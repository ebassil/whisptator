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

    /// One channel of the chunk as a continuous sample array. Mono chunks
    /// answer every request with their single channel, so callers that ask for
    /// `.system` on a system-only recording still get usable audio.
    public func plane(_ channel: AudioChannel) -> [Float] {
        guard channels > 1, let index = channel.planeIndex(inChannels: channels) else {
            return channels == 1 ? Array(samples[0..<min(frames, samples.count)]) : []
        }
        var out = [Float](repeating: 0, count: frames)
        var i = 0
        while i < frames {
            out[i] = samples[i * channels + index]
            i += 1
        }
        return out
    }

    public static let empty = AlignedAudioChunk(startFrame: 0, frames: 0, channels: 1, samples: [])
}

/// Which capture source a segment came from. In stereo sessions the microphone
/// is always the left plane and system audio the right plane, so the channel
/// identifies the physical speaker side without guessing from energy.
public enum AudioChannel: String, Sendable, Codable, CaseIterable {
    case mic
    case system

    /// Plane index for this channel, or nil when the stream does not carry it.
    public func planeIndex(inChannels channels: Int) -> Int? {
        switch self {
        case .mic: return 0
        case .system: return channels > 1 ? 1 : nil
        }
    }
}

public struct SpeechSegment: Sendable {
    public let startFrame: Int64
    public let endFrame: Int64
    public let samples: [Float]
    public let sampleRate: Double
    /// Source channel the segment was cut from.
    public let channel: AudioChannel
    /// Fraction of the segment judged to be the local microphone speaker rather
    /// than acoustic echo of the system channel. `nil` when nothing measured it:
    /// system-channel segments, mono sessions, and microphone segments cut
    /// before the echo gate had locked onto the echo path.
    public let localShare: Double?

    public init(
        startFrame: Int64,
        endFrame: Int64,
        samples: [Float],
        sampleRate: Double,
        channel: AudioChannel,
        localShare: Double? = nil
    ) {
        self.startFrame = startFrame
        self.endFrame = endFrame
        self.samples = samples
        self.sampleRate = sampleRate
        self.channel = channel
        self.localShare = localShare
    }

    public var durationSeconds: Double {
        Double(endFrame - startFrame) / sampleRate
    }
}
