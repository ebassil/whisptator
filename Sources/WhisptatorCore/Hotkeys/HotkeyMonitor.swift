import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

public protocol HotkeyMonitorDelegate: AnyObject {
    func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectPushToTalkDown shortcut: ShortcutKeyCode)
    func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectPushToTalkUp shortcut: ShortcutKeyCode)
    func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectHandsFreeTap shortcut: ShortcutKeyCode)
    func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectMeetingToggle shortcut: ShortcutKeyCode)
}

public final class HotkeyMonitor: @unchecked Sendable {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapThread: Thread?
    private var reEnableTimer: Timer?
    private var isRunning = false

    private var pushToTalkShortcut: ShortcutKeyCode
    private var handsFreeShortcut: ShortcutKeyCode
    private var meetingShortcut: ShortcutKeyCode

    private var pushToTalkDown = false
    private var handsFreeRecording = false
    private var meetingRecording = false

    private var tapThreadRunLoop: CFRunLoop?

    private var pressedModifierKeyCodes = Set<UInt32>()
    private var previousModifierKeyCodes = Set<UInt32>()
    private var pushToTalkModifierHeld = false

    public weak var delegate: HotkeyMonitorDelegate?

    private static let trackedModifierKeyCodes: Set<UInt32> = [0x36, 0x37, 0x38, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E]

    public init(settings: AppSettings) {
        self.pushToTalkShortcut = settings.pushToTalkShortcut
        self.handsFreeShortcut = settings.handsFreeShortcut
        self.meetingShortcut = settings.meetingShortcut
    }

    public func updateShortcuts(settings: AppSettings) {
        self.pushToTalkShortcut = settings.pushToTalkShortcut
        self.handsFreeShortcut = settings.handsFreeShortcut
        self.meetingShortcut = settings.meetingShortcut
    }

