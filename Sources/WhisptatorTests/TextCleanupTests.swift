import XCTest
@testable import WhisptatorCore

final class TextCleanupTests: XCTestCase {
    let pipeline = TextCleanupPipeline()

    func testRawModeBypassesCleanup() {
        let result = pipeline.process(
            "um so this is a test",
            mode: .raw,
            fillerWords: [FillerWord(word: "um"), FillerWord(word: "so")],
            wordReplacements: [],
            snippets: []
        )
        XCTAssertEqual(result, "um so this is a test")
    }

    func testFillerRemoval() {
        let remover = FillerRemover()
        let result = remover.removeFillers(
            "um so I think we should go",
            fillerWords: [FillerWord(word: "um"), FillerWord(word: "so")]
        )
        XCTAssertFalse(result.lowercased().contains("um"))
        XCTAssertFalse(result.lowercased().contains("so"))
    }

    func testWordReplacement() {
        let replacer = WordReplacer()
        let result = replacer.replaceWords(
            "aye pee eye is great",
            replacements: [WordReplacement(trigger: "aye pee eye", replacement: "API")]
        )
        XCTAssertEqual(result, "API is great")
    }

    func testWordReplacementCaseInsensitive() {
        let replacer = WordReplacer()
        let result = replacer.replaceWords(
            "Kubernetes is awesome",
            replacements: [WordReplacement(trigger: "kubernetes", replacement: "K8s")]
        )
        XCTAssertEqual(result, "K8s is awesome")
    }

    func testSnippetExpansion() {
        let expander = SnippetExpander()
        let result = expander.expandSnippets(
            "my signature",
            snippets: [Snippet(trigger: "my signature", expansion: "Best regards, Emile")]
        )
        XCTAssertEqual(result, "Best regards, Emile")
    }

    func testSnippetLongestMatch() {
        let expander = SnippetExpander()
        let result = expander.expandSnippets(
            "my signature",
            snippets: [
                Snippet(trigger: "my sig", expansion: "Short"),
                Snippet(trigger: "my signature", expansion: "Best regards, Emile"),
            ]
        )
        XCTAssertEqual(result, "Best regards, Emile")
    }

    func testWhitespaceCleanup() {
        let cleaner = WhitespaceCleaner()
        let result = cleaner.clean("  hello   world  ")
        XCTAssertEqual(result, "Hello world")
    }

    func testPunctuationSpacing() {
        let cleaner = WhitespaceCleaner()
        let result = cleaner.clean("hello , world !")
        XCTAssertEqual(result, "Hello, world!")
    }

    func testFullPipeline() {
        let result = pipeline.process(
            "um so aye pee eye my signature is great",
            mode: .clean,
            fillerWords: [FillerWord(word: "um"), FillerWord(word: "so")],
            wordReplacements: [WordReplacement(trigger: "aye pee eye", replacement: "API")],
            snippets: [Snippet(trigger: "my signature", expansion: "Best regards, Emile")]
        )
        XCTAssertEqual(result, "API Best regards, Emile is great")
    }
}
