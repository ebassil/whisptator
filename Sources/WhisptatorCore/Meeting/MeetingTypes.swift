import AVFoundation

public struct AlignedAudioChunk: Sendable {
    public let startFrame: Int64
    public let frames: Int
    public let channels: Int
    public let samples: [Float]

    public init(startFrame: Int64, frames: Int, channels: Int, samples: [Float]) {
        self.startFrame = startFrame
        self.frames = frames
        self.channels = channels
        self.samples = samples
    }

    public func monoFold() -> [Float] {
        guard channels > 1 else { return samples }
        var out = [Float](repeating: 0, count: frames)
        for i in 0..<frames {
            out[i] = (samples[i * channels] + samples[i * channels + 1]) * 0.5
        }
        return out
    }

    public static let empty = AlignedAudioChunk(startFrame: 0, frames: 0, channels: 1, samples: [])
}

public struct SpeechSegment: Sendable {
    public let startFrame: Int64
    public let endFrame: Int64
    public let samples: [Float]
    public let sampleRate: Double

    public init(startFrame: Int64, endFrame: Int64, samples: [Float], sampleRate: Double) {
        self.startFrame = startFrame
        self.endFrame = endFrame
        self.samples = samples
        self.sampleRate = sampleRate
    }

    public var durationSeconds: Double {
        Double(endFrame - startFrame) / sampleRate
    }
}
