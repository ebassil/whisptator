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

public enum OverlayPosition: String, CaseIterable, Sendable {
    case center
    case topRight = "top_right"
    case bottomCenter = "bottom_center"
    case followCursor = "follow_cursor"
}

public enum DualScreenMode: String, CaseIterable, Sendable {
    case primaryOnly = "primary_only"
    case bothDisplays = "both_displays"
    case activeAppDisplay = "active_app_display"
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
    public var onSettingChange: ((String) -> Void)?

    public init() {
        if let raw = UserDefaults.standard.string(forKey: Key.audioFormat),
           let fmt = AudioSaveFormat(rawValue: raw) {
            audioFormat = fmt
        }
        let bitrate = UserDefaults.standard.integer(forKey: Key.mp3Bitrate)
        if bitrate > 0 {
            mp3Bitrate = bitrate
        }

        if let data = UserDefaults.standard.data(forKey: Key.pushToTalkShortcut),
           let decoded = try? JSONDecoder().decode(ShortcutKeyCode.self, from: data) {
            pushToTalkShortcut = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Key.handsFreeShortcut),
           let decoded = try? JSONDecoder().decode(ShortcutKeyCode.self, from: data) {
            handsFreeShortcut = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Key.meetingShortcut),
           let decoded = try? JSONDecoder().decode(ShortcutKeyCode.self, from: data) {
            meetingShortcut = decoded
        }

        if let raw = UserDefaults.standard.string(forKey: Key.pasteMode),
           let parsed = PasteMode(rawValue: raw) {
            pasteMode = parsed
        }
        if let raw = UserDefaults.standard.string(forKey: Key.selectedAudioDeviceID) {
            selectedAudioDeviceID = raw
        }
        if let raw = UserDefaults.standard.string(forKey: Key.language) {
            language = raw
        }

        if let raw = UserDefaults.standard.string(forKey: Key.cleanupMode),
           let parsed = CleanupMode(rawValue: raw) {
            cleanupMode = parsed
        }

        if let data = UserDefaults.standard.data(forKey: Key.fillerWords),
           let decoded = try? JSONDecoder().decode([FillerWord].self, from: data) {
            fillerWords = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Key.wordReplacements),
           let decoded = try? JSONDecoder().decode([WordReplacement].self, from: data) {
            wordReplacements = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Key.snippets),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
        }

        if let raw = UserDefaults.standard.string(forKey: Key.meetingAudioSource),
           let parsed = AudioSourceMode(rawValue: raw) {
            meetingAudioSource = parsed
        }
        if let raw = UserDefaults.standard.string(forKey: Key.meetingRetention),
           let parsed = AudioRetentionMode(rawValue: raw) {
            meetingRetention = parsed
        }
        let meetingDays = UserDefaults.standard.integer(forKey: Key.meetingRetentionDays)
        if meetingDays > 0 {
            meetingRetentionDays = meetingDays
        }
        if let val = UserDefaults.standard.string(forKey: Key.meetingSaveLocation) {
            meetingSaveLocation = val
        }

