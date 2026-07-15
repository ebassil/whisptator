import SwiftUI
import ServiceManagement
import WhisptatorCore

struct SettingsView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        TabView {
            GeneralSettingsTab(settings: coordinator.settings)
                .tabItem { Label("General", systemImage: "gear") }

            DictationSettingsTab(settings: coordinator.settings, onShortcutChange: { coordinator.dictationOrchestrator.updateShortcuts() })
                .tabItem { Label("Dictation", systemImage: "mic") }

            ModelSettingsTab(settings: coordinator.settings, modelManager: coordinator.modelManager)
                .tabItem { Label("Model", systemImage: "cpu") }

            CleanupSettingsTab(settings: coordinator.settings)
                .tabItem { Label("Cleanup", systemImage: "text.badge.checkmark") }

            MeetingSettingsTab(settings: coordinator.settings, onShortcutChange: { coordinator.dictationOrchestrator.updateShortcuts() })
                .tabItem { Label("Meeting", systemImage: "video") }

            OverlaySettingsTab(settings: coordinator.settings)
                .tabItem { Label("Overlay", systemImage: "circle.hexagongrid") }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsTab: View {
    @Bindable var settings: AppSettings
    @State private var permissionGate = PermissionGate()
    @State private var permissions = PermissionStatus(
        accessibility: false,
        microphone: false,
        screenRecording: false
    )
    @State private var pollingTimer: Timer?

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
                PermissionRow(
                    name: "Accessibility",
                    granted: permissions.accessibility,
                    settingsPane: "Privacy_Accessibility"
                )
                PermissionRow(
                    name: "Microphone",
                    granted: permissions.microphone,
                    onGrant: { Task { await permissionGate.requestMicrophonePermission() } }
                )
                PermissionRow(
                    name: "Screen Recording",
                    granted: permissions.screenRecording,
                    onGrant: { _ = permissionGate.requestScreenRecordingPermission() }
                )
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            permissions = permissionGate.checkPermissions()
            pollingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                Task { @MainActor in
                    permissions = permissionGate.checkPermissions()
                }
            }
        }
        .onDisappear {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            permissions = permissionGate.checkPermissions()
        }
    }
}

struct PermissionRow: View {
    let name: String
    let granted: Bool
    let onGrant: (() -> Void)?
    let settingsPane: String?

    init(name: String, granted: Bool, onGrant: (() -> Void)? = nil, settingsPane: String? = nil) {
        self.name = name
        self.granted = granted
        self.onGrant = onGrant
        self.settingsPane = settingsPane
    }

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            if granted {
                Label("Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if let onGrant {
                Button("Grant") {
                    onGrant()
                }
            } else if let settingsPane {
                Button("Grant in Settings") {
                    let url = URL(
                        string: "x-apple.systempreferences:com.apple.preference.security?\(settingsPane)"
                    )
                    if let url {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

struct DictationSettingsTab: View {
    @Bindable var settings: AppSettings
    var onShortcutChange: (() -> Void)?

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
        .onChange(of: settings.pushToTalkShortcut) { _, _ in onShortcutChange?() }
        .onChange(of: settings.handsFreeShortcut) { _, _ in onShortcutChange?() }
    }
}

struct ModelSettingsTab: View {
    @Bindable var settings: AppSettings
    var modelManager: ModelManager

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
                    switch modelManager.downloadStatus {
                    case .notStarted:
                        Button("Download") {
                            Task { await modelManager.loadModel() }
                        }
                    case .downloading(let progress, let message):
                        VStack(alignment: .trailing) {
                            ProgressView(value: progress)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    case .loaded:
                        Label("Loaded", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failed(let error):
                        VStack(alignment: .trailing) {
                            Label("Failed", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Retry") {
                                Task { await modelManager.loadModel() }
                            }
                        }
                    }
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
    var onShortcutChange: (() -> Void)?

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
        .onChange(of: settings.meetingShortcut) { _, _ in onShortcutChange?() }
    }
}

struct OverlaySettingsTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable overlay", isOn: $settings.overlayEnabled)
            }

            if settings.overlayEnabled {
                Section("Position") {
                    Picker("Overlay position", selection: $settings.overlayPosition) {
                        Text("Center").tag(OverlayPosition.center)
                        Text("Top-Right").tag(OverlayPosition.topRight)
                        Text("Bottom-Center").tag(OverlayPosition.bottomCenter)
                        Text("Follow Cursor").tag(OverlayPosition.followCursor)
                    }
                }

                Section("Dual-Screen") {
                    Picker("Multi-display behavior", selection: $settings.dualScreenMode) {
                        Text("Primary Only").tag(DualScreenMode.primaryOnly)
                        Text("Both Displays").tag(DualScreenMode.bothDisplays)
                        Text("Active App Display").tag(DualScreenMode.activeAppDisplay)
                    }
                }

                Section("Appearance") {
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Text("\(Int(settings.overlayOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.overlayOpacity, in: 0.2...1.0, step: 0.05)

                    HStack {
                        Text("Size")
                        Spacer()
                        Text("\(Int(settings.overlaySize * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.overlaySize, in: 0.5...2.0, step: 0.1)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
