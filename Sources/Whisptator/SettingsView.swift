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

            LogsSettingsTab(settings: coordinator.settings)
                .tabItem { Label("Logs", systemImage: "list.bullet.rectangle") }
        }
        .frame(minWidth: 480, minHeight: 380)
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

                Toggle("Save audio files", isOn: $settings.saveAudioFiles)

                if settings.saveAudioFiles {
                    HStack {
                        Text(settings.audioSaveLocation)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Change") {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            panel.allowsMultipleSelection = false
                            if panel.runModal() == .OK, let url = panel.url {
                                settings.audioSaveLocation = url.path
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: settings.pushToTalkShortcut) { _, _ in onShortcutChange?() }
        .onChange(of: settings.handsFreeShortcut) { _, _ in onShortcutChange?() }
    }
}

struct LogsSettingsTab: View {
    @State private var logger = AppLogger.shared
    @State private var showConfigSheet = false
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List(logger.entries.reversed()) { entry in
                    HStack(spacing: 8) {
                        Text(entry.timestamp, style: .time)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        CategoryBadge(category: entry.category)
                        Text(entry.message)
                            .font(.caption)
                    }
                    .id(entry.id)
                }
                .onChange(of: logger.entries.count) { _, _ in
                    if let last = logger.entries.last {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }

            Divider()

            HStack(spacing: 4) {
                Button {
                    let paused = !logger.isPaused
                    logger.setPaused(paused)
                    settings.isLoggingPaused = paused
                } label: {
                    Label(
                        logger.isPaused ? "Start" : "Stop",
                        systemImage: logger.isPaused ? "play.fill" : "pause.fill"
                    )
                }
                .help(logger.isPaused ? "Resume logging" : "Pause logging")

                Button {
                    showConfigSheet = true
                } label: {
                    Label("Config Logs", systemImage: "gearshape")
                }
                .help("Configure log categories")

                Button {
                    saveLogsToCSV()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .help("Save logs to CSV")

                Spacer()

                Button("Clear") {
                    logger.clear()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .labelStyle(.iconOnly)
        }
        .sheet(isPresented: $showConfigSheet) {
            LogConfigSheet(logger: logger, settings: settings)
        }
    }

    private func saveLogsToCSV() {
        let panel = NSSavePanel()
        panel.title = "Save Logs"

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        panel.nameFieldStringValue = "whisptator-logs-\(df.string(from: Date())).csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        var csv = "Timestamp,Category,Message\n"
        let dateFormatter = ISO8601DateFormatter()
        for entry in logger.entries {
            let ts = dateFormatter.string(from: entry.timestamp)
            let msg = entry.message.contains(",") || entry.message.contains("\n") || entry.message.contains("\"")
                ? "\"\(entry.message.replacingOccurrences(of: "\"", with: "\"\""))\""
                : entry.message
            csv += "\(ts),\(entry.category.rawValue),\(msg)\n"
        }

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save CSV logs: \(error)")
        }
    }
}

struct LogConfigSheet: View {
    @State var logger: AppLogger
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Enable All") {
                    logger.enableAllCategories()
                    settings.logEnabledCategories = LogCategory.allCases.map(\.rawValue)
                }
                Button("Disable All") {
                    logger.disableAllCategories()
                    settings.logEnabledCategories = []
                }
            }
            .padding()

            Divider()

            List(LogCategory.allCases, id: \.self) { category in
                Toggle(isOn: Binding(
                    get: { logger.enabledCategories.contains(category) },
                    set: { enabled in
                        logger.setCategoryEnabled(category, enabled: enabled)
                        var cats = Set(settings.logEnabledCategories.compactMap(LogCategory.init(rawValue:)))
                        if enabled {
                            cats.insert(category)
                        } else {
                            cats.remove(category)
                        }
                        settings.logEnabledCategories = cats.map(\.rawValue)
                    }
                )) {
                    HStack {
                        CategoryBadge(category: category)
                        Text(category.rawValue.capitalized)
                    }
                }
            }
        }
        .frame(width: 300, height: 350)
        .padding()
    }
}

struct CategoryBadge: View {
    let category: LogCategory

    var color: Color {
        switch category {
        case .shortcut: return .orange
        case .dictation: return .blue
        case .meeting: return .purple
        case .model: return .green
        case .transcription: return .teal
        case .audio: return .pink
        case .settings: return .gray
        case .overlay: return .yellow
        case .system: return .secondary
        }
    }

    var body: some View {
        Text(category.rawValue)
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }
}

struct ModelSettingsTab: View {
    @Bindable var settings: AppSettings
    var modelManager: ModelManager
    @State private var hubCacheStatuses: [String: Bool] = [:]

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Available ASR Models") {
                    ForEach(modelManager.availableModels) { model in
                        ModelRow(
                            model: model,
                            isSelected: modelManager.isSelected(model.id),
                            isCached: hubCacheStatuses[model.id] ?? false,
                            downloadStatus: modelManager.isSelected(model.id) ? modelManager.downloadStatus : .notStarted,
                            selectAction: {
                                modelManager.selectModel(model.id)
                            },
                            downloadAction: {
                                Task { await modelManager.loadModel() }
                            },
                            retryAction: {
                                Task { await modelManager.loadModel() }
                            }
                        )
                    }
                }
            }
            .listStyle(.inset)
        }
        .onAppear {
            refreshHubCacheStatus()
        }
    }

    private func refreshHubCacheStatus() {
        var statuses: [String: Bool] = [:]
        for model in modelManager.availableModels {
            statuses[model.id] = modelManager.hubCacheStatus(for: model.id)
        }
        hubCacheStatuses = statuses
    }
}

struct ModelRow: View {
    let model: SupportedModel
    let isSelected: Bool
    let isCached: Bool
    let downloadStatus: ModelDownloadStatus
    let selectAction: () -> Void
    let downloadAction: () -> Void
    let retryAction: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(model.sizeLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if isCached {
                        Label("Cached", systemImage: "externaldrive.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            if isSelected {
                switch downloadStatus {
                case .notStarted:
                    Button("Download") {
                        downloadAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                case .downloading(let progress, let message):
                    VStack(alignment: .trailing, spacing: 2) {
                        ProgressView(value: progress)
                            .frame(width: 100)
                        Text(message)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                case .loaded:
                    Label("Loaded", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed(let error):
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("Failed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error.localizedDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Button("Retry", action: retryAction)
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                Button("Select") {
                    selectAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
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
