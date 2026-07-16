import SwiftUI
import AppKit

struct AboutMenuView: View {
    var body: some View {
        Divider()
        Button("About") { showAboutWindow() }
    }
}

@MainActor
private func showAboutWindow() {
    let aboutWindow = AboutWindowController.shared.window
    aboutWindow?.center()
    aboutWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

private class AboutWindowController: NSWindowController {
    static let shared = AboutWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Whisptator"
        let hostingView = NSHostingView(rootView: AboutView())
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
