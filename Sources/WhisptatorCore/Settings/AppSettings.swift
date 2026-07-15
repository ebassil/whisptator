import Foundation
#if canImport(AppKit)
import AppKit
#endif

public enum PasteMode: String, CaseIterable, Sendable {
    case clipboard
    case typing
}

public enum CleanupMode: String, CaseIterable, Sendable {
    case raw
    case clean
}

public enum AudioSourceMode: String, CaseIterable, Sendable {
    case systemAndMicrophone = "system_and_microphone"
    case microphoneOnly = "microphone_only"
    case systemOnly = "system_only"
}

public enum AudioRetentionMode: String, CaseIterable, Sendable {
    case keep
    case deleteAfterTranscription = "delete_after_transcription"
    case autoDeleteAfterDays = "auto_delete_after_days"
}

public struct ShortcutKeyCode: Equatable, Sendable {
    public var keyCode: UInt32
    public var modifierFlags: UInt32
    public var modifierKeyCodes: [UInt32]

    public init(keyCode: UInt32 = 0, modifierFlags: UInt32 = 0, modifierKeyCodes: [UInt32] = []) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.modifierKeyCodes = modifierKeyCodes
    }

    public var isModifierOnly: Bool { !modifierKeyCodes.isEmpty }

    public var isEmpty: Bool { !isModifierOnly && keyCode == 0 && modifierFlags == 0 }
}

extension ShortcutKeyCode: Codable {
    enum CodingKeys: String, CodingKey {
        case keyCode
        case modifierFlags
        case modifierKeyCodes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keyCode = try container.decodeIfPresent(UInt32.self, forKey: .keyCode) ?? 0
        self.modifierFlags = try container.decodeIfPresent(UInt32.self, forKey: .modifierFlags) ?? 0
        self.modifierKeyCodes = try container.decodeIfPresent([UInt32].self, forKey: .modifierKeyCodes) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifierFlags, forKey: .modifierFlags)
        if !modifierKeyCodes.isEmpty {
            try container.encode(modifierKeyCodes, forKey: .modifierKeyCodes)
        }
    }
}

public struct FillerWord: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var word: String
    public var isEnabled: Bool

    public init(word: String, isEnabled: Bool = true) {
        self.id = word.lowercased()
        self.word = word
        self.isEnabled = isEnabled
    }
}

public struct WordReplacement: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var trigger: String
    public var replacement: String
    public var isEnabled: Bool

    public init(trigger: String, replacement: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.trigger = trigger
        self.replacement = replacement
        self.isEnabled = isEnabled
    }
}

public struct Snippet: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var trigger: String
    public var expansion: String
    public var isEnabled: Bool

    public init(trigger: String, expansion: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.trigger = trigger
        self.expansion = expansion
        self.isEnabled = isEnabled
    }
}

@Observable
public final class AppSettings: @unchecked Sendable {
    public init() {}

    // MARK: - Keys

    private enum Key {
        static let pushToTalkShortcut = "pushToTalkShortcut"
        static let handsFreeShortcut = "handsFreeShortcut"
        static let meetingShortcut = "meetingShortcut"
        static let pasteMode = "pasteMode"
        static let selectedAudioDeviceID = "selectedAudioDeviceID"
        static let language = "language"
        static let cleanupMode = "cleanupMode"
        static let fillerWords = "fillerWords"
        static let wordReplacements = "wordReplacements"
        static let snippets = "snippets"
        static let meetingAudioSource = "meetingAudioSource"
        static let meetingRetention = "meetingRetention"
        static let meetingRetentionDays = "meetingRetentionDays"
        static let meetingSaveLocation = "meetingSaveLocation"
        static let launchAtLogin = "launchAtLogin"
        static let showInDock = "showInDock"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    // MARK: - Shortcuts

    public var pushToTalkShortcut: ShortcutKeyCode {
        get { Self.decode(ShortcutKeyCode.self, forKey: Key.pushToTalkShortcut) ?? ShortcutKeyCode(keyCode: 63, modifierFlags: 0) }
        set { Self.encode(newValue, forKey: Key.pushToTalkShortcut) }
    }

