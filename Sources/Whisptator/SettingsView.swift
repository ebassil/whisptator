import SwiftUI
import ServiceManagement
import AVFoundation
import WhisptatorCore

struct SettingsView: View {
    @State private var settings = AppSettings()

    var body: some View {
        TabView {
            GeneralSettingsTab(settings: settings)
                .tabItem { Label("General", systemImage: "gear") }

            DictationSettingsTab(settings: settings)
                .tabItem { Label("Dictation", systemImage: "mic") }

            ModelSettingsTab(settings: settings)
                .tabItem { Label("Model", systemImage: "cpu") }

            CleanupSettingsTab(settings: settings)
                .tabItem { Label("Cleanup", systemImage: "text.badge.checkmark") }

            MeetingSettingsTab(settings: settings)
                .tabItem { Label("Meeting", systemImage: "video") }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    if newValue {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }

            Toggle("Show in Dock", isOn: $settings.showInDock)

            Section("Permissions") {
                PermissionRow(name: "Accessibility", granted: AXIsProcessTrusted())
                PermissionRow(name: "Microphone", granted: checkMicrophonePermission())
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func checkMicrophonePermission() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return true
        default: return false
        }
    }
}

struct PermissionRow: View {
    let name: String
    let granted: Bool

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            if granted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant in Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

struct DictationSettingsTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Shortcuts") {
                HStack {
                    Text("Push-to-talk")
                    Spacer()
                    ShortcutRecorderView(shortcut: $settings.pushToTalkShortcut)
                }
                HStack {
                    Text("Hands-free")
                    Spacer()
                    ShortcutRecorderView(shortcut: $settings.handsFreeShortcut)
                }
            }

            Section("Paste Mode") {
                Picker("Mode", selection: $settings.pasteMode) {
                    Text("Clipboard (Cmd+V)").tag(PasteMode.clipboard)
                    Text("Typing").tag(PasteMode.typing)
                }
                .pickerStyle(.radioGroup)
            }

            Section("Audio") {
                Picker("Language", selection: $settings.language) {
                    Text("Auto-detect").tag("auto")
                    Text("English").tag("en")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Spanish").tag("es")
                    Text("Japanese").tag("ja")
                    Text("Chinese").tag("zh")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ModelSettingsTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Whisper Model") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Whisper Large-v3 Turbo (CoreML)")
                            .font(.headline)
                        Text("aufklarer/Whisper-Large-v3-Turbo-CoreML")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("~1.56 GB")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct CleanupSettingsTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Mode") {
                Picker("Cleanup Mode", selection: $settings.cleanupMode) {
                    Text("Raw").tag(CleanupMode.raw)
                    Text("Clean").tag(CleanupMode.clean)
                }
                .pickerStyle(.radioGroup)
            }

            if settings.cleanupMode == .clean {
                Section("Filler Words") {
                    ForEach($settings.fillerWords) { $filler in
                        Toggle(filler.word, isOn: $filler.isEnabled)
                    }
                }

                Section("Word Replacements") {
                    ForEach(settings.wordReplacements) { rule in
                        HStack {
                            Text(rule.trigger)
                            Image(systemName: "arrow.right")
                            Text(rule.replacement)
                        }
                    }
                }

                Section("Snippets") {
                    ForEach(settings.snippets) { snippet in
                        HStack {
                            Text(snippet.trigger)
                            Image(systemName: "arrow.right")
                            Text(snippet.expansion)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct MeetingSettingsTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Audio Source") {
                Picker("Source", selection: $settings.meetingAudioSource) {
                    Text("System + Microphone").tag(AudioSourceMode.systemAndMicrophone)
                    Text("Microphone only").tag(AudioSourceMode.microphoneOnly)
                    Text("System only").tag(AudioSourceMode.systemOnly)
                }
                .pickerStyle(.radioGroup)
            }

            Section("Retention") {
                Picker("Audio Retention", selection: $settings.meetingRetention) {
                    Text("Keep audio").tag(AudioRetentionMode.keep)
                    Text("Delete after transcription").tag(AudioRetentionMode.deleteAfterTranscription)
                    Text("Auto-delete after N days").tag(AudioRetentionMode.autoDeleteAfterDays)
                }
                .pickerStyle(.radioGroup)

                if settings.meetingRetention == .autoDeleteAfterDays {
                    Stepper("Days: \(settings.meetingRetentionDays)", value: $settings.meetingRetentionDays, in: 1...365)
                }
            }

            Section("Shortcut") {
                HStack {
                    Text("Start/Stop Recording")
                    Spacer()
                    ShortcutRecorderView(shortcut: $settings.meetingShortcut)
                }
            }

            Section("Save Location") {
                HStack {
                    Text(settings.meetingSaveLocation)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Change") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.meetingSaveLocation = url.path
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
