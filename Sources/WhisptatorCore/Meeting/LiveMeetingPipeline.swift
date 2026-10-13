import Foundation

/// Wires the live meeting data flow: aligned captures fan out to the streaming
/// mp3 sink and to one voice-activity segmenter per source channel; segments
/// feed a bounded queue consumed by a single-lane transcriber that appends
/// timestamped lines to the transcript and records their provenance in the
/// session ledger.
///
/// Keeping the channels apart is the point: folding microphone and system audio
/// into one mono stream handed the transcriber two speakers at once (plus the
/// echo of the remote voice coming back through the laptop speakers), which is
/// what produced interleaved nonsense and mislabeled speakers.
///
/// Thread model: `ingestMic`/`ingestSystem`/`poll` hop onto one serial audio
/// queue; LAME and the segmenters only ever run there.
public final class LiveMeetingPipeline: @unchecked Sendable {
    public struct Config: Sendable {
        public var saveDirectory: String
        public var audioSource: AudioSourceMode
        public var mp3Bitrate: Int
        public var mp3Quality: Int
        public var sessionStem: String
        /// Suppress the echo of system audio that the microphone picks up from
        /// the machine's own speakers. Only meaningful in stereo mode.
        public var echoSuppressionEnabled: Bool

        public init(
            saveDirectory: String,
            audioSource: AudioSourceMode,
            mp3Bitrate: Int,
            mp3Quality: Int = 2,
            sessionStem: String,
            echoSuppressionEnabled: Bool = true
        ) {
            self.saveDirectory = saveDirectory
            self.audioSource = audioSource
            self.mp3Bitrate = mp3Bitrate
            self.mp3Quality = mp3Quality
            self.sessionStem = sessionStem
            self.echoSuppressionEnabled = echoSuppressionEnabled
        }
    }

    public enum EndReason: Sendable {
        case stopped
        case cancel
    }

    public let transcriptURL: URL
    public let audioURL: URL

    private let aligner: StereoAligner
    private let sink: LameStreamSink
    private let segmenters: [EnergyVADSegmenter]
    /// Echo path model for the microphone plane, when stereo and enabled.
    private let echoGate: AcousticEchoGate?
    public let ledger: TranscriptLedger
    public let queue: ChunkQueue
    private let writer: TranscriptWriter
    private let transcriber: ChunkTranscriber
    private let audioQueue = DispatchQueue(label: "com.whisptator.meeting.audio")

    public var onAudioLevel: ((Float) -> Void)?

    private let chunkFrames: Int = 4_800 // 100 ms @ 48 kHz

