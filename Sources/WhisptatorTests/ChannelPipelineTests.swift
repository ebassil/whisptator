import AVFoundation
import XCTest

@testable import WhisptatorCore

/// Microphone and system planes must stay apart from segmentation onward, and
/// the microphone plane must not be believed when it is only carrying the
/// remote voice back from the speakers.
final class ChannelPipelineTests: XCTestCase {
    private let rate = StereoAligner.sampleRate
    private func frames(_ seconds: Double) -> Int64 { Int64((seconds * 48_000).rounded()) }

    private func chunk(startFrame: Int64, seconds: Double, mic: Float, system: Float) -> AlignedAudioChunk {
        let n = Int(frames(seconds))
        var samples = [Float](repeating: 0, count: n * 2)
        for i in 0..<n {
            samples[i * 2] = mic
            samples[i * 2 + 1] = system
        }
        return AlignedAudioChunk(startFrame: startFrame, frames: n, channels: 2, samples: samples)
    }

    private func collect(_ segmenters: [EnergyVADSegmenter], plan: [(seconds: Double, mic: Float, system: Float)]) -> [SpeechSegment] {
        var segments: [SpeechSegment] = []
        for segmenter in segmenters {
            segmenter.onSegment = { segments.append($0) }
        }
        var frame: Int64 = 0
        for (seconds, mic, system) in plan {
            let total = frames(seconds)
            var consumed: Int64 = 0
            while consumed < total {
                let step = min(frames(0.1), total - consumed)
                let chunk = chunk(startFrame: frame + consumed, seconds: Double(step) / 48_000, mic: mic, system: system)
                for segmenter in segmenters {
                    segmenter.append(chunk)
                }
                consumed += step
            }
            frame += total
        }
        for segmenter in segmenters {
            segmenter.flush()
        }
        return segments
    }

    func testEachChannelSegmentsIndependentlyInsteadOfFoldingTogether() {
        let mic = EnergyVADSegmenter(channel: .mic)
        let system = EnergyVADSegmenter(channel: .system)
        let segments = collect([mic, system], plan: [
            (1.0, 0.0, 0.0),      // silence
            (2.0, 0.1, 0.0),      // local speech only
            (1.0, 0.0, 0.0),      // gap
            (2.0, 0.0, 0.1),      // remote speech only
            (1.0, 0.0, 0.0),
        ])
        let micSegments = segments.filter { $0.channel == .mic }
        let systemSegments = segments.filter { $0.channel == .system }
        XCTAssertEqual(micSegments.count, 1, "microphone burst segmented on its own")
        XCTAssertEqual(systemSegments.count, 1, "system burst segmented on its own")
        // Cumulative plan: silence 0-1, mic 1-3, gap 3-4, system 4-6, silence 6-7.
        XCTAssertEqual(micSegments.first?.startFrame ?? -1, frames(0.8), "head padding of 0.2 s")
        XCTAssertEqual(systemSegments.first?.startFrame ?? -1, frames(3.8), "head padding of 0.2 s")
    }

    func testMicrophoneSegmentsCarryNoLocalShareWithoutAnEchoGate() {
        let mic = EnergyVADSegmenter(channel: .mic)
        let segments = collect([mic], plan: [(0.5, 0.0, 0.0), (1.5, 0.1, 0.0), (0.6, 0.0, 0.0)])
        XCTAssertEqual(segments.count, 1)
        XCTAssertNil(segments[0].localShare, "mono/unmeasured microphone audio has no evidence either way")
    }

