import AppKit
import Combine
import SwiftUI

// MARK: - Model

@MainActor
public final class TranscriptPanelModel: ObservableObject {
    @Published var lines: [String] = []
    @Published var unseenCount = 0
    @Published var isPinned = true
    @Published var scrollTrigger = 0
    @Published var elapsedSeconds: Double = 0
    @Published var micMuted = false
    @Published var isRecording = false
    @Published var isFinalizing = false
    @Published var statusMessage: String?

    let autoScroll = AutoScrollController()
    var onToggleMute: (() -> Void)?
    var onStop: (() -> Void)?

    public init() {}

    func apply(_ change: TranscriptFileWatcher.Change) {
        switch change {
        case .reloaded(let newLines):
            lines = newLines
            autoScroll.reset(pinned: true)
            publishAutoScrollState()
            requestScroll()
        case .appended(let newLines):
            lines.append(contentsOf: newLines)
            let shouldScroll = autoScroll.contentDidAppend(distanceFromBottom: currentGap)
            publishAutoScrollState()
            if shouldScroll {
                requestScroll()
            }
        }
    }

    /// The view feeds every observed scroll position (gap above the bottom).
    func scrollEvent(distanceFromBottom: Double) {
        currentGap = distanceFromBottom
        let shouldJump = autoScroll.userDidScroll(distanceFromBottom: distanceFromBottom)
        publishAutoScrollState()
        if shouldJump {
            requestScroll()
        }
    }

    func jumpToLive() {
        if autoScroll.jumpToLive() {
            publishAutoScrollState()
            requestScroll()
        }
    }

    private func requestScroll() {
        scrollTrigger += 1
    }

    var currentGap: Double = 0

    private func publishAutoScrollState() {
        isPinned = autoScroll.isPinned
        unseenCount = autoScroll.unseenCount
    }

