import AppKit

public final class TypingPaster: @unchecked Sendable {
    public init() {}

    public func type(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)

        for scalar in text.unicodeScalars {
            let char = Character(scalar)
            typeCharacter(char, source: source)
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    private func typeCharacter(_ char: Character, source: CGEventSource?) {
        let str = String(char)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else { return }

        var utf16 = Array(str.utf16)
        event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        event.post(tap: .cghidEventTap)

        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        keyUp.post(tap: .cghidEventTap)
    }
}
