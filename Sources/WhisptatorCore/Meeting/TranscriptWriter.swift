import Foundation

/// The canonical meeting recording clock: 48 kHz sample offsets, not wall time.
public enum SessionTimeline {
    public static func seconds(frame: Int64, sampleRate: Double = StereoAligner.sampleRate) -> Double {
        Double(frame) / sampleRate
    }

    /// `HH:MM:SS` derived from the frame offset on the recording timeline.
    public static func timestamp(frame: Int64, sampleRate: Double = StereoAligner.sampleRate) -> String {
        let total = max(0, Int(seconds(frame: frame, sampleRate: sampleRate).rounded(.down)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public static func line(frame: Int64, text: String) -> String {
        "[\(timestamp(frame: frame))] \(text)"
    }

    public static func markerLine(frame: Int64, text: String) -> String {
        "[\(timestamp(frame: frame))] (\(text))"
    }
}

public final class TranscriptWriter: @unchecked Sendable {
    public let fileURL: URL
    private let queue = DispatchQueue(label: "com.whisptator.transcript-writer")
    private var handle: FileHandle?

    public init(url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)
        guard let handle = FileHandle(forWritingAtPath: url.path) else {
            throw NSError(domain: "TranscriptWriter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open transcript file \(url.path)"])
        }
        self.handle = handle
        self.fileURL = url
    }

    /// Appends one already-formatted line and fsyncs it (crash durability).
    public func appendLine(_ line: String) {
        queue.async { [weak self] in
            guard let self, let handle = self.handle else { return }
            var data = Data(line.utf8)
            data.append(0x0A)
            handle.write(data)
            do {
                try handle.synchronize()
            } catch {
                AppLogger.shared.log(category: .transcription, message: "Transcript fsync failed: \(error.localizedDescription)")
            }
        }
    }

    public func appendText(frame: Int64, text: String) {
        appendLine(SessionTimeline.line(frame: frame, text: text))
    }

    public func appendMarker(frame: Int64, text: String) {
        appendLine(SessionTimeline.markerLine(frame: frame, text: text))
    }

    /// Resumes after every line enqueued before this call has been appended and fsynced.
    public func waitForPendingWrites() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { continuation.resume() }
        }
    }

    public func close() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self else { continuation.resume(); return }
                if let handle = self.handle {
                    try? handle.synchronize()
                    try? handle.close()
                    self.handle = nil
                }
                continuation.resume()
            }
        }
    }
}