    func testPlaneExtractionPicksTheRightChannel() {
        let n = 4
        var samples = [Float](repeating: 0, count: n * 2)
        for i in 0..<n {
            samples[i * 2] = Float(i)          // mic
            samples[i * 2 + 1] = Float(i) + 10 // system
        }
        let chunk = AlignedAudioChunk(startFrame: 0, frames: n, channels: 2, samples: samples)
        XCTAssertEqual(chunk.plane(.mic), [0, 1, 2, 3])
        XCTAssertEqual(chunk.plane(.system), [10, 11, 12, 13])

        let mono = AlignedAudioChunk(startFrame: 0, frames: n, channels: 1, samples: [1, 2, 3, 4])
        XCTAssertEqual(mono.plane(.mic), [1, 2, 3, 4])
        XCTAssertEqual(mono.plane(.system), [1, 2, 3, 4], "a mono stream answers for whichever channel is asked")
    }
}

/// Ordering across the two producers of the chunk queue.
final class ChunkQueueOrderingTests: XCTestCase {
    private func segment(_ startFrame: Int64, channel: AudioChannel) -> SpeechSegment {
        SpeechSegment(
            startFrame: startFrame,
            endFrame: startFrame + 48_000,
            samples: [Float](repeating: 0.1, count: 48_000),
            sampleRate: 48_000,
            channel: channel
        )
    }

    func testSegmentsDequeueInTimelineOrderEvenWhenEnqueuedLate() async {
        let queue = ChunkQueue(capacity: 10)
        // System burst that started earlier is emitted later: a long microphone
        // segment can be cut after a short system one finished.
        queue.enqueue(segment(96_000, channel: .mic))
        queue.enqueue(segment(48_000, channel: .system))
        queue.enqueue(segment(144_000, channel: .mic))

        let first = await queue.dequeue()
        let second = await queue.dequeue()
        let third = await queue.dequeue()
        XCTAssertEqual(first?.startFrame, 48_000)
        XCTAssertEqual(second?.startFrame, 96_000)
        XCTAssertEqual(third?.startFrame, 144_000)
    }

    func testEqualStartFramesKeepArrivalOrder() async {
        let queue = ChunkQueue(capacity: 10)
        queue.enqueue(segment(48_000, channel: .mic))
        queue.enqueue(segment(48_000, channel: .system))
        let first = await queue.dequeue()
        XCTAssertEqual(first?.channel, .mic, "ties resolve by arrival, not by channel")
    }
}

/// Provenance recording and the echo-only microphone guard.
final class ChunkTranscriberLedgerTests: XCTestCase {
    private final class FixedTranscriber: ChunkTranscribing, @unchecked Sendable {
        func transcribe(segment: SpeechSegment) async throws -> String {
            "words from \(segment.channel.rawValue)"
        }
    }

    private func makeSegment(channel: AudioChannel, localShare: Double?, startSecond: Double) -> SpeechSegment {
        SpeechSegment(
            startFrame: Int64(startSecond * 48_000),
            endFrame: Int64((startSecond + 2) * 48_000),
            samples: [Float](repeating: 0.1, count: 96_000),
            sampleRate: 48_000,
            channel: channel,
            localShare: localShare
        )
    }

    func testLedgerRecordsOneEntryPerWrittenLineInOrder() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try TranscriptWriter(url: url)
        let ledger = TranscriptLedger()
        let queue = ChunkQueue(capacity: 10)
        let transcriber = ChunkTranscriber(queue: queue, transcriber: FixedTranscriber(), writer: writer, ledger: ledger)
        transcriber.start()

        queue.enqueue(makeSegment(channel: .mic, localShare: 0.9, startSecond: 0))
        // An echo-dominated microphone chunk: never worth transcribing.
        queue.enqueue(makeSegment(channel: .mic, localShare: 0.03, startSecond: 3))
        queue.enqueue(makeSegment(channel: .system, localShare: nil, startSecond: 6))
        _ = await queue.waitForDrain(timeout: 5)
        await transcriber.stop()
        await writer.close()

