import AVFoundation

public final class AudioMixer: @unchecked Sendable {
    public init() {}

    public func start() throws {}

    public func stop() {}

    public func mixSystemAudio(_ systemBuffer: AVAudioPCMBuffer, withMic micBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let systemSamples = extractSamples(from: systemBuffer)
        let micSamples = extractSamples(from: micBuffer)

        let minCount = min(systemSamples.count, micSamples.count)
        guard minCount > 0 else { return nil }

        var mixed = [Float](repeating: 0, count: minCount)
        for i in 0..<minCount {
            mixed[i] = (systemSamples[i] + micSamples[i]) / 2.0
        }

        let format = systemBuffer.format
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(minCount)) else { return nil }
        outputBuffer.frameLength = AVAudioFrameCount(minCount)

        if let channelData = outputBuffer.floatChannelData?[0] {
            for (i, sample) in mixed.enumerated() {
                channelData[i] = sample
            }
        }

        return outputBuffer
    }

    private func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
    }

    public var isRunning: Bool { false }
}
