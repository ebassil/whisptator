import XCTest
@testable import WhisptatorCore

/// Mock engine: emits text per segment with scripted delays so completions
/// can "shuffle" if ordering were not enforced downstream. Segment identity is
/// carried in samples[0] (its start frame).
private final class MockTranscriber: ChunkTranscribing, @unchecked Sendable {
    private let lock = NSLock()
    private var delays: [Int64: Double]
    private(set) var callOrder: [Int64] = []

    init(delays: [Int64: Double] = [:]) {
        self.delays = delays
    }

    func transcribe(segment: SpeechSegment) async throws -> String {
        let frame = segment.startFrame
        let delay = noteCall(frame)
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return "text at \(frame)"
    }

    private func noteCall(_ frame: Int64) -> Double {
        lock.lock()
        defer { lock.unlock() }
        callOrder.append(frame)
        return delays[frame] ?? 0
    }
}

final class LiveTranscriptionTests: XCTestCase {

    // MARK: 3.3 — timestamp-from-frame math and line format

    func testTimestampFromFrame() {
        XCTAssertEqual(SessionTimeline.timestamp(frame: 34_800_000), "00:12:05")
        XCTAssertEqual(SessionTimeline.timestamp(frame: 0), "00:00:00")
        XCTAssertEqual(SessionTimeline.timestamp(frame: 48_000), "00:00:01")
        XCTAssertEqual(SessionTimeline.timestamp(frame: 48_000 * 60 * 60 + 48_000 * 60 * 2 + 48_000 * 3), "01:02:03")
        XCTAssertEqual(SessionTimeline.seconds(frame: 34_800_000), 725, accuracy: 0.0001)
    }

    func testLineFormat() {
        XCTAssertEqual(SessionTimeline.line(frame: 34_800_000, text: "hello there"), "[00:12:05] hello there")
        XCTAssertEqual(SessionTimeline.markerLine(frame: 60 * 48_000, text: "mic muted"), "[00:01:00] (mic muted)")
    }

    // MARK: 3.1 — durable append

    func testTranscriptWriterAppendsAndFlushes() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("transcript-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }

        let writer = try TranscriptWriter(url: url)
        writer.appendText(frame: 34_800_000, text: "first line")
        writer.appendMarker(frame: 36_000_000, text: "mic muted")
        writer.appendLine("raw line")
        await writer.close()

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(contents, "[00:12:05] first line\n[00:12:30] (mic muted)\nraw line\n")
    }

    // MARK: 3.2 — order preservation and drop policy

    private func segment(startFrame: Int64, seconds: Double = 1) -> SpeechSegment {
        var samples = [Float](repeating: Float(startFrame), count: Int(48_000 * seconds))
        samples[0] = Float(startFrame)
        return SpeechSegment(
            startFrame: startFrame,
            endFrame: startFrame + Int64(seconds * 48_000),
            samples: samples,
            sampleRate: 48_000
        )
    }

    func testLinesWrittenInSegmentOrderUnderShuffledLatency() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("transcript-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try TranscriptWriter(url: url)
        let queue = ChunkQueue(capacity: 60)
        // chunk 0 is slow, chunk 1 fast: completions would interleave if we fanned out.
        let mock = MockTranscriber(delays: [0: 0.3, 240_000: 0.01])
        let transcriber = ChunkTranscriber(queue: queue, transcriber: mock, writer: writer)
        transcriber.start()

        for frame in [Int64(0), 240_000, 34_800_000] {
            queue.enqueue(segment(startFrame: frame))
        }
        let drained = await queue.waitForDrain(timeout: 10)
        await transcriber.stop()
        await writer.close()

        XCTAssertTrue(drained)
        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
        XCTAssertEqual(lines, [
            "[00:00:00] text at 0",
            "[00:00:05] text at 240000",
            "[00:12:05] text at 34800000",
        ])
    }

    func testOverflowDropsOldestAndKeepsContinuing() async throws {
        let queue = ChunkQueue(capacity: 3)
        let s0 = segment(startFrame: 0)
        queue.enqueue(s0)
        queue.enqueue(segment(startFrame: 4_800))
        queue.enqueue(segment(startFrame: 9_600))
        let dropped = queue.enqueue(segment(startFrame: 14_400))
        XCTAssertEqual(dropped?.startFrame, 0, "oldest chunk dropped")
        XCTAssertEqual(queue.pendingCount, 3)

        let a = await queue.dequeue()
        XCTAssertEqual(a?.startFrame, 4_800)
        queue.completeWork()
        let b = await queue.dequeue()
        XCTAssertEqual(b?.startFrame, 9_600, "remaining chunks keep original order")
        queue.completeWork()
        let c = await queue.dequeue()
        XCTAssertEqual(c?.startFrame, 14_400)
        queue.completeWork()

        queue.close()
        let d = await queue.dequeue()
        XCTAssertNil(d)
    }

    func testWaitForDrainTimesOutWhenWorkIsInFlight() async throws {
        let queue = ChunkQueue(capacity: 60)
        queue.enqueue(segment(startFrame: 0))
        _ = await queue.dequeue() // simulated in-flight work, never completed
        let drained = await queue.waitForDrain(timeout: 0.1)
        XCTAssertFalse(drained)
        queue.completeWork()
        let drainedAfter = await queue.waitForDrain(timeout: 1)
        XCTAssertTrue(drainedAfter)
    }

    func testWhisperInputDownsampling() {
        let samples = [Float](repeating: 1, count: 48_000)
        let out = AudioResampling.to16kHzMono(samples, from: 48_000)
        XCTAssertEqual(Double(out.count), 16_000, accuracy: 50)
        let passThrough = AudioResampling.to16kHzMono(samples, from: 16_000)
        XCTAssertEqual(passThrough.count, 48_000)
    }
}
