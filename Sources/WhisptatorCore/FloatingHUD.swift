import SwiftUI
import AppKit

final class FloatingHUDWindow: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .hudWindow, .fullSizeContentView], backing: .buffered, defer: flag)
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
    }
}

struct FloatingHUDView: View {
    let isRecording: Bool
    let elapsedTime: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)
                .overlay(
                    isRecording ?
                    Circle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 16, height: 16)
                    : nil
                )

            Text(isRecording ? "Recording" : "Idle")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white)

            Text(formatTime(elapsedTime))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

@MainActor
final class FloatingHUDController {
    private var window: FloatingHUDWindow?
    private var timer: Timer?
    private var startTime: Date?
    private var dismissWorkItem: DispatchWorkItem?

    func show() {
        dismissWorkItem?.cancel()

        if window == nil {
            createWindow()
        }

        startTime = Date()
        updateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }

        window?.orderFront(nil)
    }

    func hide() {
        timer?.invalidate()
        timer = nil
        startTime = nil

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.window?.orderOut(nil)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func createWindow() {
        let contentView = NSHostingView(rootView: FloatingHUDView(isRecording: false, elapsedTime: 0))
        let window = FloatingHUDWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 50),
            styleMask: [.nonactivatingPanel, .hudWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = contentView
        window.isReleasedWhenClosed = false

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 110
            let y = screenFrame.maxY - 70
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = window
    }

    private func updateTimer() {
        guard let startTime, let hostingView = window?.contentView as? NSHostingView<FloatingHUDView> else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        hostingView.rootView = FloatingHUDView(isRecording: true, elapsedTime: elapsed)
    }

    func updateRecordingState(_ isRecording: Bool) {
        if isRecording {
            show()
        } else {
            hide()
        }
    }
}