    var elapsedText: String {
        let total = Int(elapsedSeconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - View

struct LiveTranscriptView: View {
    @ObservedObject var model: TranscriptPanelModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(model.lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(8)
                }
                .onScrollGeometryChange(for: ScrollGeometry.self) { geometry in
                    geometry
                } action: { _, geometry in
                    let gap = geometry.contentSize.height - (geometry.contentOffset.y + geometry.containerSize.height)
                    model.scrollEvent(distanceFromBottom: max(0, gap))
                }
                .overlay(alignment: .top) {
                    if model.unseenCount > 0 {
                        Button {
                            model.jumpToLive()
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(model.unseenCount) new")
                                Image(systemName: "arrow.down")
                                Text("Jump to live")
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.regularMaterial, in: Capsule())
                            .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                        .transition(.opacity)
                    }
                }
                .onChange(of: model.lines.count) { _, _ in
                    if model.isPinned, let last = model.lines.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
                .onChange(of: model.scrollTrigger) { _, _ in
                    if let last = model.lines.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 10) {
                Label(model.elapsedText, systemImage: "stopwatch")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                Button {
                    model.onToggleMute?()
                } label: {
                    Image(systemName: model.micMuted ? "mic.slash.fill" : "mic.fill")
                }
                .help(model.micMuted ? "Unmute microphone" : "Mute microphone")
                .disabled(!model.isRecording)

                Button(role: .destructive) {
                    model.onStop?()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Stop meeting")
                .disabled(!model.isRecording && !model.isFinalizing)

                Spacer()

                if let status = model.statusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if model.isRecording {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 7, height: 7)
                        Text("LIVE").font(.caption2.bold())
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
        .frame(minWidth: 320, minHeight: 220)
    }
}

// MARK: - Panel window

final class LiveTranscriptPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Controller

@MainActor
public final class LiveTranscriptPanelController: NSObject, NSWindowDelegate {
    private let settings: AppSettings
    private let model = TranscriptPanelModel()
    private var panel: NSPanel?
    private var watcher: TranscriptFileWatcher?
    private var statusTimer: Timer?
    private weak var recorder: MeetingRecorder?
    private var lastSession: MeetingSessionInfo?

    public init(settings: AppSettings) {
        self.settings = settings
        super.init()
        model.onToggleMute = { [weak self] in
            self?.recorder?.toggleMicMute()
        }
        model.onStop = { [weak self] in
            guard let recorder = self?.recorder, recorder.state == .recording else { return }
            Task { await recorder.stopRecording() }
        }
    }

    public func attach(recorder: MeetingRecorder) {
        self.recorder = recorder
    }

    /// Called when a session starts. Honors the auto-show setting; remembers the
    /// session so the menu can open the panel later.
    public func sessionDidStart(_ info: MeetingSessionInfo) {
        lastSession = info
        if settings.panelAutoShow {
            present(info, focus: false)
        }
    }

    public func presentCurrentSession() {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }
        if let info = recorder?.activeSession ?? lastSession {
            present(info, focus: true)
        } else {
            presentEmpty(focus: true)
        }
    }

    private func present(_ info: MeetingSessionInfo, focus: Bool) {
        lastSession = info
        if panel == nil {
            model.lines = []
            model.statusMessage = nil
        }
        openOrUpdatePanel(info: info, focus: focus)
    }

    private func presentEmpty(focus: Bool) {
        openOrUpdatePanel(info: nil, focus: focus)
    }

    private func openOrUpdatePanel(info: MeetingSessionInfo?, focus: Bool) {
        if let panel {
            if let info {
                panel.title = info.transcriptURL.deletingPathExtension().lastPathComponent
                reattachWatcher(to: info)
            }
            if focus { panel.makeKeyAndOrderFront(nil) } else { panel.orderFrontRegardless() }
            return
        }

        let frame = restoredFrame()
        let panel = LiveTranscriptPanelWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = info?.transcriptURL.deletingPathExtension().lastPathComponent ?? "Live Transcript"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: LiveTranscriptView(model: model))

        if focus {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
        self.panel = panel

        if let info {
            reattachWatcher(to: info)
        }
        startTimeTicking()
    }

    private func reattachWatcher(to info: MeetingSessionInfo) {
        watcher?.stop()
        model.lines = []
        model.elapsedSeconds = 0
        model.statusMessage = nil
        model.autoScroll.reset(pinned: true)
        model.unseenCount = 0
        model.isPinned = true
        let watcher = TranscriptFileWatcher(url: info.transcriptURL)
        watcher.onChange = { [weak self] change in
            Task { @MainActor in
                self?.model.apply(change)
            }
        }
        watcher.start()
        self.watcher = watcher
    }

    private func startTimeTicking() {
        guard statusTimer == nil else { return }
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshState()
            }
        }
        refreshState()
    }

    func close() {
        saveFrame()
        watcher?.stop()
        watcher = nil
        statusTimer?.invalidate()
        statusTimer = nil
        panel?.orderOut(nil)
        panel = nil
    }

    public func shutdown() {
        close()
    }

    private func refreshState() {
        guard let recorder else {
            model.isRecording = false
            return
        }
        switch recorder.state {
        case .recording:
            model.isRecording = true
            model.isFinalizing = false
            model.statusMessage = nil
            model.elapsedSeconds = Double(recorder.currentElapsedFrames) / StereoAligner.sampleRate
            model.micMuted = recorder.micMuted
        case .finalizing:
            model.isRecording = false
            model.isFinalizing = true
            model.statusMessage = "Finalizing — identifying speakers…"
            model.micMuted = recorder.micMuted
        case .idle:
            model.isRecording = false
            model.isFinalizing = false
            model.micMuted = false
        case .error(let message):
            model.isRecording = false
            model.isFinalizing = false
            model.statusMessage = message
        }
    }

    // MARK: Frame persistence

    private func restoredFrame() -> NSRect {
        let saved = settings.livePanelFrame
        if !saved.isEmpty, let rect = Self.parseRect(saved) {
            // keep on-screen
            if NSScreen.screens.contains(where: { $0.frame.intersects(rect) }) {
                return rect
            }
        }
        let size = NSSize(width: 420, height: 320)
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            return NSRect(
                x: visible.maxX - size.width - 24,
                y: visible.maxY - size.height - 60,
                width: size.width,
                height: size.height
            )
        }
        return NSRect(origin: .zero, size: size)
    }

    private func saveFrame() {
        guard let panel else { return }
        settings.livePanelFrame = Self.formatRect(panel.frame)
    }

    public func windowWillClose(_ notification: Notification) {
        saveFrame()
        watcher?.stop()
        watcher = nil
        statusTimer?.invalidate()
        statusTimer = nil
        panel = nil
    }

    public func windowDidMove(_ notification: Notification) { saveFrame() }
    public func windowDidResize(_ notification: Notification) { saveFrame() }

    nonisolated static func formatRect(_ rect: NSRect) -> String {
        "\(rect.origin.x)|\(rect.origin.y)|\(rect.size.width)|\(rect.size.height)"
    }

    nonisolated static func parseRect(_ string: String) -> NSRect? {
        let parts = string.split(separator: "|").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return NSRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }
}