        if UserDefaults.standard.object(forKey: Key.launchAtLogin) != nil {
            launchAtLogin = UserDefaults.standard.bool(forKey: Key.launchAtLogin)
        }
        if UserDefaults.standard.object(forKey: Key.showInDock) != nil {
            showInDock = UserDefaults.standard.bool(forKey: Key.showInDock)
        }
        if UserDefaults.standard.object(forKey: Key.hasCompletedOnboarding) != nil {
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Key.hasCompletedOnboarding)
        }
        if UserDefaults.standard.object(forKey: Key.saveAudioFiles) != nil {
            saveAudioFiles = UserDefaults.standard.bool(forKey: Key.saveAudioFiles)
        }
        if UserDefaults.standard.object(forKey: Key.isLoggingPaused) != nil {
            isLoggingPaused = UserDefaults.standard.bool(forKey: Key.isLoggingPaused)
        }

        if UserDefaults.standard.object(forKey: Key.overlayEnabled) != nil {
            overlayEnabled = UserDefaults.standard.bool(forKey: Key.overlayEnabled)
        }
        if let raw = UserDefaults.standard.string(forKey: Key.overlayPosition),
           let parsed = OverlayPosition(rawValue: raw) {
            overlayPosition = parsed
        }
        let opacity = UserDefaults.standard.double(forKey: Key.overlayOpacity)
        if opacity != 0 {
            overlayOpacity = opacity
        }
        let size = UserDefaults.standard.double(forKey: Key.overlaySize)
        if size != 0 {
            overlaySize = size
        }
        if let raw = UserDefaults.standard.string(forKey: Key.dualScreenMode),
           let parsed = DualScreenMode(rawValue: raw) {
            dualScreenMode = parsed
        }

        if let val = UserDefaults.standard.string(forKey: Key.audioSaveLocation) {
            audioSaveLocation = val
        }
        if let raw = UserDefaults.standard.string(forKey: Key.selectedModelId) {
            selectedModelId = raw
        }

        if let data = UserDefaults.standard.data(forKey: Key.logEnabledCategories),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            logEnabledCategories = decoded
        }
    }

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
        static let overlayEnabled = "overlayEnabled"
        static let overlayPosition = "overlayPosition"
        static let overlayOpacity = "overlayOpacity"
        static let overlaySize = "overlaySize"
        static let dualScreenMode = "dualScreenMode"
        static let saveAudioFiles = "saveAudioFiles"
        static let audioSaveLocation = "audioSaveLocation"
        static let audioFormat = "audioFormat"
        static let mp3Bitrate = "mp3Bitrate"
        static let isLoggingPaused = "logPaused"
        static let logEnabledCategories = "logEnabledCategories"
        static let selectedModelId = "selectedModelId"
    }

    // MARK: - Shortcuts

    public var pushToTalkShortcut: ShortcutKeyCode = ShortcutKeyCode(keyCode: 63, modifierFlags: 0) {
        didSet {
            Self.encode(pushToTalkShortcut, forKey: Key.pushToTalkShortcut)
            onSettingChange?("pushToTalkShortcut")
        }
    }

    public var handsFreeShortcut: ShortcutKeyCode = ShortcutKeyCode(keyCode: 63, modifierFlags: 0) {
        didSet {
            Self.encode(handsFreeShortcut, forKey: Key.handsFreeShortcut)
            onSettingChange?("handsFreeShortcut")
        }
    }

    public var meetingShortcut: ShortcutKeyCode = ShortcutKeyCode(keyCode: 46, modifierFlags: UInt32(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue)) {
        didSet {
            Self.encode(meetingShortcut, forKey: Key.meetingShortcut)
            onSettingChange?("meetingShortcut")
        }
    }

    // MARK: - Dictation

    public var pasteMode: PasteMode = .clipboard {
        didSet {
            UserDefaults.standard.set(pasteMode.rawValue, forKey: Key.pasteMode)
            onSettingChange?("pasteMode")
        }
    }

    public var selectedAudioDeviceID: String = "" {
        didSet {
            UserDefaults.standard.set(selectedAudioDeviceID, forKey: Key.selectedAudioDeviceID)
            onSettingChange?("selectedAudioDeviceID")
        }
    }

    public var language: String = "auto" {
        didSet {
            UserDefaults.standard.set(language, forKey: Key.language)
            onSettingChange?("language")
        }
    }

    // MARK: - Cleanup

    public var cleanupMode: CleanupMode = .clean {
        didSet {
            UserDefaults.standard.set(cleanupMode.rawValue, forKey: Key.cleanupMode)
            onSettingChange?("cleanupMode")
        }
    }

    public var fillerWords: [FillerWord] = AppSettings.defaultFillerWords {
        didSet {
            Self.encode(fillerWords, forKey: Key.fillerWords)
            onSettingChange?("fillerWords")
        }
    }

    public var wordReplacements: [WordReplacement] = [] {
        didSet {
            Self.encode(wordReplacements, forKey: Key.wordReplacements)
            onSettingChange?("wordReplacements")
        }
    }

    public var snippets: [Snippet] = [] {
        didSet {
            Self.encode(snippets, forKey: Key.snippets)
            onSettingChange?("snippets")
        }
    }

    // MARK: - Meeting

    public var meetingAudioSource: AudioSourceMode = .systemAndMicrophone {
        didSet {
            UserDefaults.standard.set(meetingAudioSource.rawValue, forKey: Key.meetingAudioSource)
            onSettingChange?("meetingAudioSource")
        }
    }

    public var meetingRetention: AudioRetentionMode = .deleteAfterTranscription {
        didSet {
            UserDefaults.standard.set(meetingRetention.rawValue, forKey: Key.meetingRetention)
            onSettingChange?("meetingRetention")
        }
    }

    public var meetingRetentionDays: Int = 30 {
        didSet {
            UserDefaults.standard.set(meetingRetentionDays, forKey: Key.meetingRetentionDays)
            onSettingChange?("meetingRetentionDays")
        }
    }

    public var meetingSaveLocation: String = "\(NSHomeDirectory())/Documents/Whisptator/Meetings" {
        didSet {
            UserDefaults.standard.set(meetingSaveLocation, forKey: Key.meetingSaveLocation)
            onSettingChange?("meetingSaveLocation")
        }
    }

    // MARK: - General

    public var launchAtLogin: Bool = false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin)
            onSettingChange?("launchAtLogin")
        }
    }

    public var showInDock: Bool = false {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: Key.showInDock)
            onSettingChange?("showInDock")
            Task { @MainActor in
                let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
                NSApp.setActivationPolicy(policy)
            }
        }
    }

    public var hasCompletedOnboarding: Bool = false {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding)
            onSettingChange?("hasCompletedOnboarding")
        }
    }

    // MARK: - Model

    public var selectedModelId: String = SupportedModel.default.id {
        didSet {
            UserDefaults.standard.set(selectedModelId, forKey: Key.selectedModelId)
            onSettingChange?("selectedModelId")
        }
    }

    // MARK: - Overlay

    public var overlayEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(overlayEnabled, forKey: Key.overlayEnabled)
            onSettingChange?("overlayEnabled")
        }
    }

    public var overlayPosition: OverlayPosition = .center {
        didSet {
            UserDefaults.standard.set(overlayPosition.rawValue, forKey: Key.overlayPosition)
            onSettingChange?("overlayPosition")
        }
    }

    public var overlayOpacity: Double = 0.85 {
        didSet {
            UserDefaults.standard.set(overlayOpacity, forKey: Key.overlayOpacity)
            onSettingChange?("overlayOpacity")
        }
    }

    public var overlaySize: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(overlaySize, forKey: Key.overlaySize)
            onSettingChange?("overlaySize")
        }
    }

    public var dualScreenMode: DualScreenMode = .primaryOnly {
        didSet {
            UserDefaults.standard.set(dualScreenMode.rawValue, forKey: Key.dualScreenMode)
            onSettingChange?("dualScreenMode")
        }
    }

    // MARK: - Audio Save

    public var saveAudioFiles: Bool = false {
        didSet {
            UserDefaults.standard.set(saveAudioFiles, forKey: Key.saveAudioFiles)
            onSettingChange?("saveAudioFiles")
        }
    }

    public var audioSaveLocation: String = "\(NSHomeDirectory())/Documents/Whisptator/Audio" {
        didSet {
            UserDefaults.standard.set(audioSaveLocation, forKey: Key.audioSaveLocation)
            onSettingChange?("audioSaveLocation")
        }
    }

    public var audioFormat: AudioSaveFormat = .wav {
        didSet {
            UserDefaults.standard.set(audioFormat.rawValue, forKey: Key.audioFormat)
            onSettingChange?("audioFormat")
        }
    }

    public var mp3Bitrate: Int = 256 {
        didSet {
            UserDefaults.standard.set(mp3Bitrate, forKey: Key.mp3Bitrate)
            onSettingChange?("mp3Bitrate")
        }
    }

    public var audioSaveSettings: AudioSaveSettings {
        AudioSaveSettings(format: audioFormat, mp3Bitrate: mp3Bitrate)
    }

    // MARK: - Logging

    public var isLoggingPaused: Bool = false {
        didSet {
            UserDefaults.standard.set(isLoggingPaused, forKey: Key.isLoggingPaused)
            onSettingChange?("isLoggingPaused")
        }
    }

    public var logEnabledCategories: [String] = LogCategory.allCases.map(\.rawValue) {
        didSet {
            Self.encode(logEnabledCategories, forKey: Key.logEnabledCategories)
            onSettingChange?("logEnabledCategories")
        }
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
