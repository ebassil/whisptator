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
    ///
    /// One resampler per channel is kept alive for the whole stream: a fresh
    /// `AVAudioConverter` per chunk restarts the interpolation filter at every
    /// boundary, which smears the audio that diarization embeds, and its
    /// retained samples shift the output against the timeline it is compared
    /// with.
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
        let outRate = 16_000.0
        let resamplers = (0..<channels).map { _ in StreamResampler(sourceRate: rate, targetRate: outRate) }
        var emitted = [Int](repeating: 0, count: channels)

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
                let mono16 = resamplers[ch].append(samples)
                let startSample = emitted[ch]
                emitted[ch] += mono16.count
                try handler(ch, startSample, mono16)
            }
            absoluteFrame += AVAudioFramePosition(buffer.frameLength)
        }
        for ch in 0..<channels {
            let tail = resamplers[ch].flush()
            guard !tail.isEmpty else { continue }
            let startSample = emitted[ch]
            emitted[ch] += tail.count
            try handler(ch, startSample, tail)
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

/// Post-recording pass: attributes each live transcript line to a speaker and
/// rewrites the file atomically via temp-file + rename so readers always see a
/// complete transcript.
///
/// Attribution prefers the session ledger — the transcriber knows which channel
/// each line was cut from, and the echo gate knows how much of a microphone line
/// was really the local voice. Channel energy is only a fallback for sessions
/// recorded before the ledger existed: with a microphone that hears the laptop's
/// speakers, "the mic channel is active" says almost nothing about who spoke.
public enum TranscriptRelabeler {
    public enum RelabelError: Error, LocalizedError {
        case unreadable
        public var errorDescription: String? { "Could not read the session transcript for relabeling" }
    }

    /// RMS above which a channel counts as carrying audio energy.
    public static let activeThreshold: Float = 0.004
    /// Microphone lines at or above this local-speech share are the user.
    public static let meShareThreshold = 0.5
    /// Share of a microphone line's words that overlapping system audio must
    /// reproduce before the line is treated as an echo copy of it.
    public static let echoDuplicateSimilarity = 0.6

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

    /// Outcome of attribution: a label per line, or nil meaning "leave the line
    /// exactly as it is", plus the indices of lines to drop outright.
    public struct Attribution: Sendable {
        public let labels: [String?]
        public let dropped: Set<Int>
    }

    /// Pure attribution logic (unit-testable) using the session ledger.
    public static func attributeLines(
        lines: [TranscriptLine],
        segments: [DiarizedSegment],
        ledger: [TranscriptLedger.Entry],
        energy: ChannelEnergyProfile?,
        totalSeconds: Double
    ) -> Attribution {
        var labels: [String?] = Array(repeating: nil, count: lines.count)
        var dropped = Set<Int>()
        var previousLabel: String?

        // Line index → ledger entry. The transcriber appends transcript lines and
        // ledger entries one after the other on a single lane, so the k-th
        // transcribed line is the k-th entry; markers never have entries.
        var textLines: [Int] = []
        for (index, line) in lines.enumerated() where line.startSeconds >= 0 && !line.isMarker {
            textLines.append(index)
        }
        var entryByLineIndex: [Int: TranscriptLedger.Entry] = [:]
        if ledger.count == textLines.count {
            for (position, lineIndex) in textLines.enumerated() {
                entryByLineIndex[lineIndex] = ledger[position]
            }
        } else if !ledger.isEmpty {
            // Counts differ (a chunk failed to transcribe, or a crash truncated the
            // file): match by text, consuming ledger entries in order so each is
            // used at most once.
            var cursor = 0
            for lineIndex in textLines {
                let body = lines[lineIndex].body
                var probe = cursor
                while probe < ledger.count {
                    if ledger[probe].text == body {
                        entryByLineIndex[lineIndex] = ledger[probe]
                        cursor = probe + 1
                        break
                    }
                    probe += 1
                }
            }
        }

        var previousSystemLabel: String?
        for (index, line) in lines.enumerated() {
            guard line.startSeconds >= 0, !line.isMarker else { continue }
            let windowEnd = index + 1 < lines.count && lines[index + 1].startSeconds >= 0
                ? lines[index + 1].startSeconds
                : max(totalSeconds, line.startSeconds + 1)

            guard let entry = entryByLineIndex[index] else {
                // No provenance for this line: fall back to channel energy.
                labels[index] = energyLabel(for: line, windowEnd: windowEnd, segments: segments, energy: energy, previous: previousLabel)
                if let label = labels[index] { previousLabel = label }
                continue
            }

            // The ledger knows the span the audio actually covered, which is what
            // the speaker lookup needs. "Until the next line" cannot be used here:
            // two channels routinely produce lines that start in the same second,
            // which makes that window empty, and using the following line's start
            // when it is later would borrow another speaker's audio.
            let spanStart = min(line.startSeconds, entry.startSeconds)
            let spanEnd = max(entry.endSeconds, spanStart + 1)
            let spanSpeaker = overlappingSpeaker(in: spanStart..<spanEnd, segments: segments)

            switch entry.channel {
            case .system:
                // Inherit the last system-channel label so a remote utterance the
                // segmentation missed does not fall back to an unlabeled line —
                // but never inherit `Me`, which would put the local user's name on
                // someone else's words.
                let label = spanSpeaker ?? previousSystemLabel
                labels[index] = label
                if let spanSpeaker { previousSystemLabel = spanSpeaker }
                if let label { previousLabel = label }
            case .mic:
                let share = entry.localShare
                let systemActive = (energy?.systemRMS(from: spanStart, to: spanEnd) ?? 0) > activeThreshold
                if echoesNeighbour(entry: entry, line: line, entries: entryByLineIndex, lines: lines) {
                    // A microphone line whose words are reproduced by system audio
                    // over the same span is the echo path, whatever the envelope
                    // gate measured — the same sentence was not said twice at the
                    // same moment by two people.
                    dropped.insert(index)
                } else if let share, share < meShareThreshold, systemActive, let spanSpeaker {
                    // Microphone audio the echo gate says is mostly the remote
                    // voice, with no system-channel copy: keep the words, but
                    // attribute them to the voice they came from.
                    labels[index] = spanSpeaker
                    previousSystemLabel = spanSpeaker
                    previousLabel = spanSpeaker
                } else {
                    labels[index] = "Me"
                    previousLabel = "Me"
                }
            }
        }
        return Attribution(labels: labels, dropped: dropped)
    }

    /// Energy-only attribution, for sessions without a ledger.
    public static func attributeLabels(
        lines: [TranscriptLine],
        segments: [DiarizedSegment],
        energy: ChannelEnergyProfile?,
        totalSeconds: Double
    ) -> [String?] {
        attributeLines(
            lines: lines,
            segments: segments,
            ledger: [],
            energy: energy,
            totalSeconds: totalSeconds
        ).labels
    }

    private static func energyLabel(
        for line: TranscriptLine,
        windowEnd: Double,
        segments: [DiarizedSegment],
        energy: ChannelEnergyProfile?,
        previous: String?
    ) -> String? {
        let micE = energy?.micRMS(from: line.startSeconds, to: windowEnd) ?? 0
        let sysE = energy?.systemRMS(from: line.startSeconds, to: windowEnd) ?? 0
        let micActive = micE > activeThreshold
        let sysActive = sysE > activeThreshold
        let speaker = overlappingSpeaker(in: line.startSeconds..<windowEnd, segments: segments)

        if micActive && !sysActive {
            return "Me"
        } else if let speaker {
            return speaker
        } else if sysActive {
            return previous
        } else {
            return previous ?? (micActive ? "Me" : nil)
        }
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

    /// True when a microphone line is the same utterance as a nearby line from
    /// the system channel — the echo path duplicating a remote speaker.
    /// True when a microphone line is explained by system-channel audio over the
    /// same span — the echo path duplicating a remote speaker.
    ///
    /// Measured as the share of the *microphone* line's words that the
    /// overlapping system text reproduces. Direction matters: a long microphone
    /// segment can echo several short system lines, and comparing one sentence at
    /// a time with a symmetric score would either miss that case or drop a local
    /// utterance that merely quotes a short remote phrase back at them.
    private static func echoesNeighbour(
        entry: TranscriptLedger.Entry,
        line: TranscriptLine,
        entries: [Int: TranscriptLedger.Entry],
        lines: [TranscriptLine]
    ) -> Bool {
        let micTokens = tokens(line.body)
        guard micTokens.count >= 3 else { return false }
        let lo = entry.startSeconds - 2
        let hi = max(entry.endSeconds, entry.startSeconds + 1) + 2

        var overlapping: [String] = []
        for (index, otherEntry) in entries where otherEntry.channel == .system {
            guard otherEntry.startSeconds < hi, otherEntry.endSeconds > lo else { continue }
            guard index < lines.count else { continue }
            overlapping.append(otherEntry.text)
        }
        guard !overlapping.isEmpty else { return false }

        let systemTokens = tokens(overlapping.joined(separator: " "))
        guard systemTokens.count >= 3 else { return false }
        let coverage = longestCommonSubsequence(micTokens, systemTokens) / Double(micTokens.count)
        return coverage >= echoDuplicateSimilarity
    }

    /// Removes a leading `Me:` / `Speaker N:` label so duplicate detection can
    /// compare the words themselves in an already-relabeled transcript.
    static func stripSpeaker(_ body: String) -> String {
        guard let colon = body.firstIndex(of: ":") else { return body }
        let label = body[body.startIndex..<colon].trimmingCharacters(in: .whitespaces)
        guard label == "Me" || label.hasPrefix("Speaker ") else { return body }
        return String(body[body.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
    }

    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    /// Length of the longest common subsequence of two token lists.
    static func longestCommonSubsequence(_ a: [String], _ b: [String]) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        var previous = [Int](repeating: 0, count: b.count + 1)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    current[j] = previous[j - 1] + 1
                } else {
                    current[j] = max(previous[j], current[j - 1])
                }
            }
            swap(&previous, &current)
            current = Array(repeating: 0, count: b.count + 1)
        }
        return Double(previous[b.count])
    }

    /// Longest common subsequence scaled by the shorter side.
    static func longestCommonSubsequenceRatio(_ a: [String], _ b: [String]) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        return longestCommonSubsequence(a, b) / Double(min(a.count, b.count))
    }

    /// Rewrites `transcriptURL` with speaker labels. Throws on failure, in
    /// which case the live transcript file is left untouched.
    @discardableResult
    public static func relabel(
        transcriptURL: URL,
        audioURL: URL,
        segments: [DiarizedSegment],
        ledger: TranscriptLedger? = nil
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

        let attribution = attributeLines(
            lines: lines,
            segments: segments,
            ledger: ledger?.all ?? [],
            energy: energy,
            totalSeconds: totalSeconds
        )

        var out = ""
        for (index, line) in lines.enumerated() {
            if attribution.dropped.contains(index) { continue }
            if let label = attribution.labels[index] {
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
