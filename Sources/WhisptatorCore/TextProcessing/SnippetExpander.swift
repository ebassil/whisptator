import Foundation

public final class SnippetExpander: @unchecked Sendable {
    public init() {}

    public func expandSnippets(in text: String, snippets: [Snippet]) -> String {
        let enabledSnippets = snippets.filter(\.isEnabled)
        guard !enabledSnippets.isEmpty else { return text }

        let sorted = enabledSnippets.sorted { (a: Snippet, b: Snippet) in a.trigger.count > b.trigger.count }

        var result = text
        for snippet in sorted {
            let pattern = "(?i)\(NSRegularExpression.escapedPattern(for: snippet.trigger))"
            result = result.replacingOccurrences(of: pattern, with: snippet.expansion, options: .regularExpression)
        }

        return result
    }
}
