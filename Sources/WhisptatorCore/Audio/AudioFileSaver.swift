@preconcurrency import AVFoundation

public enum AudioSaveFormat: String, CaseIterable, Sendable {
    case wav
    case mp3

    public var label: String {
        switch self {
        case .wav: return "WAV"
        case .mp3: return "MP3"
        }
    }

    public var fileExtension: String { rawValue }
}

public struct AudioSaveSettings: Sendable {
    public var format: AudioSaveFormat = .wav
    public var mp3Bitrate: Int = 256

    public init(format: AudioSaveFormat = .wav, mp3Bitrate: Int = 256) {
        self.format = format
        self.mp3Bitrate = mp3Bitrate
    }
}

public final class AudioFileSaver: @unchecked Sendable {
    public init() {}

    @discardableResult
    public func saveAudioFile(samples: [Float], sampleRate: Int, to directory: String, settings: AudioSaveSettings = .init()) -> String? {
        let fm = FileManager.default
        let dirURL = URL(fileURLWithPath: directory)
        if !fm.fileExists(atPath: directory) {
            try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }

        let filename = filename(for: settings.format)
        let fileURL = dirURL.appendingPathComponent(filename)

        switch settings.format {
        case .wav:
            return saveWAV(samples: samples, sampleRate: sampleRate, to: fileURL) ? fileURL.path : nil
        case .mp3:
            return saveMP3(samples: samples, sampleRate: sampleRate, bitrate: settings.mp3Bitrate, to: fileURL) ? fileURL.path : nil
        }
    }

    // MARK: - WAV (via AVAudioFile)

    private func saveWAV(samples: [Float], sampleRate: Int, to url: URL) -> Bool {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(sampleRate),
            channels: 1,
            interleaved: false
        )!
        let frameCount = AVAudioFrameCount(samples.count)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return false
        }
        buffer.frameLength = frameCount
        if let dst = buffer.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { src in
                guard let base = src.baseAddress else { return }
                memcpy(dst, base, samples.count * MemoryLayout<Float>.size)
            }
        }

        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            try file.write(from: buffer)
            return true
        } catch {
            AppLogger.shared.log(category: .audio, message: "WAV write failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - MP3 (direct LAME encoding)

    private func saveMP3(samples: [Float], sampleRate: Int, bitrate: Int, to url: URL) -> Bool {
        guard let encoder = MP3Encoder(sampleRate: sampleRate, channels: 1, bitrate: bitrate, quality: 2) else {
            AppLogger.shared.log(category: .audio, message: "MP3: failed to init encoder")
            return false
        }
        return encoder.encode(samples: samples, to: url)
    }

    // MARK: - Helpers

    private func filename(for format: AudioSaveFormat) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "dictation_\(df.string(from: Date())).\(format.fileExtension)"
    }
}
