import Foundation

public final class FillerRemover: @unchecked Sendable {
    public init() {}

    public func removeFillers(from text: String, fillerWords: [FillerWord]) -> String {
        let enabledFillers = Set(fillerWords.filter(\.isEnabled).map { $0.word.lowercased() })
        guard !enabledFillers.isEmpty else { return text }

        var result = text

        for filler in enabledFillers {
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: filler))\\b"
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        result = removeSentenceStartFillers(from: result, fillers: enabledFillers)

        result = collapseWhitespace(result)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func removeSentenceStartFillers(from text: String, fillers: Set<String>) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
        var result: [String] = []

        for sentence in sentences {
            var trimmed = sentence.trimmingCharacters(in: .whitespaces)
            let words = trimmed.split(separator: " ")

            if let firstWord = words.first?.lowercased(), fillers.contains(firstWord) {
                trimmed = words.dropFirst().joined(separator: " ")
            }

            result.append(trimmed)
        }

        return result.joined(separator: " ")
    }

    private func collapseWhitespace(_ text: String) -> String {
        text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
