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
    public private(set) var isPaused: Bool = false
    public private(set) var enabledCategories: Set<LogCategory> = Set(LogCategory.allCases)

    private let maxEntries = 1000
    private let lock = NSLock()

    private init() {}

    public func log(category: LogCategory, message: String) {
        lock.lock()
        let paused = isPaused
        let enabled = enabledCategories.contains(category)
        lock.unlock()

        guard !paused, enabled else { return }

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

    public func setPaused(_ paused: Bool) {
        lock.lock()
        isPaused = paused
        lock.unlock()
    }

    public func setCategoryEnabled(_ category: LogCategory, enabled: Bool) {
        lock.lock()
        if enabled {
            enabledCategories.insert(category)
        } else {
            enabledCategories.remove(category)
        }
        lock.unlock()
    }

    public func enableAllCategories() {
        lock.lock()
        enabledCategories = Set(LogCategory.allCases)
        lock.unlock()
    }

    public func disableAllCategories() {
        lock.lock()
        enabledCategories = []
        lock.unlock()
    }

    public func loadFrom(settings: AppSettings) {
        lock.lock()
        isPaused = settings.isLoggingPaused
        enabledCategories = Set(settings.logEnabledCategories.compactMap(LogCategory.init(rawValue:)))
        lock.unlock()
    }
}