        let entries = ledger.all
        XCTAssertEqual(entries.count, 2, "the skipped echo chunk records no line")
        XCTAssertEqual(entries[0].channel, .mic)
        XCTAssertEqual(entries[0].localShare, 0.9)
        XCTAssertEqual(entries[1].channel, .system)
        XCTAssertEqual(entries[1].startSeconds, 6, accuracy: 0.001)

        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        for (position, line) in lines.enumerated() {
            XCTAssertTrue(line.hasSuffix(entries[position].text), "ledger and transcript stay in step")
        }
    }

    func testUnknownLocalShareIsTranscribed() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try TranscriptWriter(url: url)
        let ledger = TranscriptLedger()
        let queue = ChunkQueue(capacity: 4)
        let transcriber = ChunkTranscriber(queue: queue, transcriber: FixedTranscriber(), writer: writer, ledger: ledger)
        transcriber.start()
        // Microphone audio from before the gate locked on: no measurement, so it
        // must still be transcribed rather than silently thrown away.
        queue.enqueue(makeSegment(channel: .mic, localShare: nil, startSecond: 0))
        _ = await queue.waitForDrain(timeout: 5)
        await transcriber.stop()
        await writer.close()
        XCTAssertEqual(ledger.all.count, 1)
    }
}

final class SegmentLevelTests: XCTestCase {
    private func rms(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + Double($1) * Double($1) }
        return (sum / Double(samples.count)).squareRoot()
    }

    func testQuietSpeechIsBoostedTowardTarget() {
        let quiet = [Float](repeating: 0.006, count: 48_000)
        let boosted = SegmentLevel.normalize(quiet)
        XCTAssertGreaterThan(rms(boosted), rms(quiet) * 3)
        XCTAssertEqual(rms(boosted), SegmentLevel.targetRMS, accuracy: SegmentLevel.targetRMS * 0.05)
    }

    func testLoudSpeechIsLeftAloneAndNoiseIsNotAmplified() {
        let loud = [Float](repeating: 0.2, count: 48_000)
        XCTAssertEqual(SegmentLevel.normalize(loud), loud, "never attenuate")
        let noise = [Float](repeating: 0.0002, count: 48_000)
        XCTAssertEqual(SegmentLevel.normalize(noise), noise, "amplifying near-silence only amplifies noise")
    }

    func testBoostCannotClip() {
        // Quiet overall but with transient peaks: the peak must stay in range.
        var samples = [Float](repeating: 0.004, count: 48_000)
        samples[1000] = 0.9
        let boosted = SegmentLevel.normalize(samples)
        let peak = boosted.map { abs(Double($0)) }.max() ?? 0
        XCTAssertLessThanOrEqual(peak, 1.0)
    }
}

final class RepetitionCollapserTests: XCTestCase {
    func testCollapsesRecognitionLoops() {
        let looped = Array(repeating: "a medium,", count: 30).joined(separator: " ") + " and then it stopped"
        let collapsed = RepetitionCollapser.collapse(looped)
        XCTAssertEqual(collapsed, "a medium, and then it stopped")
    }

    /// A loop can also arrive without the recogniser separating cycles cleanly.
    func testCollapsesLoopsWithoutWordSpacing() {
        let looped = Array(repeating: "a medium,", count: 30).joined()
        let collapsed = RepetitionCollapser.collapse(looped)
        XCTAssertFalse(collapsed.contains("medium,a medium,a medium,a"), "runaway loop must be truncated: \(collapsed)")
    }

    func testCollapsesSingleWordStutters() {
        let text = "the the the the the the report is late"
        XCTAssertEqual(RepetitionCollapser.collapse(text), "the report is late")
    }

    func testKeepsMildRepetitionAndNormalSentences() {
        XCTAssertEqual(RepetitionCollapser.collapse("very very good"), "very very good")
        XCTAssertEqual(
            RepetitionCollapser.collapse("we shipped it and the numbers improved"),
            "we shipped it and the numbers improved"
        )
    }

    func testThreeWordCycleIsCollapsed() {
        let looped = Array(repeating: "that is not, ", count: 12).joined()
        XCTAssertEqual(RepetitionCollapser.collapse(looped), "that is not,")
    }
}
