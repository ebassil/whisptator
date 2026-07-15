import AppKit
import Carbon

private struct SavedPasteboardItem {
    let entries: [(NSPasteboard.PasteboardType, Data)]
}

public final class ClipboardPaster: @unchecked Sendable {
    public init() {}

    public func paste(_ text: String) {
        let pasteboard = NSPasteboard.general

        let savedItems = savePasteboard(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        simulateCmdV()

        Thread.sleep(forTimeInterval: 0.1)

        restorePasteboard(pasteboard, items: savedItems)
    }

    private func savePasteboard(_ pasteboard: NSPasteboard) -> [SavedPasteboardItem] {
        var items: [SavedPasteboardItem] = []

        for item in pasteboard.pasteboardItems ?? [] {
            var typeData: [(NSPasteboard.PasteboardType, Data)] = []
            for type in item.types {
                if let data = item.data(forType: type) {
                    typeData.append((type, data))
                }
            }
            items.append(SavedPasteboardItem(entries: typeData))
        }

        return items
    }

    private func restorePasteboard(_ pasteboard: NSPasteboard, items: [SavedPasteboardItem]) {
        pasteboard.clearContents()
        guard !items.isEmpty else { return }

        var nsItems: [NSPasteboardItem] = []
        for item in items {
            let nsItem = NSPasteboardItem()
            for entry in item.entries {
                nsItem.setData(entry.1, forType: entry.0)
            }
            nsItems.append(nsItem)
        }

        pasteboard.writeObjects(nsItems)
    }

    private func simulateCmdV() {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