    public var handsFreeShortcut: ShortcutKeyCode {
        get { Self.decode(ShortcutKeyCode.self, forKey: Key.handsFreeShortcut) ?? ShortcutKeyCode(keyCode: 63, modifierFlags: 0) }
        set { Self.encode(newValue, forKey: Key.handsFreeShortcut) }
    }

    public var meetingShortcut: ShortcutKeyCode {
        get { Self.decode(ShortcutKeyCode.self, forKey: Key.meetingShortcut) ?? ShortcutKeyCode(keyCode: 0, modifierFlags: 0) }
        set { Self.encode(newValue, forKey: Key.meetingShortcut) }
    }

    // MARK: - Dictation

    public var pasteMode: PasteMode {
        get { PasteMode(rawValue: UserDefaults.standard.string(forKey: Key.pasteMode) ?? PasteMode.clipboard.rawValue) ?? .clipboard }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.pasteMode) }
    }

    public var selectedAudioDeviceID: String {
        get { UserDefaults.standard.string(forKey: Key.selectedAudioDeviceID) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Key.selectedAudioDeviceID) }
    }

    public var language: String {
        get { UserDefaults.standard.string(forKey: Key.language) ?? "auto" }
        set { UserDefaults.standard.set(newValue, forKey: Key.language) }
    }

    // MARK: - Cleanup

    public var cleanupMode: CleanupMode {
        get { CleanupMode(rawValue: UserDefaults.standard.string(forKey: Key.cleanupMode) ?? CleanupMode.clean.rawValue) ?? .clean }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.cleanupMode) }
    }

    public var fillerWords: [FillerWord] {
        get { Self.decode([FillerWord].self, forKey: Key.fillerWords) ?? Self.defaultFillerWords }
        set { Self.encode(newValue, forKey: Key.fillerWords) }
    }

    public var wordReplacements: [WordReplacement] {
        get { Self.decode([WordReplacement].self, forKey: Key.wordReplacements) ?? [] }
        set { Self.encode(newValue, forKey: Key.wordReplacements) }
    }

    public var snippets: [Snippet] {
        get { Self.decode([Snippet].self, forKey: Key.snippets) ?? [] }
        set { Self.encode(newValue, forKey: Key.snippets) }
    }

    // MARK: - Meeting

    public var meetingAudioSource: AudioSourceMode {
        get { AudioSourceMode(rawValue: UserDefaults.standard.string(forKey: Key.meetingAudioSource) ?? AudioSourceMode.systemAndMicrophone.rawValue) ?? .systemAndMicrophone }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.meetingAudioSource) }
    }

    public var meetingRetention: AudioRetentionMode {
        get { AudioRetentionMode(rawValue: UserDefaults.standard.string(forKey: Key.meetingRetention) ?? AudioRetentionMode.deleteAfterTranscription.rawValue) ?? .deleteAfterTranscription }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.meetingRetention) }
    }

    public var meetingRetentionDays: Int {
        get { UserDefaults.standard.integer(forKey: Key.meetingRetentionDays) == 0 ? 30 : UserDefaults.standard.integer(forKey: Key.meetingRetentionDays) }
        set { UserDefaults.standard.set(newValue, forKey: Key.meetingRetentionDays) }
    }

    public var meetingSaveLocation: String {
        get { UserDefaults.standard.string(forKey: Key.meetingSaveLocation) ?? "\(NSHomeDirectory())/Documents/Whisptator/Meetings" }
        set { UserDefaults.standard.set(newValue, forKey: Key.meetingSaveLocation) }
    }

    // MARK: - General

    public var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: Key.launchAtLogin) }
        set { UserDefaults.standard.set(newValue, forKey: Key.launchAtLogin) }
    }

    public var showInDock: Bool {
        get { UserDefaults.standard.bool(forKey: Key.showInDock) }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.showInDock)
            Task { @MainActor in
                let policy: NSApplication.ActivationPolicy = newValue ? .regular : .accessory
                NSApp.setActivationPolicy(policy)
            }
        }
    }

    public var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Key.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    // MARK: - Defaults

    private static let defaultFillerWords: [FillerWord] = [
        FillerWord(word: "um"),
        FillerWord(word: "uh"),
        FillerWord(word: "so"),
        FillerWord(word: "well"),
        FillerWord(word: "like"),
    ]

    // MARK: - Codable Helpers

    private static func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
