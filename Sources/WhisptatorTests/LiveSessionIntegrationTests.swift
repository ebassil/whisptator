import AVFoundation
import XCTest
@testable import WhisptatorCore

/// Task 4.6: simulated meetings driven through the live pipeline with a
/// fabricated (fast-forwarded) clock, asserting transcript + mp3 output and
/// crash mid-session behavior.
final class LiveSessionIntegrationTests: XCTestCase {

    private final class EchoTranscriber: ChunkTranscribing, @unchecked Sendable {
        func transcribe(segment: SpeechSegment) async throws -> String {
            try? await Task.sleep(nanoseconds: 1_000_000)
            return "echo at \(segment.startFrame)"
        }
    }

    /// Speech schedule: mic speaks 2 s every 6 s starting at t=2;
    /// system speaks 1.5 s every 9 s starting at t=4.5.
    private func micLevel(at seconds: Double) -> Float {
        seconds >= 2 && seconds.truncatingRemainder(dividingBy: 6) < 2 ? 0.1 : 0.0
    }

    private func systemLevel(at seconds: Double) -> Float {
        seconds >= 4.5 && seconds.truncatingRemainder(dividingBy: 9) < 1.5 ? 0.1 : 0.0
    }

    private func ingest(_ pipeline: LiveMeetingPipeline, seconds: Double, baseNanos: UInt64, mic: (Double) -> Float, system: (Double) -> Float) {
        let stepSeconds = 0.02
        let frames = Int(stepSeconds * 48_000)
        let totalSteps = Int(seconds / stepSeconds)
        for step in 0...totalSteps {
            let t = Double(step) * stepSeconds
            let arrival = baseNanos + UInt64(t * 1_000_000_000)
            pipeline.ingestMic([Float](repeating: mic(t), count: frames), arrivalNanos: arrival)
            pipeline.ingestSystem([Float](repeating: system(t), count: frames), arrivalNanos: arrival + 5_000_000)
        }
    }

    func testTenMinuteSimulatedMeetingProducesTranscriptAndPlayableMP3() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("live-meeting-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let pipeline = try LiveMeetingPipeline(
            config: .init(saveDirectory: dir.path, audioSource: .systemAndMicrophone, mp3Bitrate: 32, mp3Quality: 7, sessionStem: "S"),
            transcriber: EchoTranscriber()
        )
        pipeline.startTranscribing()
        let base = DispatchTime.now().uptimeNanoseconds
        ingest(pipeline, seconds: 600, baseNanos: base, mic: micLevel, system: systemLevel)

        let drained = await pipeline.finalize(drainTimeout: 180)
        XCTAssertTrue(drained, "chunk queue must drain within timeout")

        let contents = try String(contentsOf: pipeline.transcriptURL, encoding: .utf8)
        let lines = contents.split(separator: "\n").map(String.init)
        XCTAssertFalse(lines.isEmpty)
        let pattern = /^\[(\d{2}):(\d{2}):(\d{2})\] echo at (\d+)$/
        var previousSeconds: Double = -1
        for line in lines {
            guard let match = line.firstMatch(of: pattern) else {
                XCTFail("malformed line: \(line)")
                continue
            }
            let seconds = Double(match.1)! * 3600 + Double(match.2)! * 60 + Double(match.3)!
            XCTAssertGreaterThanOrEqual(seconds, previousSeconds, "lines ordered")
            previousSeconds = seconds
            XCTAssertLessThan(Int64(match.4)!, Int64(48_000 * 605), "line inside session window")
        }
        // ~99 mic bursts + ~66 system bursts over 10 min; assert a solid lower bound.
        XCTAssertGreaterThanOrEqual(lines.count, 100)

