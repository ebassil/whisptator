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
        let samples = segment.samples
        let rate = segment.sampleRate
        let audio: [Float]
        if Int(rate) == 16_000 {
            audio = samples
        } else {
            audio = await Task.detached(priority: .userInitiated) {
                AudioResampling.to16kHzMono(samples, from: rate)
            }.value
        }
        return try await engine.transcribe(audio: audio, sampleRate: 16_000)
    }
}

/// Single-lane background worker: consumes queued segments in order, asks the
/// transcriber, and appends `[HH:MM:SS] text` lines. Sequential processing is
/// what guarantees transcript order regardless of engine latency.
public final class ChunkTranscriber: @unchecked Sendable {
    private let queue: ChunkQueue
    private let transcriber: ChunkTranscribing
    private let writer: TranscriptWriter
    private let lineProcessor: @Sendable (String) -> String
    private var workerTask: Task<Void, Never>?

    public init(
        queue: ChunkQueue,
        transcriber: ChunkTranscribing,
        writer: TranscriptWriter,
        lineProcessor: @escaping @Sendable (String) -> String = { $0 }
    ) {
        self.queue = queue
        self.transcriber = transcriber
        self.writer = writer
        self.lineProcessor = lineProcessor
    }

    public func start() {
        guard workerTask == nil else { return }
        workerTask = Task(priority: .userInitiated) { [queue, transcriber, writer, lineProcessor] in
            while !Task.isCancelled {
                guard let segment = await queue.dequeue() else { break }
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
