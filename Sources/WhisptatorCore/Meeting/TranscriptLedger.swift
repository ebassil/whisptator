import Foundation

/// Provenance for every line the live transcriber appends to a session
/// transcript: which channel the audio came from, the time range it covered,
/// and how much of it was the local microphone speaker rather than echo.
///
/// The relabel pass needs exactly this to write `Me:` vs `Speaker N:` without
/// guessing from channel energy — which cannot work when the microphone hears
/// the laptop's own speakers. The ledger lives in memory only: it is produced
/// and consumed inside one session, so no side-car file is added to the user's
/// meetings folder, and a crash before relabeling leaves the live transcript
/// exactly as the durable-append contract promises.
public final class TranscriptLedger: @unchecked Sendable {
    public struct Entry: Sendable {
        /// Index among transcript lines, counting only transcribed text lines
        /// (markers such as `(mic muted)` are not written by the transcriber).
        public let lineIndex: Int
        public let channel: AudioChannel
        public let startSeconds: Double
        public let endSeconds: Double
        /// Fraction of the segment classified as local microphone speech.
        /// `nil` when no echo gate was in play (mono sessions, or before the
        /// gate locked onto the echo path).
        public let localShare: Double?
        /// The text that was appended, kept so the relabeler can confirm it is
        /// lining up with the right lines before it rewrites the file.
        public let text: String
    }

    private let lock = NSLock()
    private var entries: [Entry] = []

    public init() {}

    public var count: Int {
        lock.lock(); defer { lock.unlock() }
        return entries.count
    }

    public var all: [Entry] {
        lock.lock(); defer { lock.unlock() }
        return entries
    }

    @discardableResult
    public func record(
        channel: AudioChannel,
        startFrame: Int64,
        endFrame: Int64,
        sampleRate: Double,
        localShare: Double?,
        text: String
    ) -> Entry {
        lock.lock()
        let entry = Entry(
            lineIndex: entries.count,
            channel: channel,
            startSeconds: Double(startFrame) / sampleRate,
            endSeconds: Double(endFrame) / sampleRate,
            localShare: localShare,
            text: text
        )
        entries.append(entry)
        lock.unlock()
        return entry
    }

    public func reset() {
        lock.lock()
        entries = []
        lock.unlock()
    }
}
