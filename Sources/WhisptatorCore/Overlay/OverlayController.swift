import SwiftUI
import AppKit

@MainActor
public final class OverlayController {
    private var windows: [OverlayWindow] = []
    private let settings: AppSettings
    private var audioLevelPoller: Timer?

    public var audioLevel: Float = 0

    public init(settings: AppSettings) {
        self.settings = settings
    }

    public func show(state: OverlayState) {
        guard settings.overlayEnabled else { return }

        dismiss()

        let screens = screensForMode()
        for screen in screens {
            let window = createWindow(for: screen)
            let hostingView = NSHostingView(
                rootView: OverlayContentView(
                    state: state,
                    audioLevel: audioLevel,
                    opacity: settings.overlayOpacity
                )
            )
            window.contentView = hostingView
            positionWindow(window, on: screen)
            window.orderFront(nil)
            windows.append(window)
        }
    }

    public func updateState(_ state: OverlayState) {
        guard settings.overlayEnabled else { return }

        if state == .idle {
            dismiss()
            return
        }

        if windows.isEmpty {
            show(state: state)
        } else {
            for window in windows {
                guard let hostingView = window.contentView as? NSHostingView<OverlayContentView> else { continue }
                hostingView.rootView = OverlayContentView(
                    state: state,
                    audioLevel: audioLevel,
                    opacity: settings.overlayOpacity
                )
            }
        }
    }

    public func updateAudioLevel(_ level: Float) {
        audioLevel = level
        for window in windows {
            guard let hostingView = window.contentView as? NSHostingView<OverlayContentView> else { continue }
            hostingView.rootView = OverlayContentView(
                state: hostingView.rootView.state,
                audioLevel: level,
                opacity: settings.overlayOpacity
            )
        }
    }

    public func dismiss() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }

    public func showCompletionThenDismiss() {
        updateState(.completion)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.dismiss()
        }
    }

    private func screensForMode() -> [NSScreen] {
        switch settings.dualScreenMode {
        case .primaryOnly:
            return [NSScreen.main].compactMap { $0 }
        case .bothDisplays:
            return NSScreen.screens
        case .activeAppDisplay:
            if let screen = activeAppScreen() {
                return [screen]
            }
            return [NSScreen.main].compactMap { $0 }
        }
    }

    private func activeAppScreen() -> NSScreen? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard result == .success, let window = focusedWindow else { return nil }

        var position: CFTypeRef?
        let posResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &position)
        guard posResult == .success, let positionValue = position else { return nil }

        var point = CGPoint.zero
        if AXValueGetValue(positionValue as! AXValue, .cgPoint, &point) {
            return NSScreen.screens.first { screen in
                screen.frame.contains(point)
            }
        }
        return nil
    }

    private func createWindow(for screen: NSScreen) -> OverlayWindow {
        let window = OverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 140),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        return window
    }

    private func positionWindow(_ window: OverlayWindow, on screen: NSScreen) {
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        let scaledSize = NSSize(
            width: windowSize.width * CGFloat(settings.overlaySize),
            height: windowSize.height * CGFloat(settings.overlaySize)
        )
        window.setFrame(NSRect(origin: .zero, size: scaledSize), display: true)

        let point: CGPoint
        switch settings.overlayPosition {
        case .center:
            point = CGPoint(
                x: screenFrame.midX - scaledSize.width / 2,
                y: screenFrame.midY - scaledSize.height / 2
            )
        case .topRight:
            point = CGPoint(
                x: screenFrame.maxX - scaledSize.width - 20,
                y: screenFrame.maxY - scaledSize.height - 60
            )
        case .bottomCenter:
            point = CGPoint(
                x: screenFrame.midX - scaledSize.width / 2,
                y: screenFrame.minY + 80
            )
        case .followCursor:
            let cursor = NSEvent.mouseLocation
            point = CGPoint(
                x: min(max(cursor.x - scaledSize.width / 2, screenFrame.minX), screenFrame.maxX - scaledSize.width),
                y: min(max(cursor.y - scaledSize.height / 2, screenFrame.minY), screenFrame.maxY - scaledSize.height)
            )
        }
        window.setFrameOrigin(point)
    }
}
