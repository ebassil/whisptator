import Foundation

public final class TextCleanupPipeline: @unchecked Sendable {
    private let fillerRemover = FillerRemover()
    private let wordReplacer = WordReplacer()
    private let snippetExpander = SnippetExpander()
    private let whitespaceCleaner = WhitespaceCleaner()

    public init() {}

    public func process(
        _ text: String,
        mode: CleanupMode,
        fillerWords: [FillerWord],
        wordReplacements: [WordReplacement],
        snippets: [Snippet]
    ) -> String {
        guard mode == .clean else { return text }

        var result = text

        result = fillerRemover.removeFillers(from: result, fillerWords: fillerWords)
        result = wordReplacer.replaceWords(in: result, replacements: wordReplacements)
        result = snippetExpander.expandSnippets(in: result, snippets: snippets)
        result = whitespaceCleaner.clean(result)

        return result
    }
}