    public func start() throws {
        guard !isRunning else { return }
        guard AXIsProcessTrusted() else {
            AppLogger.shared.log(category: .shortcut, message: "Hotkey start failed: accessibility not granted")
            throw HotkeyError.accessibilityNotGranted
        }
        AppLogger.shared.log(category: .shortcut, message: "Hotkey monitor started")

        tapThread = Thread { [weak self] in
            self?.runEventTap()
        }
        tapThread?.name = "com.whisptator.hotkey"
        tapThread?.start()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        AppLogger.shared.log(category: .shortcut, message: "Hotkey monitor stopped")
        isRunning = false

        if let source = runLoopSource, let rl = tapThreadRunLoop {
            CFRunLoopRemoveSource(rl, source, .defaultMode)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        reEnableTimer?.invalidate()
        reEnableTimer = nil
        tapThread?.cancel()
        tapThread = nil
        eventTap = nil
        runLoopSource = nil
        tapThreadRunLoop = nil
        pressedModifierKeyCodes = []
        previousModifierKeyCodes = []
        pushToTalkModifierHeld = false
    }

    private func runEventTap() {
        tapThreadRunLoop = CFRunLoopGetCurrent()

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        CGEvent.tapEnable(tap: tap, enable: true)

        reEnableTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self, let tap = self.eventTap else { return }
            CGEvent.tapEnable(tap: tap, enable: true)
            AppLogger.shared.log(category: .shortcut, message: "Event tap re-enabled (timeout recovery)")
        }

        CFRunLoopRunInMode(.defaultMode, .infinity, false)
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            handleFlagsChanged(event: event)
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let shortcut = ShortcutKeyCode(
            keyCode: UInt32(keyCode),
            modifierFlags: extractModifierFlags(flags)
        )

        if type == .keyDown {
            handleKeyDown(shortcut: shortcut)
        } else {
            handleKeyUp(shortcut: shortcut)
        }

        if isShortcutMatched(shortcut) {
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleFlagsChanged(event: CGEvent) {
        let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
        guard Self.trackedModifierKeyCodes.contains(keyCode) else { return }

        if pressedModifierKeyCodes.contains(keyCode) {
            pressedModifierKeyCodes.remove(keyCode)
        } else {
            pressedModifierKeyCodes.insert(keyCode)
        }

        checkModifierOnlyShortcuts()
        previousModifierKeyCodes = pressedModifierKeyCodes
    }

    private func checkModifierOnlyShortcuts() {
        if pushToTalkShortcut.isModifierOnly {
            checkPushToTalkModifier()
        }
        if handsFreeShortcut.isModifierOnly {
            checkHandsFreeModifier()
        }
        if meetingShortcut.isModifierOnly {
            checkMeetingModifier()
        }
    }

    private func checkPushToTalkModifier() {
        let needed = Set(pushToTalkShortcut.modifierKeyCodes)
        let isHeld = !needed.isEmpty && pressedModifierKeyCodes == needed

        if isHeld && !pushToTalkModifierHeld {
            pushToTalkModifierHeld = true
            AppLogger.shared.log(category: .shortcut, message: "Modifier-only shortcut matched: push-to-talk")
            delegate?.hotkeyMonitor(self, didDetectPushToTalkDown: pushToTalkShortcut)
        } else if !isHeld && pushToTalkModifierHeld {
            pushToTalkModifierHeld = false
            delegate?.hotkeyMonitor(self, didDetectPushToTalkUp: pushToTalkShortcut)
        }
    }

    private func checkHandsFreeModifier() {
        let needed = Set(handsFreeShortcut.modifierKeyCodes)
        let isHeld = !needed.isEmpty && pressedModifierKeyCodes == needed
        let wasHeld = !needed.isEmpty && previousModifierKeyCodes == needed

        if isHeld && !wasHeld {
            AppLogger.shared.log(category: .shortcut, message: "Modifier-only shortcut matched: hands-free")
            delegate?.hotkeyMonitor(self, didDetectHandsFreeTap: handsFreeShortcut)
        }
    }

    private func checkMeetingModifier() {
        let needed = Set(meetingShortcut.modifierKeyCodes)
        let isHeld = !needed.isEmpty && pressedModifierKeyCodes == needed
        let wasHeld = !needed.isEmpty && previousModifierKeyCodes == needed

        if isHeld && !wasHeld {
            AppLogger.shared.log(category: .shortcut, message: "Modifier-only shortcut matched: meeting")
            delegate?.hotkeyMonitor(self, didDetectMeetingToggle: meetingShortcut)
        }
    }

    private func handleKeyDown(shortcut: ShortcutKeyCode) {
        if shortcut == pushToTalkShortcut && !pushToTalkDown {
            pushToTalkDown = true
            AppLogger.shared.log(category: .shortcut, message: "Push-to-talk down: keyCode=\(shortcut.keyCode)")
            delegate?.hotkeyMonitor(self, didDetectPushToTalkDown: shortcut)
        } else if shortcut == handsFreeShortcut {
            handsFreeRecording.toggle()
            AppLogger.shared.log(category: .shortcut, message: "Hands-free tap detected")
            delegate?.hotkeyMonitor(self, didDetectHandsFreeTap: shortcut)
        } else if shortcut == meetingShortcut {
            meetingRecording.toggle()
            AppLogger.shared.log(category: .shortcut, message: "Meeting toggle detected")
            delegate?.hotkeyMonitor(self, didDetectMeetingToggle: shortcut)
        }
    }

    private func handleKeyUp(shortcut: ShortcutKeyCode) {
        if shortcut == pushToTalkShortcut && pushToTalkDown {
            pushToTalkDown = false
            AppLogger.shared.log(category: .shortcut, message: "Push-to-talk up")
            delegate?.hotkeyMonitor(self, didDetectPushToTalkUp: shortcut)
        }
    }

    private func isShortcutMatched(_ shortcut: ShortcutKeyCode) -> Bool {
        guard !shortcut.isModifierOnly else { return false }
        return shortcut == pushToTalkShortcut || shortcut == handsFreeShortcut || shortcut == meetingShortcut
    }

    private func extractModifierFlags(_ flags: CGEventFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.maskShift) { result |= UInt32(NSEvent.ModifierFlags.shift.rawValue) }
        if flags.contains(.maskControl) { result |= UInt32(NSEvent.ModifierFlags.control.rawValue) }
        if flags.contains(.maskAlternate) { result |= UInt32(NSEvent.ModifierFlags.option.rawValue) }
        if flags.contains(.maskCommand) { result |= UInt32(NSEvent.ModifierFlags.command.rawValue) }
        return result
    }
}

public enum HotkeyError: Error, LocalizedError {
    case accessibilityNotGranted

    public var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Accessibility permission is required for global hotkeys. Grant it in System Settings > Privacy & Security > Accessibility."
        }
    }
}
