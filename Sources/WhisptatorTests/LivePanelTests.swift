import XCTest
@testable import WhisptatorCore

final class AutoScrollControllerTests: XCTestCase {
    private let day = TimeInterval(10_000)

    private func at(_ offset: TimeInterval) -> Date { Date(timeIntervalSince1970: 1_700_000_000 + offset) }

    func testPinnedFollowsNewLinesByDefault() {
        let c = AutoScrollController()
        XCTAssertTrue(c.isPinned)
        XCTAssertTrue(c.contentDidAppend(distanceFromBottom: 0, now: at(0)), "new line while pinned scrolls to end")
        XCTAssertTrue(c.contentDidAppend(distanceFromBottom: 5, now: at(1)))
    }

    func testScrollingBeyondGapDisengagesAndNewLinesDoNotMove() {
        let c = AutoScrollController()
        XCTAssertFalse(c.userDidScroll(distanceFromBottom: 120, now: at(0)))
        XCTAssertFalse(c.isPinned)
        XCTAssertFalse(c.contentDidAppend(distanceFromBottom: 120, now: at(1)), "viewport must not move when free")
        XCTAssertEqual(c.unseenCount, 1)
        XCTAssertFalse(c.contentDidAppend(distanceFromBottom: 120, now: at(2)))
        XCTAssertEqual(c.unseenCount, 2, "indicator counts pending new lines")
    }

    func testReturningWithinGapReEngagesAndJumps() {
        let c = AutoScrollController()
        _ = c.userDidScroll(distanceFromBottom: 300, now: at(0))
        _ = c.contentDidAppend(distanceFromBottom: 300, now: at(1))
        XCTAssertEqual(c.unseenCount, 1)
        XCTAssertTrue(c.userDidScroll(distanceFromBottom: 30, now: at(2)), "within 40pt re-engages with jump")
        XCTAssertTrue(c.isPinned)
        XCTAssertEqual(c.unseenCount, 0)
    }

    func testJumpToLivePillReEngages() {
        let c = AutoScrollController()
        _ = c.userDidScroll(distanceFromBottom: 500, now: at(0))
        _ = c.contentDidAppend(distanceFromBottom: 500, now: at(1))
        XCTAssertTrue(c.jumpToLive(now: at(2)))
        XCTAssertTrue(c.isPinned)
        XCTAssertEqual(c.unseenCount, 0)
    }

    func testProgrammaticScrollEventsIgnoredWithinFollowWindow() {
        let c = AutoScrollController()
        XCTAssertTrue(c.contentDidAppend(distanceFromBottom: 0, now: at(0)))
        // Our own scrollTo generates events with a transient gap.
        XCTAssertFalse(c.userDidScroll(distanceFromBottom: 90, now: at(0.1)), "settling event ignored")
        XCTAssertTrue(c.isPinned, "must not disengage from programmatic settling")
        // After the window, user scrolling up disengages normally.
        _ = c.userDidScroll(distanceFromBottom: 20, now: at(0.5))
        XCTAssertFalse(c.userDidScroll(distanceFromBottom: 90, now: at(1)))
        XCTAssertFalse(c.isPinned)
    }

    func testExactlyAtGapBoundaryCountsAsPinned() {
        let c = AutoScrollController(engagementGap: 40)
        _ = c.userDidScroll(distanceFromBottom: 300, now: at(0))
        XCTAssertTrue(c.userDidScroll(distanceFromBottom: 39.99, now: at(1)), "within 40pt returns pinned + jump")
        XCTAssertTrue(c.isPinned)
        _ = c.userDidScroll(distanceFromBottom: 0, now: at(2))
        XCTAssertFalse(c.userDidScroll(distanceFromBottom: 40.01, now: at(3)))
        XCTAssertFalse(c.isPinned)
    }
}

final class TranscriptFileWatcherTests: XCTestCase {
    private func makeTempFile() -> (URL, FileManager) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("watcher-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return (dir.appendingPathComponent("S.txt"), FileManager.default)
    }

    private func append(_ text: String, to url: URL) {
        let handle = try! FileHandle(forWritingTo: url)
        handle.seekToEndOfFile()
        handle.write(Data(text.utf8))
        handle.closeFile()
    }

    func testInitialContentAndIncrementalAppends() throws {
        let (url, fm) = makeTempFile()
        defer { try? fm.removeItem(at: url.deletingLastPathComponent()) }
        try "line one\nline two\n".write(to: url, atomically: true, encoding: .utf8)

        let expectation1 = expectation(description: "initial reload")
        let expectation2 = expectation(description: "incremental append")
        var appended: [String] = []
        var sawHello = false

        let watcher = TranscriptFileWatcher(url: url, queue: .main, pollInterval: 0.1)
        watcher.onChange = { change in
            switch change {
            case .reloaded(let lines):
                XCTAssertEqual(lines, ["line one", "line two"])
                expectation1.fulfill()
            case .appended(let lines):
                appended.append(contentsOf: lines)
                if !sawHello, appended.contains("[00:00:01] hello") {
                    sawHello = true
                    expectation2.fulfill()
                }
            }
        }
        watcher.start()
        wait(for: [expectation1], timeout: 2)

        append("[00:00:01] hello\n", to: url)
        append("[00:00:02] wor", to: url) // partial line must not surface yet
        wait(for: [expectation2], timeout: 3)
        append("ld\n", to: url)
        runmain(for: 0.5)
        XCTAssertTrue(appended.contains("[00:00:02] world"), "partial line completes later")
        XCTAssertFalse(appended.contains(where: { $0 == "[00:00:02] wor" }))
        watcher.stop()
    }

    func testAtomicRenameTriggersFullReload() throws {
        let (url, fm) = makeTempFile()
        let dir = url.deletingLastPathComponent()
        defer { try? fm.removeItem(at: dir) }
        try "live line\n".write(to: url, atomically: true, encoding: .utf8)

        let reloadExpectation = expectation(description: "reload after rename")
        var sawReloaded = false
        let watcher = TranscriptFileWatcher(url: url, queue: .main, pollInterval: 0.1)
        watcher.onChange = { change in
            if case .appended(let lines) = change, lines.contains("second line") {
                // before the rename: normal append path
            }
            if case .reloaded(let lines) = change, lines.first == "[00:00:00] Speaker 1: live line", !sawReloaded {
                sawReloaded = true
                reloadExpectation.fulfill()
            }
        }
        watcher.start()
        runmain(for: 0.3)

        append("second line\n", to: url)
        runmain(for: 0.3)

        // Simulate the relabel write-back: temp file + atomic rename over the watched path.
        let tempURL = dir.appendingPathComponent("S.txt.relabel")
        try "[00:00:00] Speaker 1: live line\n[00:00:01] (mic muted)\n[00:00:02] Speaker 1: second line\n"
            .write(to: tempURL, atomically: false, encoding: .utf8)
        rename(tempURL.path, url.path) // atomic replace

        wait(for: [reloadExpectation], timeout: 3)
        XCTAssertTrue(sawReloaded)
        watcher.stop()
    }

    private func runmain(for seconds: Double) {
        let e = expectation(description: "main runloop spin")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { e.fulfill() }
        wait(for: [e], timeout: seconds + 1)
    }
}
