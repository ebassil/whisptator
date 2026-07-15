import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
import Carbon

public struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: ShortcutKeyCode
    var placeholder: String = "Record Shortcut"

    public init(shortcut: Binding<ShortcutKeyCode>, placeholder: String = "Record Shortcut") {
        self._shortcut = shortcut
        self.placeholder = placeholder
    }

    public func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.shortcut = shortcut
        view.placeholder = placeholder
        view.onShortcutChanged = { newShortcut in
            shortcut = newShortcut
        }
        return view
    }

    public func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.shortcut = shortcut
    }
}

public final class ShortcutRecorderNSView: NSView {
    var shortcut: ShortcutKeyCode = .init() {
        didSet { updateTitle() }
    }
    var placeholder: String = "Record Shortcut"
    var onShortcutChanged: ((ShortcutKeyCode) -> Void)?

    private let button = NSButton()
    private var isRecording = false
    private var eventMonitor: Any?

    private var pressedModifierKeyCodes = Set<UInt16>()
    private var capturedModifierKeyCodes = Set<UInt16>()
    private var hasPressedModifiersInSession = false

    private static let modifierKeyCodes: Set<UInt16> = [0x36, 0x37, 0x38, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    private func setupButton() {
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(buttonClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        updateTitle()
    }

    @objc private func buttonClicked() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        pressedModifierKeyCodes = []
        capturedModifierKeyCodes = []
        hasPressedModifiersInSession = false
        button.title = "Press keys..."
        button.bezelColor = .systemBlue

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        button.bezelColor = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        pressedModifierKeyCodes = []
        capturedModifierKeyCodes = []
        hasPressedModifiersInSession = false
        updateTitle()
    }

    private func handleKeyEvent(_ event: NSEvent) {
        if event.type == .flagsChanged {
            handleFlagsChanged(event)
        } else if event.type == .keyDown {
            handleKeyDown(event)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let keyCode = event.keyCode
        guard Self.modifierKeyCodes.contains(keyCode) else { return }

        if pressedModifierKeyCodes.contains(keyCode) {
            pressedModifierKeyCodes.remove(keyCode)
            if pressedModifierKeyCodes.isEmpty && hasPressedModifiersInSession {
                finishWithModifierCombo()
            }
        } else {
            pressedModifierKeyCodes.insert(keyCode)
            capturedModifierKeyCodes = pressedModifierKeyCodes
            hasPressedModifiersInSession = true
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        var modifierFlags: UInt32 = 0
        if flags.contains(.shift) { modifierFlags |= UInt32(NSEvent.ModifierFlags.shift.rawValue) }
        if flags.contains(.control) { modifierFlags |= UInt32(NSEvent.ModifierFlags.control.rawValue) }
        if flags.contains(.option) { modifierFlags |= UInt32(NSEvent.ModifierFlags.option.rawValue) }
        if flags.contains(.command) { modifierFlags |= UInt32(NSEvent.ModifierFlags.command.rawValue) }

        let newShortcut = ShortcutKeyCode(keyCode: keyCode, modifierFlags: modifierFlags)
        shortcut = newShortcut
        onShortcutChanged?(newShortcut)
        stopRecording()
    }

    private func finishWithModifierCombo() {
        let codes = capturedModifierKeyCodes.map { UInt32($0) }.sorted()
        let newShortcut = ShortcutKeyCode(modifierKeyCodes: codes)
        shortcut = newShortcut
        onShortcutChanged?(newShortcut)
        stopRecording()
    }

    private func updateTitle() {
        if shortcut.isEmpty {
            button.title = placeholder
        } else {
            button.title = formatShortcut(shortcut)
        }
    }

    private func formatShortcut(_ shortcut: ShortcutKeyCode) -> String {
        if shortcut.isModifierOnly {
            return shortcut.modifierKeyCodes
                .map { modifierKeyDisplayName(for: UInt16($0)) }
                .joined(separator: "+")
        }

        var parts: [String] = []
        let flags = shortcut.modifierFlags

        if flags & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 { parts.append("⌘") }
        if flags & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 { parts.append("⌥") }
        if flags & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 { parts.append("⌃") }
        if flags & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 { parts.append("⇧") }

        if let key = keyString(for: shortcut.keyCode) {
            parts.append(key)
        }

        return parts.joined()
    }

    private func modifierKeyDisplayName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 0x36: return "R-⌘"
        case 0x37: return "⌘"
        case 0x38: return "⇧"
        case 0x3A: return "⌥"
        case 0x3B: return "⌃"
        case 0x3C: return "R-⇧"
        case 0x3D: return "R-⌥"
        case 0x3E: return "R-⌃"
        default: return "Key\(keyCode)"
        }
    }

    private func keyString(for keyCode: UInt32) -> String? {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutDataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let layoutData = unsafeBitCast(layoutDataRef, to: CFData.self) as Data

        return layoutData.withUnsafeBytes { ptr -> String? in
            guard let basePtr = ptr.baseAddress else { return nil }
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length: Int = 0

            let status = UCKeyTranslate(
                basePtr.assumingMemoryBound(to: UCKeyboardLayout.self),
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )

            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: length).uppercased()
        }
    }
}
