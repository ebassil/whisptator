import Foundation

public final class WhitespaceCleaner: @unchecked Sendable {
    public init() {}

    public func clean(_ text: String) -> String {
        var result = text

        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        result = fixPunctuationSpacing(result)

        result = capitalizeFirstLetter(result)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fixPunctuationSpacing(_ text: String) -> String {
        var result = text

        let punctuationPattern = "\\s+([.,!?;:])"
        result = result.replacingOccurrences(of: punctuationPattern, with: "$1", options: .regularExpression)

        let afterPunctuationPattern = "([.,!?;:])([^\\s\\n])"
        result = result.replacingOccurrences(of: afterPunctuationPattern, with: "$1 $2", options: .regularExpression)

        return result
    }

    private func capitalizeFirstLetter(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
