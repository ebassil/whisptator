import AVFoundation
import Foundation

enum AudioResampling {
    static func to16kHzMono(_ samples: [Float], from sampleRate: Double) -> [Float] {
        guard !samples.isEmpty else { return samples }
        guard sampleRate != 16_000 else { return samples }
        guard let inFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false),
              let outFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: inFormat, to: outFormat)
        else {
            let stride = max(1, Int((sampleRate / 16_000).rounded()))
            var out = [Float]()
            out.reserveCapacity(samples.count / stride)
            var i = 0
            while i < samples.count { out.append(samples[i]); i += stride }
            return out
        }
        guard let inBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(samples.count)) else { return [] }
        inBuffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            if let base = src.baseAddress, let dst = inBuffer.floatChannelData?[0] {
                memcpy(dst, base, samples.count * MemoryLayout<Float>.size)
            }
        }
        let outCapacity = AVAudioFrameCount((Double(samples.count) * 16_000.0 / sampleRate).rounded(.up)) + 1
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: outCapacity) else { return [] }
        var fedSource = false
        var convertError: NSError?
        converter.convert(to: outBuffer, error: &convertError) { _, outStatus in
            if fedSource {
                outStatus.pointee = .noDataNow
                return nil
            }
            fedSource = true
            outStatus.pointee = .haveData
            return inBuffer
        }
        guard convertError == nil, outBuffer.frameLength > 0, let channel = outBuffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(outBuffer.frameLength)))
    }
}

/// Per-segment level normalization for the transcriber.
///
/// Meeting sources arrive at very different levels — system audio replaying a
/// call can sit 20 dB below a close microphone, and an echo-gated microphone
/// lower still. Recognizers are tuned on speech at broadcast-like levels, so a
/// quiet segment is the difference between a clean transcript and a hallucinated
/// one. This boosts quiet segments toward `targetRMS` and never attenuates a
/// loud one, clamping the boost so near-silence is not turned into amplified
/// room noise and no sample can clip.
enum SegmentLevel {
    public static let targetRMS: Double = 0.06
    public static let maxGain: Double = 12
    /// Below this RMS the "speech" is noise; leave it alone.
    public static let noiseFloorRMS: Double = 0.0015

    public static func normalize(_ samples: [Float]) -> [Float] {
        guard !samples.isEmpty else { return samples }
        var sum: Double = 0
        var peak: Double = 0
        for s in samples {
            sum += Double(s) * Double(s)
            peak = max(peak, abs(Double(s)))
        }
        let level = (sum / Double(samples.count)).squareRoot()
        guard level > noiseFloorRMS, level < targetRMS else { return samples }
        var gain = min(targetRMS / level, maxGain)
        if peak * gain > 0.999 {
            gain = min(gain, 0.999 / peak)
        }
        guard gain > 1.02 else { return samples }
        return samples.map { Float(Double($0) * gain) }
    }
}

/// Abstraction over the per-chunk transcription call so sessions can be
/// tested without loading a Whisper model.
public protocol ChunkTranscribing: Sendable {
    func transcribe(segment: SpeechSegment) async throws -> String
}

public final class WhisperChunkTranscriber: ChunkTranscribing {
    private let engine: TranscriptionEngine

    public init(engine: TranscriptionEngine) {
        self.engine = engine
    }

    public func transcribe(segment: SpeechSegment) async throws -> String {
        let leveled = SegmentLevel.normalize(segment.samples)
        let rate = segment.sampleRate
        let audio: [Float]
        if Int(rate) == 16_000 {
            audio = leveled
        } else {
            audio = await Task.detached(priority: .userInitiated) {
                AudioResampling.to16kHzMono(leveled, from: rate)
            }.value
        }
        return try await engine.transcribe(audio: audio, sampleRate: 16_000)
    }
}

/// Single-lane background worker: consumes queued segments in timeline order,
/// asks the transcriber, appends `[HH:MM:SS] text` lines, and records the
/// channel each line came from in the session ledger. Sequential processing is
/// what guarantees transcript order regardless of engine latency.
public final class ChunkTranscriber: @unchecked Sendable {
    /// A microphone segment below this share of measured local speech is remote
    /// echo the gate could not fully remove. Skipping it is what keeps the
    /// recognizer from writing the remote speaker's words a second time — and
    /// from burning a model pass on audio it can only garble.
    ///
    /// Calibrated on a real speakerphone meeting where the remote voice came
    /// back through the laptop's own speakers: with the sustained-run statistic
    /// the echo-dominated microphone segments measured 0.00 (median), 0.16 (p75)
    /// and 57 of 60 fell below this cut, while only segments carrying a genuine
    /// sustained local run reached ≥ 0.4. Sessions over headphones score near
    /// 1.0 and are never skipped. Segments the gate has not measured at all
    /// (before it locks on, or a mono session) are always transcribed — no
    /// evidence, no suppression.
    public static let minLocalShare = 0.4

    private let queue: ChunkQueue
    private let transcriber: ChunkTranscribing
    private let writer: TranscriptWriter
    private let ledger: TranscriptLedger?
    private let lineProcessor: @Sendable (String) -> String
    private var workerTask: Task<Void, Never>?

    public init(
        queue: ChunkQueue,
        transcriber: ChunkTranscribing,
        writer: TranscriptWriter,
        ledger: TranscriptLedger? = nil,
        lineProcessor: @escaping @Sendable (String) -> String = { $0 }
    ) {
        self.queue = queue
        self.transcriber = transcriber
        self.writer = writer
        self.ledger = ledger
        self.lineProcessor = lineProcessor
    }

    public func start() {
        guard workerTask == nil else { return }
        workerTask = Task(priority: .userInitiated) { [queue, transcriber, writer, ledger, lineProcessor] in
            while !Task.isCancelled {
                guard let segment = await queue.dequeue() else { break }
                if segment.channel == .mic, let share = segment.localShare, share < ChunkTranscriber.minLocalShare {
                    AppLogger.shared.log(
                        category: .transcription,
                        message: String(format: "Skipped echo-only microphone chunk [frame %d-%d, local share %.0f%%]", segment.startFrame, segment.endFrame, share * 100)
                    )
                    queue.completeWork()
                    continue
                }
                let text: String
                do {
                    text = try await transcriber.transcribe(segment: segment)
                } catch {
                    AppLogger.shared.log(
                        category: .transcription,
                        message: "Chunk transcription failed at frame \(segment.startFrame): \(error.localizedDescription)"
                    )
                    queue.completeWork()
                    continue
                }
                let cleaned = lineProcessor(text)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                if !cleaned.isEmpty {
                    writer.appendText(frame: segment.startFrame, text: cleaned)
                    ledger?.record(
                        channel: segment.channel,
                        startFrame: segment.startFrame,
                        endFrame: segment.endFrame,
                        sampleRate: segment.sampleRate,
                        localShare: segment.channel == .mic ? segment.localShare : nil,
                        text: cleaned
                    )
                }
                queue.completeWork()
            }
        }
    }

    public func stop() async {
        queue.close()
        workerTask?.cancel()
        await workerTask?.value
        workerTask = nil
    }
}
