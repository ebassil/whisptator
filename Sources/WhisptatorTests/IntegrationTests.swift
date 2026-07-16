import XCTest
@testable import WhisptatorCore

final class IntegrationTests: XCTestCase {
    var settings: AppSettings!

    override func setUp() {
        super.setUp()
        settings = AppSettings()
    }

    override func tearDown() {
        settings = nil
        super.tearDown()
    }

    func testSettingsPersistence() {
        settings.pasteMode = .typing
        settings.language = "fr"
        settings.cleanupMode = .raw
        settings.meetingRetentionDays = 14

        let newSettings = AppSettings()
        XCTAssertEqual(newSettings.pasteMode, .typing)
        XCTAssertEqual(newSettings.language, "fr")
        XCTAssertEqual(newSettings.cleanupMode, .raw)
        XCTAssertEqual(newSettings.meetingRetentionDays, 14)
    }

    func testCleanupPipelineFull() {
        let pipeline = TextCleanupPipeline()

        let result = pipeline.process(
            "um so aye pee eye my signature is great  really",
            mode: .clean,
            fillerWords: [FillerWord(word: "um"), FillerWord(word: "so")],
            wordReplacements: [WordReplacement(trigger: "aye pee eye", replacement: "API")],
            snippets: [Snippet(trigger: "my signature", expansion: "Best regards, Emile")]
        )

        XCTAssertFalse(result.contains("um"))
        XCTAssertFalse(result.contains("so"))
        XCTAssertTrue(result.contains("API"))
        XCTAssertTrue(result.contains("Best regards, Emile"))
        XCTAssertFalse(result.contains("  "))
    }

    func testPasteEngineClipboard() {
        let paster = ClipboardPaster()
        paster.paste("Test paste content")

        let pasteboard = NSPasteboard.general
        let content = pasteboard.string(forType: .string)
        XCTAssertEqual(content, "Test paste content")
    }

    func testModelManagerAvailableModels() {
        let manager = ModelManager()
        XCTAssertFalse(manager.availableModels.isEmpty)
        XCTAssertEqual(manager.availableModels.count, 5)
        XCTAssertEqual(manager.selectedModelId, SupportedModel.default.id)
        XCTAssertEqual(manager.selectedModel?.type, .whisper)
    }

    func testPermissionGateChecks() {
        let gate = PermissionGate()
        let status = gate.checkPermissions()

        XCTAssertNotNil(status)
    }

    func testDictationOrchestratorInitialization() {
        let modelManager = ModelManager()
        let orchestrator = DictationOrchestrator(settings: settings, modelManager: modelManager)

        XCTAssertEqual(orchestrator.state, .idle)
    }

    func testMeetingRecorderInitialization() {
        let modelManager = ModelManager()
        let recorder = MeetingRecorder(settings: settings, modelManager: modelManager)

        XCTAssertEqual(recorder.state, .idle)
    }
}
