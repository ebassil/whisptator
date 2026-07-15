import Foundation

public final class TranscriptSaver: @unchecked Sendable {
    public init() {}

    public func saveTranscript(_ text: String, to directory: String) {
        let fileManager = FileManager.default
        let dirURL = URL(fileURLWithPath: directory)

        if !fileManager.fileExists(atPath: directory) {
            try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "meeting_\(timestamp).txt"
        let fileURL = dirURL.appendingPathComponent(filename)

        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    public func cleanupOldAudioFiles(in directory: String, olderThanDays days: Int) {
        let fileManager = FileManager.default
        let dirURL = URL(fileURLWithPath: directory)

        guard let files = try? fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        for file in files where file.pathExtension == "wav" {
            if let attributes = try? file.resourceValues(forKeys: [.creationDateKey]),
               let creationDate = attributes.creationDate,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}
