import Foundation

/// ONNX implementation of the pyannote/speaker-diarization-3.1 pipeline for
/// the system channel of a meeting recording. Models are the ungated
/// `onnx-community` exports of the two weights the 3.1 config references:
///
///   16 kHz mono audio -> segmentation-3.0 sliding windows over raw samples
///   (powerset logits [1, frames, 7], offset 990 / hop 270 samples)
///   -> speech activity and overlap per 10 ms bin -> turn regions
///   -> wespeaker-voxceleb-resnet34-LM embeddings (80-bin kaldi fbank ->
///   [1, 256]) per eligible window, pooled per turn
///   -> weighted average-linkage agglomerative clustering with a speaker cap
///   and support-based absorption
///   -> windows refined against cluster centroids -> speakers numbered by first
///   appearance.
///
/// Clustering happens at turn level on purpose. Labeling every 3 s embedding
/// window on its own made one continuous voice look like dozens of speakers:
/// window embeddings of the same person on a compressed, quiet meeting channel
/// sit ~0.24 apart, so a 0.25 merge threshold joined almost nothing and every
/// window became a new person. Pooled turn embeddings are far more stable, and
/// the cap plus absorption keep a single odd window from inventing a speaker.
public actor PyannoteDiarizer: SpeakerDiarizer {
    public struct Parameters: Sendable {
        /// Raw-audio window fed to the segmentation model.
        public var segmentationWindowSeconds: Double = 10.0
        /// Segmentation window hop (50 % overlap, aggregated by averaging).
        public var segmentationHopSeconds: Double = 5.0
        /// Activity grid resolution used for turn detection (10 ms).
        public var frameSeconds: Double = 0.01
        /// Speech threshold on summed non-background powerset probabilities.
        /// Measured with real weights: clean silence ≈ 0.07, window-edge
        /// bleed into short gaps ≈ 0.5, speech ≈ 0.85–1.0.
        public var activityThreshold: Double = 0.6
        /// Gaps shorter than this within a turn are kept as one region.
        public var turnGapFillSeconds: Double = 0.3
        /// Regions shorter than this are ignored (no speaker evidence).
        public var minTurnSeconds: Double = 0.4
        /// Raw-audio window per embedding piece.
        public var embeddingWindowSeconds: Double = 3.0
        /// Embedding window hop within a turn.
        public var embeddingHopSeconds: Double = 1.5
        /// Shortest piece that may be embedded; anything shorter is not padded
        /// with silence, which used to produce unstable embeddings.
        public var minEmbeddingSeconds: Double = 1.2
        /// At least this fraction of a piece's activity bins must be speech.
        public var minSpeechRatio: Double = 0.55
        /// Pieces per turn, sampled evenly when the turn is long.
        public var maxPiecesPerTurn: Int = 6
        /// Cosine distance below which two turns may merge into one speaker.
        /// Calibrated against real meetings: the same voice in consecutive
        /// 3 s windows measures ~0.24 median (~0.33 at p90), while distinct
        /// voices measure ~0.47; pyannote's own 3.1 pipeline cuts average
        /// linkage at 0.78 and this library's reference default is 0.715.
        public var clusterDistanceThreshold: Double = 0.6
        /// Hard ceiling on speakers in one session; beyond it the closest
        /// clusters merge no matter the distance.
        public var maxSpeakers: Int = 8
        /// A cluster supported by less speech than this is absorbed into its
        /// nearest neighbour instead of becoming a speaker.
        public var minClusterSeconds: Double = 2.0
        /// How much closer another cluster's centroid must be than a window's
        /// own cluster before the window is reassigned to it.
        public var reassignmentMargin: Double = 0.06

        public init() {}
    }

    public enum DiarizerError: Error, LocalizedError {
        case modelsMissing
        case emptyAudio
        public var errorDescription: String? {
            switch self {
            case .modelsMissing: return "Diarization models are not available"
            case .emptyAudio: return "Session audio could not be decoded for diarization"
            }
        }
    }

    private let segmentationURL: URL
    private let embeddingURL: URL
    private let parameters: Parameters
    private var segmentationModel: OrtModel?
    private var embeddingModel: OrtModel?
    private var loadFailed = false

    public init(
        segmentationModelURL: URL,
        embeddingModelURL: URL,
        parameters: Parameters = Parameters()
    ) {
        self.segmentationURL = segmentationModelURL
        self.embeddingURL = embeddingModelURL
        self.parameters = parameters
    }

    public var isReady: Bool {
        get async {
            do {
                _ = try ensureModels()
                return true
            } catch {
                return false
            }
        }
    }

    private func ensureModels() throws -> (segmentation: OrtModel, embedding: OrtModel) {
        if loadFailed { throw DiarizerError.modelsMissing }
        if let segmentationModel, let embeddingModel { return (segmentationModel, embeddingModel) }
        do {
            let seg = try OrtModel(url: segmentationURL)
            let emb = try OrtModel(url: embeddingURL)
            segmentationModel = seg
            embeddingModel = emb
            return (seg, emb)
        } catch {
            loadFailed = true
            throw error
        }
    }

    public func diarize(mp3URL: URL) async throws -> [DiarizedSegment] {
        let models = try ensureModels()
        let audio = try await SystemChannelLoader.load16kHzMono(from: mp3URL)
        guard audio.count > 1600 else { throw DiarizerError.emptyAudio }

        let frame = speechFrames(audio: audio, model: models.segmentation)
        let activity = frame.activity
        let turns = turnRegions(from: activity)
        guard !turns.isEmpty else { return [] }

        let pieces = embeddingPieces(
            for: turns,
            audio: audio,
            frames: frame,
            embedder: WeSpeakerEmbedder(model: models.embedding)
        )
        guard !pieces.isEmpty else { return [] }

        // Pool per turn, then cluster turns.
        let pooled = poolByTurn(pieces, turns: turns)
        let result = AgglomerativeClustering.cluster(
            vectors: pooled.map(\.embedding),
            distanceThreshold: parameters.clusterDistanceThreshold,
            weights: pooled.map(\.seconds),
            maxClusters: parameters.maxSpeakers,
            minClusterWeight: parameters.minClusterSeconds
        )
        guard result.clusterCount > 0 else { return [] }

        let turnLabels = result.labels
        let windowLabels = refine(
            pieces: pieces,
            pooled: pooled,
            turnLabels: turnLabels,
            centroids: result.centroids
        )
        let segments = speakerSegments(pieces: pieces, windowLabels: windowLabels)
        AppLogger.shared.log(
            category: .model,
            message: "Diarization: \(turns.count) turns, \(pieces.count) embedded windows, \(result.clusterCount) speaker(s)"
        )
        return segments
    }

    // MARK: - Segmentation

    /// Powerset frame geometry (`preprocessor_config.json`): first frame centre
    /// at sample offset 990, consecutive frames every 270 samples at 16 kHz.
    private static let segmentationOffset = 990.0
    private static let segmentationStep = 270.0

    struct SpeechFrames {
        /// Probability of any speech per 10 ms bin, averaged over windows.
        let activity: [Double]
        /// Share of that speech probability that came from multi-speaker
        /// powerset classes, per bin: 0 when one voice, ~1 when several.
        let overlapShare: [Double]
    }

    /// Returns speech probability per 10 ms bin, averaged over sliding
    /// segmentation windows, plus the share of that probability attributable to
    /// simultaneous speakers.
    func speechFrames(audio: [Float], model: OrtModel) -> SpeechFrames {
        let binSeconds = parameters.frameSeconds
        let binCount = max(1, Int((Double(audio.count) / 16_000 / binSeconds).rounded(.up)))

        var speechSums = [Double](repeating: 0, count: binCount)
        var pairSums = [Double](repeating: 0, count: binCount)
        var counts = [Int](repeating: 0, count: binCount)

        let windowSamples = max(1, Int(parameters.segmentationWindowSeconds * 16_000))
        let hopSamples = max(1, Int(parameters.segmentationHopSeconds * 16_000))

        var start = 0
        while true {
            let covered = audio.count - start
            if covered >= windowSamples {
                let window = Array(audio[start..<start + windowSamples])
                if let probs = runSegmentation(model: model, samples: window, windowSamples: windowSamples) {
                    accumulate(
                        probs: probs,
                        windowStart: start,
                        binSeconds: binSeconds,
                        speech: &speechSums,
                        pair: &pairSums,
                        counts: &counts
                    )
                }
            } else if start == 0 {
                // Shorter than one model window (tests, very short clips):
                // pad, and only credit the bins the audio really covers.
                var window = audio
                window.append(contentsOf: [Float](repeating: 0, count: windowSamples - window.count))
                if let probs = runSegmentation(model: model, samples: window, windowSamples: windowSamples) {
                    accumulate(
                        probs: probs,
                        windowStart: 0,
                        binSeconds: binSeconds,
                        speech: &speechSums,
                        pair: &pairSums,
                        counts: &counts
                    )
                }
            }
            guard start + windowSamples < audio.count else { break }
            start += hopSamples
        }

        var activity = [Double](repeating: 0, count: binCount)
        var overlapShare = [Double](repeating: 0, count: binCount)
        for i in 0..<binCount where counts[i] > 0 {
            let speech = speechSums[i] / Double(counts[i])
            let pair = pairSums[i] / Double(counts[i])
            activity[i] = speech
            overlapShare[i] = speech > 1e-9 ? min(1, pair / speech) : 0
        }
        return SpeechFrames(activity: activity, overlapShare: overlapShare)
    }

    private func accumulate(
        probs: SegmentationProbs,
        windowStart: Int,
        binSeconds: Double,
        speech: inout [Double],
        pair: inout [Double],
        counts: inout [Int]
    ) {
        let classes = probs.classesPerFrame
        for f in 0..<probs.frames {
            // Powerset classes for segmentation-3.0 (max 3 speakers): 0 is
            // non-speech, 1-3 are single speakers, 4-6 are speaker pairs.
            var exp = [Double](repeating: 0, count: classes)
            var exponentSum = 0.0
            for c in 0..<classes {
                let e = Foundation.exp(probs.data[f * classes + c])
                exp[c] = e
                exponentSum += e
            }
            guard exponentSum > 1e-12 else { continue }
            let background = classes > 0 ? exp[0] / exponentSum : 1.0
            let speechTotal = 1 - background
            var pairShare = 0.0
            if classes > 4 {
                for c in 4..<classes { pairShare += exp[c] / exponentSum }
            }
            let sampleTime = Double(windowStart) + Self.segmentationOffset + (Double(f) + 0.5) * Self.segmentationStep
            let bin = Int(sampleTime / (16_000 * binSeconds))
            guard bin >= 0, bin < speech.count else { continue }
            speech[bin] += speechTotal
            pair[bin] += pairShare
            counts[bin] += 1
        }
    }

    private struct SegmentationProbs {
        let data: [Double]
        let classesPerFrame: Int
        let frames: Int
    }

    private func runSegmentation(model: OrtModel, samples: [Float], windowSamples: Int) -> SegmentationProbs? {
        // Input layout: (1, 1, num_samples) raw float32 waveform at 16 kHz.
        do {
            let (data, dims) = try model.run(input: samples, shape: [1, 1, windowSamples])
            // Output layout: (1, num_frames, classes) row-major per frame.
            guard dims.count == 3, dims[0] == 1, let last = dims.last, last > 0 else { return nil }
            let frames = dims[1]
            guard data.count >= frames * last, frames > 0 else { return nil }
            return SegmentationProbs(data: data.map { Double($0) }, classesPerFrame: last, frames: frames)
        } catch {
            AppLogger.shared.log(category: .model, message: "Segmentation inference failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Turns

    func turnRegions(from activity: [Double]) -> [(start: Double, end: Double)] {
        let frame = parameters.frameSeconds
        var regions: [(start: Double, end: Double)] = []
        var inTurn = false
        var start = 0.0
        var lastActiveEnd = 0.0
        for (i, value) in activity.enumerated() {
            let t = Double(i) * frame
            if value >= parameters.activityThreshold {
                if !inTurn {
                    inTurn = true
                    start = t
                }
                lastActiveEnd = t + frame
            } else if inTurn, t - lastActiveEnd > parameters.turnGapFillSeconds {
                let end = lastActiveEnd + parameters.turnGapFillSeconds / 2
                if end - start >= parameters.minTurnSeconds {
                    regions.append((start, end))
                }
                inTurn = false
            }
        }
        if inTurn, Double(activity.count) * frame - start >= parameters.minTurnSeconds {
            regions.append((start, Double(activity.count) * frame))
        }
        return regions
    }

    // MARK: - Embeddings

    struct Piece: Sendable {
        let turnIndex: Int
        let start: Double
        let end: Double
        let embedding: [Double]
    }

    private func embeddingPieces(
        for turns: [(start: Double, end: Double)],
        audio: [Float],
        frames: SpeechFrames,
        embedder: WeSpeakerEmbedder
    ) -> [Piece] {
        let windowSamples = max(1600, Int(parameters.embeddingWindowSeconds * 16_000))
        let stride = max(1, Int(parameters.embeddingHopSeconds * 16_000))
        let minSamples = Int(parameters.minEmbeddingSeconds * 16_000)
        var pieces: [Piece] = []

        for (turnIndex, turn) in turns.enumerated() {
            let lo = Int(turn.start * 16_000)
            let hi = min(audio.count, Int(turn.end * 16_000))
            guard hi - lo >= minSamples else { continue }

            var offsets = [Int]()
            var offset = lo
            while offset + windowSamples <= hi {
                offsets.append(offset)
                offset += stride
            }
            // A turn shorter than one window is embedded from its full span
            // rather than zero-padded out to 3 s.
            if offsets.isEmpty { offsets = [lo] }
            if offsets.count > parameters.maxPiecesPerTurn {
                let step = Double(offsets.count - 1) / Double(max(1, parameters.maxPiecesPerTurn - 1))
                var picked = [Int]()
                var seen = Set<Int>()
                for i in 0..<parameters.maxPiecesPerTurn {
                    let offset = offsets[Int((Double(i) * step).rounded())]
                    if seen.insert(offset).inserted { picked.append(offset) }
                }
                offsets = picked
            }

            for pieceOffset in offsets {
                let end = min(pieceOffset + windowSamples, hi)
                guard end - pieceOffset >= minSamples else { continue }
                guard cleanSpeechRatio(in: pieceOffset..<end, frames: frames) >= parameters.minSpeechRatio else {
                    continue
                }
                let window = Array(audio[pieceOffset..<end])
                guard let embedding = embedder.embed(window), !embedding.isEmpty else { continue }
                pieces.append(Piece(
                    turnIndex: turnIndex,
                    start: Double(pieceOffset) / 16_000,
                    end: Double(end) / 16_000,
                    embedding: embedding
                ))
            }
        }
        return pieces
    }

    /// Share of a sample range whose 10 ms bins were single-speaker speech.
    /// Overlapping speech is a poor embedding input: the vector describes two
    /// voices at once and matches nobody, which is how phantom speakers appear.
    private func cleanSpeechRatio(in range: Range<Int>, frames: SpeechFrames) -> Double {
        guard !frames.activity.isEmpty else { return 1 }
        let binSeconds = parameters.frameSeconds
        let lo = Int(Double(range.lowerBound) / 16_000 / binSeconds)
        let hi = Int((Double(range.upperBound) / 16_000 / binSeconds).rounded(.up))
        var good = 0
        var total = 0
        for bin in lo..<min(hi, frames.activity.count) {
            total += 1
            if frames.activity[bin] >= parameters.activityThreshold, frames.overlapShare[bin] < 0.5 {
                good += 1
            }
        }
        guard total > 0 else { return 0 }
        return Double(good) / Double(total)
    }

    /// Mean of the window embeddings inside a turn, L2-normalized.
    struct PooledTurn {
        let turnIndex: Int
        let embedding: [Double]
        let seconds: Double
    }

    private func poolByTurn(_ pieces: [Piece], turns: [(start: Double, end: Double)]) -> [PooledTurn] {
        var grouped: [Int: [Piece]] = [:]
        for piece in pieces { grouped[piece.turnIndex, default: []].append(piece) }
        return grouped.keys.sorted().map { turnIndex in
            let group = grouped[turnIndex] ?? []
            let mean = EmbeddingMath.weightedMean(group.map(\.embedding), weights: group.map { $0.end - $0.start })
            // Weight by the turn's real speech span, not by overlapping window
            // lengths, so `minClusterSeconds` means seconds of audio.
            let seconds = turnIndex < turns.count ? turns[turnIndex].end - turns[turnIndex].start : 0.2
            return PooledTurn(turnIndex: turnIndex, embedding: EmbeddingMath.l2Normalize(mean), seconds: max(0.2, seconds))
        }
    }

    /// Give each window its own label so a turn that really contains a speaker
    /// change is split, while windows that merely embed oddly keep the turn's
    /// label instead of becoming a new speaker.
    private func refine(pieces: [Piece], pooled: [PooledTurn], turnLabels: [Int], centroids: [[Double]]) -> [Int] {
        guard !centroids.isEmpty else { return Array(repeating: 0, count: pieces.count) }
        var labelByTurn: [Int: Int] = [:]
        for (position, turn) in pooled.enumerated() where position < turnLabels.count {
            labelByTurn[turn.turnIndex] = turnLabels[position]
        }

        var labels: [Int] = []
        labels.reserveCapacity(pieces.count)
        for piece in pieces {
            let own = labelByTurn[piece.turnIndex] ?? 0
            let ownDistance = distance(piece.embedding, to: centroids, index: own)

            var bestOther = own
            var bestOtherDistance = ownDistance
            for cluster in centroids.indices where cluster != own {
                let d = distance(piece.embedding, to: centroids, index: cluster)
                if d < bestOtherDistance {
                    bestOtherDistance = d
                    bestOther = cluster
                }
            }

            // Reassign only when another cluster is clearly the better match. A
            // window that merely embeds oddly keeps the turn's label instead of
            // becoming an extra speaker.
            labels.append(bestOtherDistance < ownDistance - parameters.reassignmentMargin ? bestOther : own)
        }
        return labels
    }

    private func distance(_ embedding: [Double], to centroids: [[Double]], index: Int) -> Double {
        guard centroids.indices.contains(index) else { return .infinity }
        return EmbeddingMath.cosineDistance(embedding, centroids[index])
    }

    // MARK: - Speakers

    /// Turns windows into time-ordered speaker segments, numbering speakers by
    /// first appearance.
    func speakerSegments(pieces: [Piece], windowLabels: [Int]) -> [DiarizedSegment] {
        guard pieces.count == windowLabels.count else { return [] }
        let ordered = zip(pieces, windowLabels).sorted { $0.0.start < $1.0.start }

        var numberByCluster: [Int: Int] = [:]
        var nextNumber = 1
        var segments: [DiarizedSegment] = []
        for (piece, label) in ordered {
            if numberByCluster[label] == nil {
                numberByCluster[label] = nextNumber
                nextNumber += 1
            }
            let speaker = "Speaker \(numberByCluster[label]!)"
            if let last = segments.last, last.speaker == speaker, piece.start <= last.end + parameters.turnGapFillSeconds {
                segments[segments.count - 1] = DiarizedSegment(start: last.start, end: max(last.end, piece.end), speaker: speaker)
            } else {
                segments.append(DiarizedSegment(start: piece.start, end: piece.end, speaker: speaker))
            }
        }
        return segments
    }
}

/// Loads the system (right) channel — or the single channel of a mono
/// session — as 16 kHz mono Float samples. Bounded memory for long files.
enum SystemChannelLoader {
    static func load16kHzMono(from mp3URL: URL) async throws -> [Float] {
        try await Task.detached(priority: .userInitiated) {
            var result: [Float] = []
            var channel0: [Float] = []
            try DiarizationAudio.stream16kHzChunks(of: mp3URL, chunkSeconds: 5.0) { channel, startSample, samples in
                if channel == 1 {
                    if startSample > result.count {
                        result.append(contentsOf: [Float](repeating: 0, count: startSample - result.count))
                    }
                    result.append(contentsOf: samples)
                } else if channel == 0 {
                    channel0.append(contentsOf: samples)
                }
            }
            return result.isEmpty ? channel0 : result
        }.value
    }
}
