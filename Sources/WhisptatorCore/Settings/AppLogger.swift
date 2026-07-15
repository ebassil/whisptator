import Foundation

public enum LogCategory: String, Sendable, CaseIterable {
    case shortcut
    case dictation
    case meeting
    case model
    case transcription
    case audio
    case settings
    case overlay
    case system
}

public struct LogEntry: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let category: LogCategory
    public let message: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), category: LogCategory, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.message = message
    }
}

@Observable
public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()

    public private(set) var entries: [LogEntry] = []

    private let maxEntries = 1000
    private let lock = NSLock()

    private init() {}

    public func log(category: LogCategory, message: String) {
        let entry = LogEntry(category: category, message: message)
        lock.lock()
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        lock.unlock()
    }

    public func clear() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }
}