    public init(
        config: Config,
        transcriber: ChunkTranscribing,
        lineProcessor: @escaping @Sendable (String) -> String = { $0 }
    ) throws {
        let dir = URL(fileURLWithPath: config.saveDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.transcriptURL = dir.appendingPathComponent("\(config.sessionStem).txt")
        self.audioURL = dir.appendingPathComponent("\(config.sessionStem).mp3")

        let mode: StereoAligner.Mode
        switch config.audioSource {
        case .systemAndMicrophone: mode = .stereo
        case .microphoneOnly: mode = .micOnly
        case .systemOnly: mode = .systemOnly
        }

        self.echoGate = (mode == .stereo && config.echoSuppressionEnabled) ? AcousticEchoGate() : nil
        self.ledger = TranscriptLedger()

        var segmenters: [EnergyVADSegmenter] = []
        switch mode {
        case .stereo:
            segmenters.append(EnergyVADSegmenter(channel: .mic, echoGate: echoGate))
            segmenters.append(EnergyVADSegmenter(channel: .system))
        case .micOnly:
            segmenters.append(EnergyVADSegmenter(channel: .mic))
        case .systemOnly:
            segmenters.append(EnergyVADSegmenter(channel: .system))
        }
        self.segmenters = segmenters

        self.aligner = StereoAligner(mode: mode)
        self.sink = try LameStreamSink(
            url: audioURL,
            sampleRate: Int(StereoAligner.sampleRate),
            channels: mode.channels,
            bitrate: config.mp3Bitrate,
            quality: config.mp3Quality
        )
        self.writer = try TranscriptWriter(url: transcriptURL)
        self.queue = ChunkQueue(capacity: 60)
        self.transcriber = ChunkTranscriber(
            queue: queue,
            transcriber: transcriber,
            writer: writer,
            ledger: ledger,
            lineProcessor: lineProcessor
        )

        for segmenter in segmenters {
            segmenter.onSegment = { [weak self] segment in
                self?.queue.enqueue(segment)
            }
        }
    }

    public func startTranscribing() {
        transcriber.start()
    }

    public var micMuted: Bool { aligner.micMuted }
    public var currentFrame: Int64 { aligner.currentFrame }
    public var echoDiagnostics: AcousticEchoGate.Diagnostics? { echoGate?.diagnostics }

    // MARK: - Ingest (capture delegate threads)

    public func ingestMic(_ samples: [Float], arrivalNanos: UInt64) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.aligner.appendMic(samples, arrivalNanos: arrivalNanos)
            self.drainAndFanOut(nowNanos: arrivalNanos)
        }
    }

    public func ingestSystem(_ samples: [Float], arrivalNanos: UInt64) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.aligner.appendSystem(samples, arrivalNanos: arrivalNanos)
            self.drainAndFanOut(nowNanos: arrivalNanos)
        }
    }

    /// Clock-driven poll so stalled channels still zero-fill and the sink
    /// fsync cadence holds while capture is quiet.
    public func poll() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.drainAndFanOut(nowNanos: DispatchTime.now().uptimeNanoseconds)
            self.sink.tick()
        }
    }

    /// Mutes/unmutes the mic channel going forward (zero-fill, timeline keeps
    /// advancing) and records a marker line in the transcript.
    public func toggleMicMute() -> Bool {
        let newMuted = !aligner.micMuted
        aligner.micMuted = newMuted
        writer.appendMarker(frame: aligner.currentFrame, text: newMuted ? "mic muted" : "mic unmuted")
        AppLogger.shared.log(category: .meeting, message: newMuted ? "Microphone muted" : "Microphone unmuted")
        return newMuted
    }

    // MARK: - Teardown

    /// Stops the flow: drains the aligner and segmenters, then waits for the
    /// transcription backlog. Files remain open.
    public func drainAll(drainTimeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            audioQueue.async {
                let tail = self.aligner.flushAll(maxFrames: self.chunkFrames)
                for chunk in tail {
                    self.sink.append(chunk)
                    for segmenter in self.segmenters {
                        segmenter.append(chunk)
                    }
                }
                for segmenter in self.segmenters {
                    segmenter.flush()
                }
                continuation.resume()
            }
        }
        let drained = await queue.waitForDrain(timeout: drainTimeout)
        if !drained {
            AppLogger.shared.log(category: .meeting, message: "Transcription drain timed out with \(queue.pendingCount) chunks pending; transcript may be missing trailing speech (audio file is complete)")
        }
        return drained
    }

    /// Closes sink and writer (emitting encoder tail). The transcript is fully
    /// flushed when this returns.
    public func closeFiles() async {
        await transcriber.stop()
        await sink.finish()
        await writer.close()
    }

    /// Waits for all ingest work enqueued so far to finish processing
    /// (aligner drain + sink writes) without closing anything.
    public func waitForIngestDrain() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            audioQueue.async { continuation.resume() }
        }
        await sink.awaitPendingWrites()
        await writer.waitForPendingWrites()
    }

    public func finalize(drainTimeout: TimeInterval) async -> Bool {
        let drained = await drainAll(drainTimeout: drainTimeout)
        await closeFiles()
        return drained
    }

    public func cancel() async {
        await transcriber.stop()
        await sink.finish()
        await writer.close()
    }

    // MARK: - Private

    private func drainAndFanOut(nowNanos: UInt64) {
        while let chunk = aligner.nextChunk(maxFrames: chunkFrames, nowNanos: nowNanos) {
            sink.append(chunk)
            for segmenter in segmenters {
                segmenter.append(chunk)
            }
            reportLevel(of: chunk)
        }
    }

    private func reportLevel(of chunk: AlignedAudioChunk) {
        guard let onAudioLevel else { return }
        var sum: Double = 0
        for s in chunk.samples { sum += Double(s) * Double(s) }
        let rms = (sum / Double(max(1, chunk.samples.count))).squareRoot()
        onAudioLevel(Float(min(1.0, rms * 5)))
    }
}