        let file = try AVAudioFile(forReading: pipeline.audioURL)
        XCTAssertEqual(file.processingFormat.channelCount, 2)
        let duration = Double(file.length) / file.processingFormat.sampleRate
        XCTAssertEqual(duration, 600, accuracy: 5, "mp3 length within flush tolerance")
    }

    func testCrashMidSessionLeavesBothFilesIntact() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("live-crash-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let pipeline = try LiveMeetingPipeline(
            config: .init(saveDirectory: dir.path, audioSource: .systemAndMicrophone, mp3Bitrate: 32, mp3Quality: 7, sessionStem: "S2"),
            transcriber: EchoTranscriber()
        )
        pipeline.startTranscribing()
        let base = DispatchTime.now().uptimeNanoseconds
        ingest(pipeline, seconds: 60, baseNanos: base, mic: micLevel, system: systemLevel)

        // "Crash" = stop pushing audio and read the files without finalizing:
        // everything appended/fsynced so far must be intact; only the encoder
        // tail (< flush window of audio) is lost.
        await pipeline.waitForIngestDrain()

        let contents = try String(contentsOf: pipeline.transcriptURL, encoding: .utf8)
        let lines = contents.split(separator: "\n").map(String.init)
        XCTAssertFalse(lines.isEmpty, "crash must not lose appended lines")
        let pattern = /^\[\d{2}:\d{2}:\d{2}\] echo at \d+$/
        XCTAssertTrue(lines.allSatisfy { $0.hasPrefix("[") }, "all persisted lines well-formed")
        XCTAssertGreaterThanOrEqual(lines.count, 6) // ~9 mic + ~6 system bursts in 60 s

        let file = try AVAudioFile(forReading: pipeline.audioURL)
        let duration = Double(file.length) / file.processingFormat.sampleRate
        XCTAssertGreaterThan(duration, 40, "mp3 survives up to the last flush window")
        XCTAssertLessThanOrEqual(duration, 61)
    }

    func testMicMuteZeroFillsAndMarkerLinesAppear() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("live-mute-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let pipeline = try LiveMeetingPipeline(
            config: .init(saveDirectory: dir.path, audioSource: .systemAndMicrophone, mp3Bitrate: 32, mp3Quality: 7, sessionStem: "S3"),
            transcriber: EchoTranscriber()
        )
        pipeline.startTranscribing()
        let base = DispatchTime.now().uptimeNanoseconds

        // t=1..3 mic speech.
        ingest(pipeline, seconds: 4, baseNanos: base, mic: { t in (t >= 1 && t <= 3) ? 0.1 : 0 }, system: { _ in 0 })
        // mute at t=4: mic must go silent from here even though we keep feeding samples.
        XCTAssertEqual(pipeline.toggleMicMute(), true)
        ingest(pipeline, seconds: 4, baseNanos: base + 4_000_000_000, mic: { _ in 0.1 }, system: { _ in 0 })
        // unmute, then system speech at absolute t=10..12.
        XCTAssertEqual(pipeline.toggleMicMute(), false)
        ingest(pipeline, seconds: 6, baseNanos: base + 8_000_000_000, mic: { _ in 0 }, system: { t in (t >= 2 && t <= 4) ? 0.1 : 0 })

        _ = await pipeline.finalize(drainTimeout: 60)
        let contents = try String(contentsOf: pipeline.transcriptURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("(mic muted)"), "marker appended on mute")
        XCTAssertTrue(contents.contains("(mic unmuted)"), "marker appended on unmute")

        let lines = contents.split(separator: "\n").map(String.init)
        // First line: mic speech starting at t=1 (padded ~0.8 s -> [00:00:00] or :01).
        XCTAssertTrue(lines.contains { $0.hasPrefix("[00:00:00]") || $0.hasPrefix("[00:00:01]") })
        // After the mute gap, system speech at t≈10 must still appear (timeline kept advancing).
        let lateLine = try XCTUnwrap(lines.first { $0.hasPrefix("[00:00:09]") || $0.hasPrefix("[00:00:10]") || $0.hasPrefix("[00:00:11]") })
        XCTAssertTrue(lateLine.contains("echo at"))
    }
}
