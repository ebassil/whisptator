import Foundation

/// ONNX implementation of the pyannote/speaker-diarization-3.1 pipeline for
/// the system channel of a meeting recording. Models are the ungated
/// `onnx-community` exports of the two weights the 3.1 config references:
///
///   16 kHz mono audio -> segmentation-3.0 sliding windows over raw samples
///   (powerset logits [1, frames, 7], 270-sample hop)
///   -> speech activity per 10 ms bin -> turn regions -> wespeaker-voxceleb-
///   resnet34-LM embeddings (80-bin kaldi fbank -> [1, 256]) per region piece
///   -> average-linkage agglomerative clustering
///   -> speakers numbered by first appearance.
///
/// Thresholds remain tunable because quality depends on real meeting audio;
/// calibration against recorded calls is task 8.1.
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
        /// Cosine distance above which two pieces are different speakers.
        /// Measured with real weights: same voice ≈ 0.03–0.05, distinct
        /// voices ≈ 0.34–0.37 (synthetic); real meetings need 8.1 tuning.
        public var clusterDistanceThreshold: Double = 0.25

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

        let activity = speechActivity(audio: audio, model: models.segmentation)
        let turns = turnRegions(from: activity)
        guard !turns.isEmpty else { return [] }

        let pieces = embeddingPieces(for: turns, audio: audio, model: models.embedding)
        guard !pieces.isEmpty else { return [] }

        let labels = AgglomerativeClustering.cluster(
            vectors: pieces.map(\.embedding),
            distanceThreshold: parameters.clusterDistanceThreshold
        )

        return speakerSegments(turns: turns, pieces: pieces, labels: labels)
    }

    // MARK: - Segmentation

    /// Samples per segmentation output frame (`preprocessor_config.json`:
    /// offset 990, step 270 at 16 kHz).
    private static let segmentationStep = 270.0

    /// Returns speech probability per 10 ms bin, averaged over sliding
    /// segmentation windows. Activity = probability of any speaker class
    /// (1 - softmax over the NO_SPEAKER powerset class).
    func speechActivity(audio: [Float], model: OrtModel) -> [Double] {
        let binSeconds = parameters.frameSeconds
        let binCount = max(1, Int((Double(audio.count) / 16_000 / binSeconds).rounded(.up)))
        let windowSamples = max(1, Int(parameters.segmentationWindowSeconds * 16_000))
        let hopSamples = max(1, Int(parameters.segmentationHopSeconds * 16_000))

        var sums = [Double](repeating: 0, count: binCount)
        var counts = [Int](repeating: 0, count: binCount)

        var start = 0
        while true {
            var window = Array(audio[start..<min(start + windowSamples, audio.count)])
            if window.count < windowSamples {
                window.append(contentsOf: [Float](repeating: 0, count: windowSamples - window.count))
            }
            if let probs = runSegmentation(model: model, samples: window, windowSamples: windowSamples) {
                let samplesPerFrame = Double(windowSamples) / Double(probs.frames)
                for f in 0..<probs.frames {
                    var background = 0.0
                    var exponentSum = 0.0
                    for c in 0..<probs.classesPerFrame {
                        let e = exp(probs.data[f * probs.classesPerFrame + c])
                        exponentSum += e
                        if c == 0 { background = e }
                    }
                    let activity = 1 - background / max(exponentSum, 1e-12)
                    let t = Double(start) + (Double(f) + 0.5) * samplesPerFrame
                    let bin = Int(t / (16_000 * binSeconds))
                    guard bin < binCount else { continue }
                    sums[bin] += activity
                    counts[bin] += 1
                }
            }
            guard start + windowSamples < audio.count else { break }
            start += hopSamples
        }

        return (0..<binCount).map { i in
            counts[i] > 0 ? sums[i] / Double(counts[i]) : 0
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

    private func embeddingPieces(for turns: [(start: Double, end: Double)], audio: [Float], model: OrtModel) -> [Piece] {
        let windowSamples = max(1600, Int(parameters.embeddingWindowSeconds * 16_000))
        let stride = max(1, Int(parameters.embeddingHopSeconds * 16_000))
        let fbank = WeSpeakerFbank()
        var pieces: [Piece] = []

        for (turnIndex, turn) in turns.enumerated() {
            let lo = Int(turn.start * 16_000)
            let hi = min(audio.count, Int(turn.end * 16_000))
            guard hi - lo >= Int(parameters.minTurnSeconds * 16_000) else { continue }

            var offsets = [Int]()
            var offset = lo
            while offset + windowSamples <= hi {
                offsets.append(offset)
                offset += stride
            }
            if offsets.isEmpty { offsets = [max(lo, hi - windowSamples)] }

            for offset in offsets {
                var window = Array(audio[offset..<min(offset + windowSamples, hi)])
                if window.count < windowSamples {
                    window.append(contentsOf: [Float](repeating: 0, count: windowSamples - window.count))
                }
                let features = fbank.extract(from: window)
                guard !features.isEmpty, let melCount = features.first?.count else { continue }
                var flat = [Float](repeating: 0, count: features.count * melCount)
                for (f, frame) in features.enumerated() {
                    for m in 0..<melCount {
                        flat[f * melCount + m] = Float(frame[m])
                    }
                }
                do {
                    // Input layout: (1, num_frames, 80) log-mel fbank.
                    let (data, dims) = try model.run(input: flat, shape: [1, features.count, melCount])
                    let embedding = normalize(averageEmbedding(data: data, dims: dims))
                    if !embedding.isEmpty {
                        pieces.append(Piece(
                            turnIndex: turnIndex,
                            start: Double(offset) / 16_000,
                            end: Double(min(offset + windowSamples, hi)) / 16_000,
                            embedding: embedding
                        ))
                    }
                } catch {
                    AppLogger.shared.log(category: .model, message: "Embedding inference failed: \(error.localizedDescription)")
                }
            }
        }
        return pieces
    }

    /// L2-normalize so cosine distance is a plain dot product in the clusterer.
    private func normalize(_ vector: [Double]) -> [Double] {
        let norm = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        guard norm > 0 else { return vector }
        return vector.map { $0 / norm }
    }

    /// Output may be (1, D) or (1, T, D); average over time if 3-D.
    private func averageEmbedding(data: [Float], dims: [Int]) -> [Double] {
        guard let last = dims.last, last > 0 else { return [] }
        let frames = dims.count >= 3 ? max(1, data.count / last) : 1
        var sums = [Double](repeating: 0, count: last)
        for f in 0..<frames {
            for d in 0..<last {
                let index = f * last + d
                if index < data.count { sums[d] += Double(data[index]) }
            }
        }
        return sums.map { $0 / Double(frames) }
    }

    // MARK: - Speakers

    func speakerSegments(
        turns: [(start: Double, end: Double)],
        pieces: [Piece],
        labels: [Int]
    ) -> [DiarizedSegment] {
        guard pieces.count == labels.count else { return [] }

        var numberByCluster: [Int: Int] = [:]
        var nextNumber = 1
        var segments: [DiarizedSegment] = []

        // Label per embedding window (not per turn majority) so a turn that
        // spans a speaker change still yields correct sub-segments; windows
        // overlap by design (hop < window), consecutive same-label windows
        // merge into one segment.
        for turnIndex in turns.indices {
            let turnPieces = zip(pieces, labels)
                .filter { $0.0.turnIndex == turnIndex }
                .sorted { $0.0.start < $1.0.start }
            for (piece, label) in turnPieces {
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
