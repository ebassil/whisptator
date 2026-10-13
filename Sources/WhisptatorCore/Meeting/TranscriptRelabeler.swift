import AVFoundation
import Foundation

/// Per-channel RMS energy of a stored session file, sampled on a fixed window.
/// Streams through the file so memory stays bounded regardless of length.
public struct ChannelEnergyProfile: Sendable {
    public let windowSeconds: Double
    public let mic: [Float]
    public let system: [Float]

    public init(windowSeconds: Double, mic: [Float], system: [Float]) {
        self.windowSeconds = windowSeconds
        self.mic = mic
        self.system = system
    }

    public var totalSeconds: Double { Double(mic.count) * windowSeconds }

    public func micRMS(from startSeconds: Double, to endSeconds: Double) -> Float {
        rms(of: mic, from: startSeconds, to: endSeconds)
    }

    public func systemRMS(from startSeconds: Double, to endSeconds: Double) -> Float {
        rms(of: system, from: startSeconds, to: endSeconds)
    }

    private func rms(of values: [Float], from startSeconds: Double, to endSeconds: Double) -> Float {
        guard !values.isEmpty, endSeconds > startSeconds else { return 0 }
        let lo = min(max(0, Int(startSeconds / windowSeconds)), values.count - 1)
        let hi = min(max(lo + 1, Int((endSeconds / windowSeconds).rounded(.up))), values.count)
        var sum: Double = 0
        for i in lo..<hi { sum += Double(values[i]) * Double(values[i]) }
        return Float((sum / Double(hi - lo)).squareRoot())
    }
}

public enum DiarizationAudio {
    public enum DiarizationAudioError: Error, LocalizedError {
        case unreadable(URL)
        public var errorDescription: String? {
            switch self {
            case .unreadable(let url): return "Could not decode audio file \(url.lastPathComponent)"
            }
        }
    }

    /// Streams the file in `chunkSeconds` pieces, emitting per-channel 16 kHz
    /// mono arrays (channel 0 = mic/left, channel 1 = system/right; mono files
    /// only emit channel 0).
    public static func stream16kHzChunks(
        of mp3URL: URL,
        chunkSeconds: Double,
        handler: (_ channel: Int, _ startSample: Int, _ samples16k: [Float]) throws -> Void
    ) throws {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: mp3URL)
        } catch {
            throw DiarizationAudioError.unreadable(mp3URL)
        }
        let rate = file.processingFormat.sampleRate
        let channels = Int(file.processingFormat.channelCount)
        let framesPerChunk = max(1, Int(rate * chunkSeconds))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(framesPerChunk)) else {
            throw DiarizationAudioError.unreadable(mp3URL)
        }
        var absoluteFrame: AVAudioFramePosition = 0
        while absoluteFrame < file.length {
            do {
                try file.read(into: buffer)
            } catch {
                // Compressed formats can raise on the read that reaches EOF
                // instead of returning zero frames; if we already consumed
                // audio, treat it as end-of-stream.
                if absoluteFrame > 0 { break }
                throw DiarizationAudioError.unreadable(mp3URL)
            }
            if buffer.frameLength == 0 { break }
            guard let data = buffer.floatChannelData else { break }
            for ch in 0..<channels {
                let samples = Array(UnsafeBufferPointer(start: data[ch], count: Int(buffer.frameLength)))
                let mono16 = AudioResampling.to16kHzMono(samples, from: rate)
                let startSample = Int(Double(absoluteFrame) * 16_000.0 / rate)
                try handler(ch, startSample, mono16)
            }
            absoluteFrame += AVAudioFramePosition(buffer.frameLength)
        }
    }

    /// Bounded-memory per-channel windowed RMS for mic-dominance decisions.
    public static func energyProfile(of mp3URL: URL, windowSeconds: Double = 0.1) throws -> ChannelEnergyProfile {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: mp3URL)
        } catch {
            throw DiarizationAudioError.unreadable(mp3URL)
        }
        let rate = file.processingFormat.sampleRate
        let channels = Int(file.processingFormat.channelCount)
        let framesPerWindow = max(1, Int(rate * windowSeconds))
        let totalWindows = max(1, Int(Double(file.length) / Double(framesPerWindow)) + 2)

        var micSums = [Double](repeating: 0, count: totalWindows)
        var micCounts = [Int](repeating: 0, count: totalWindows)
        var sysSums = [Double](repeating: 0, count: totalWindows)
        var sysCounts = [Int](repeating: 0, count: totalWindows)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(framesPerWindow)) else {
            throw DiarizationAudioError.unreadable(mp3URL)
        }
        var absoluteFrame: AVAudioFramePosition = 0
        while absoluteFrame < file.length {
            do {
                try file.read(into: buffer)
            } catch {
                if absoluteFrame > 0 { break }
                throw DiarizationAudioError.unreadable(mp3URL)
            }
            if buffer.frameLength == 0 { break }
            guard let data = buffer.floatChannelData else { break }
            let n = Int(buffer.frameLength)
            for i in 0..<n {
                let window = Int((absoluteFrame + AVAudioFramePosition(i)) / AVAudioFramePosition(framesPerWindow))
                guard window < totalWindows else { break }
                let micValue = data[0][i]
                micSums[window] += Double(micValue) * Double(micValue)
                micCounts[window] += 1
                if channels > 1 {
                    let sysValue = data[1][i]
                    sysSums[window] += Double(sysValue) * Double(sysValue)
                    sysCounts[window] += 1
                }
            }
            absoluteFrame += AVAudioFramePosition(n)
        }

        func rmsArray(_ sums: [Double], _ counts: [Int]) -> [Float] {
            zip(sums, counts).map { sum, count in
                count > 0 ? Float((sum / Double(count)).squareRoot()) : 0
            }
        }
        return ChannelEnergyProfile(
            windowSeconds: Double(framesPerWindow) / rate,
            mic: rmsArray(micSums, micCounts),
            system: rmsArray(sysSums, sysCounts)
        )
    }
}

