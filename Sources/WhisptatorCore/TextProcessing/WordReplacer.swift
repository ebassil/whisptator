import Foundation

public final class WordReplacer: @unchecked Sendable {
    public init() {}

    public func replaceWords(in text: String, replacements: [WordReplacement]) -> String {
        let enabledReplacements = replacements.filter(\.isEnabled)
        guard !enabledReplacements.isEmpty else { return text }

        var result = text

        for rule in enabledReplacements {
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: rule.trigger))\\b"
            result = result.replacingOccurrences(of: pattern, with: rule.replacement, options: .regularExpression)
        }

        return result
    }
}
