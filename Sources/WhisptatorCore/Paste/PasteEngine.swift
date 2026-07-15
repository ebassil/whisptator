import Foundation

public final class PasteEngine: @unchecked Sendable {
    private let clipboardPaster = ClipboardPaster()
    private let typingPaster = TypingPaster()

    public init() {}

    public func paste(_ text: String, mode: PasteMode) {
        switch mode {
        case .clipboard:
            clipboardPaster.paste(text)
        case .typing:
            typingPaster.type(text)
        }
    }
}