/// Post-recording pass: attributes each live transcript line to a speaker
/// (model segments for the system channel, "Me" for mic-dominant lines,
/// system-channel-wins on overlap) and rewrites the file atomically via
/// temp-file + rename so readers always see a complete transcript.
public enum TranscriptRelabeler {
    public enum RelabelError: Error, LocalizedError {
        case unreadable
        public var errorDescription: String? { "Could not read the session transcript for relabeling" }
    }

    /// RMS above which a channel counts as carrying audio energy.
    public static let activeThreshold: Float = 0.004

    public struct TranscriptLine: Sendable {
        public let raw: String
        public let timestampText: String
        public let startSeconds: Double
        public let body: String
        public let isMarker: Bool
    }

    public static func parseLines(_ contents: String) -> [TranscriptLine] {
        contents.split(separator: "\n", omittingEmptySubsequences: true).map { rawLine in
            let line = String(rawLine)
            guard line.hasPrefix("["), line.count >= 11, line[line.index(line.startIndex, offsetBy: 9)] == "]" else {
                return TranscriptLine(raw: line, timestampText: "", startSeconds: -1, body: line, isMarker: false)
            }
            let stamp = line.dropFirst().prefix(8)
            let components = stamp.split(separator: ":")
            guard components.count == 3,
                  let h = Double(components[0]), let m = Double(components[1]), let s = Double(components[2])
            else {
                return TranscriptLine(raw: line, timestampText: "", startSeconds: -1, body: line, isMarker: false)
            }
            let body = line.count > 11 ? String(line.dropFirst(11)) : ""
            return TranscriptLine(
                raw: line,
                timestampText: String(stamp),
                startSeconds: h * 3600 + m * 60 + s,
                body: body,
                isMarker: body.hasPrefix("(")
            )
        }
    }

    /// Pure attribution logic (unit-testable): returns one label per line, or
    /// nil meaning "leave the line exactly as it is".
    public static func attributeLabels(
        lines: [TranscriptLine],
        segments: [DiarizedSegment],
        energy: ChannelEnergyProfile?,
        totalSeconds: Double
    ) -> [String?] {
        var labels: [String?] = []
        var previousLabel: String?
        for (index, line) in lines.enumerated() {
            guard line.startSeconds >= 0, !line.isMarker else {
                labels.append(nil)
                continue
            }
            let windowEnd = index + 1 < lines.count && lines[index + 1].startSeconds >= 0
                ? lines[index + 1].startSeconds
                : max(totalSeconds, line.startSeconds + 1)

            let micE = energy?.micRMS(from: line.startSeconds, to: windowEnd) ?? 0
            let sysE = energy?.systemRMS(from: line.startSeconds, to: windowEnd) ?? 0
            let micActive = micE > activeThreshold
            let sysActive = sysE > activeThreshold

            let speaker = overlappingSpeaker(in: line.startSeconds..<windowEnd, segments: segments)

            let label: String?
            if micActive && !sysActive {
                label = "Me"
            } else if let speaker {
                label = speaker // system channel wins when both are active
            } else if sysActive {
                label = previousLabel
            } else {
                label = previousLabel ?? (micActive ? "Me" : nil)
            }
            if let label { previousLabel = label }
            labels.append(label)
        }
        return labels
    }

    private static func overlappingSpeaker(in range: Range<Double>, segments: [DiarizedSegment]) -> String? {
        var best: (speaker: String, overlap: Double)?
        for segment in segments {
            let overlap = min(range.upperBound, segment.end) - max(range.lowerBound, segment.start)
            if overlap > 0, overlap > (best?.overlap ?? 0) {
                best = (segment.speaker, overlap)
            }
        }
        return best?.speaker
    }

    /// Rewrites `transcriptURL` with speaker labels. Throws on failure, in
    /// which case the live transcript file is left untouched.
    @discardableResult
    public static func relabel(
        transcriptURL: URL,
        audioURL: URL,
        segments: [DiarizedSegment]
    ) throws -> URL {
        guard let contents = try? String(contentsOf: transcriptURL, encoding: .utf8) else {
            throw RelabelError.unreadable
        }
        let lines = parseLines(contents)

        var energy: ChannelEnergyProfile?
        if FileManager.default.fileExists(atPath: audioURL.path) {
            energy = try? DiarizationAudio.energyProfile(of: audioURL)
        }
        let totalSeconds = energy?.totalSeconds
            ?? lines.compactMap { $0.startSeconds >= 0 ? $0.startSeconds : nil }.max().map { $0 + 1 }
            ?? 0

        let labels = attributeLabels(lines: lines, segments: segments, energy: energy, totalSeconds: totalSeconds)

        var out = ""
        for (line, label) in zip(lines, labels) {
            if let label {
                out += "[\(line.timestampText)] \(label): \(line.body)\n"
            } else {
                out += "\(line.raw)\n"
            }
        }

        let tempURL = transcriptURL.appendingPathExtension("relabeling-\(UUID().uuidString)")
        try Data(out.utf8).write(to: tempURL)
        if Darwin.rename(tempURL.path, transcriptURL.path) != 0 {
            try? FileManager.default.removeItem(at: tempURL)
            throw RelabelError.unreadable
        }
        return transcriptURL
    }
}
