import AVFoundation
import Foundation

/// Resamples one continuous mono stream to a target rate, keeping a single
/// `AVAudioConverter` alive for the whole stream.
///
/// The diarizer and the relabeler both walk a stored session file in chunks.
/// Creating a converter per chunk restarts its interpolation filter at every
/// boundary and strands a few samples behind each time, so the 16 kHz audio
/// that embeddings are computed from carries a click at every chunk edge and
/// drifts against the timeline it is compared with. One instance per channel
/// removes both problems: whatever the converter holds back simply arrives with
/// the next chunk.
final class StreamResampler: @unchecked Sendable {
    private let converter: AVAudioConverter?
    private let targetFormat: AVAudioFormat
    private let sourceRate: Double
    private let targetRate: Double
    private let lock = NSLock()

    init(sourceRate: Double, targetRate: Double) {
        self.sourceRate = sourceRate
        self.targetRate = targetRate
        self.targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetRate, channels: 1, interleaved: false)!
        if let source = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sourceRate, channels: 1, interleaved: false),
           sourceRate != targetRate {
            self.converter = AVAudioConverter(from: source, to: targetFormat)
        } else {
            self.converter = nil
        }
    }

    /// Feed the next piece of the stream; returns the samples of 16 kHz audio
    /// (or of the target rate generally) produced by this piece.
    func append(_ samples: [Float]) -> [Float] {
        lock.lock(); defer { lock.unlock() }
        guard !samples.isEmpty else { return [] }
        guard let converter else { return samples }

        let ratio = targetRate / sourceRate
        let inFormat = converter.inputFormat
        guard let input = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return samples
        }
        input.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            if let base = src.baseAddress, let dst = input.floatChannelData?[0] {
                memcpy(dst, base, samples.count * MemoryLayout<Float>.size)
            }
        }

        let capacity = AVAudioFrameCount(Double(samples.count) * ratio) + 16
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return [] }
        var error: NSError?
        var fed = false
        converter.convert(to: output, error: &error) { _, outStatus in
            if fed {
                outStatus.pointee = .noDataNow
                return nil
            }
            fed = true
            outStatus.pointee = .haveData
            return input
        }
        guard error == nil, output.frameLength > 0, let channel = output.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
    }

    /// End of stream: emits whatever the converter still holds back.
    func flush() -> [Float] {
        lock.lock(); defer { lock.unlock() }
        guard let converter else { return [] }
        let capacity = AVAudioFrameCount(targetRate * 0.05) + 16
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return [] }
        var error: NSError?
        converter.convert(to: output, error: &error) { _, outStatus in
            outStatus.pointee = .endOfStream
            return nil
        }
        guard error == nil, output.frameLength > 0, let channel = output.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
    }
}
