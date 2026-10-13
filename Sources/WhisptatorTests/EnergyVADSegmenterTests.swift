import XCTest
@testable import WhisptatorCore

final class EnergyVADSegmenterTests: XCTestCase {
    private let rate = StereoAligner.sampleRate
    private func f(_ seconds: Double) -> Int64 { Int64((seconds * 48_000).rounded()) }

    private func chunk(startFrame: Int64, frames: Int64, level: Float) -> AlignedAudioChunk {
        let n = Int(frames)
        var samples = [Float](repeating: 0, count: n * 2)
        for i in 0..<n {
            samples[i * 2] = level
            samples[i * 2 + 1] = level
        }
        return AlignedAudioChunk(startFrame: startFrame, frames: n, channels: 2, samples: samples)
    }

    /// Feed a [silence, speech, silence, ...] plan of (seconds, level) and return emitted segments.
    private func run(_ segmenter: EnergyVADSegmenter, plan: [(seconds: Double, level: Float)]) -> [SpeechSegment] {
        var segments: [SpeechSegment] = []
        segmenter.onSegment = { segments.append($0) }
        var frame: Int64 = 0
        for (seconds, level) in plan {
            let totalFrames = f(seconds)
            var consumed: Int64 = 0
            while consumed < totalFrames {
                let step = min(f(0.1), totalFrames - consumed)
                segmenter.append(chunk(startFrame: frame + consumed, frames: step, level: level))
                consumed += step
            }
            frame += totalFrames
        }
        segmenter.flush()
        return segments
    }

    func testCutsOnTrailingSilenceWithHeadAndTailPadding() {
        let segmenter = EnergyVADSegmenter()
        let segments = run(segmenter, plan: [
            (2.0, 0.0),   // leading silence (history for head padding)
            (3.0, 0.1),   // speech
            (1.0, 0.0),   // trailing silence >= 400 ms -> cut
        ])

        XCTAssertEqual(segments.count, 1)
        let seg = segments[0]
        XCTAssertEqual(seg.startFrame, f(2.0) - f(0.2), "head padded by 0.2 s from history")
        XCTAssertEqual(seg.endFrame, f(5.0) + f(0.2), "tail padded into available silence")
        XCTAssertEqual(Int64(seg.samples.count), seg.endFrame - seg.startFrame)
        XCTAssertEqual(seg.durationSeconds, 3.4, accuracy: 0.001)
        XCTAssertEqual(seg.samples.first ?? -1, 0, "padded head is the prior silence")
    }

    func testForcedCutAtThirtySecondCapAndResumes() {
        let segmenter = EnergyVADSegmenter()
        let segments = run(segmenter, plan: [
            (1.0, 0.0),
            (35.0, 0.1),  // exceeds the 30 s cap
            (1.0, 0.0),
        ])

        XCTAssertEqual(segments.count, 2)
        let first = segments[0]
        let second = segments[1]
        // First segment covers exactly 30 s of speech plus head padding.
        XCTAssertEqual(first.startFrame, f(1.0) - f(0.2))
        XCTAssertEqual(first.endFrame, f(1.0) + f(30.0), "forced cut at the 30 s boundary")
        // Segmentation resumes for the continuing speech.
        XCTAssertEqual(second.startFrame, f(31.0) - f(0.2))
        XCTAssertEqual(second.endFrame, f(36.0) + f(0.2))
        XCTAssertLessThan(first.endFrame, second.endFrame, "segments ordered")
        XCTAssertEqual(Int64(first.samples.count), first.endFrame - first.startFrame)
        XCTAssertEqual(Int64(second.samples.count), second.endFrame - second.startFrame)
    }

    func testDetectionShorterThanThreeHundredMsIsDiscarded() {
        let segmenter = EnergyVADSegmenter()
        let segments = run(segmenter, plan: [
            (1.0, 0.0),
            (0.15, 0.1),  // 150 ms blip
            (2.0, 0.0),
        ])
        XCTAssertTrue(segments.isEmpty, "sub-300ms detections produce no chunk")
    }

    func testPaddingIsLimitedWhenSpeechStartsAtSessionStart() {
        let segmenter = EnergyVADSegmenter()
        let segments = run(segmenter, plan: [
            (3.0, 0.1),   // speech immediately, no prior audio
            (1.0, 0.0),
        ])
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].startFrame, 0, "head padding clamps to available audio")
    }

    func testMuteInducedSilenceDoesNotCrashOrThrow() {
        let segmenter = EnergyVADSegmenter()
        // mic dropped to silence (muting) while system channel keeps a low level
        var segments: [SpeechSegment] = []
        segmenter.onSegment = { segments.append($0) }
        var frame: Int64 = 0
        func feed(_ seconds: Double, mic: Float, system: Float) {
            let total = f(seconds)
            var consumed: Int64 = 0
            while consumed < total {
                let step = min(f(0.1), total - consumed)
                let n = Int(step)
                var samples = [Float](repeating: 0, count: n * 2)
                for i in 0..<n {
                    samples[i * 2] = mic
                    samples[i * 2 + 1] = system
                }
                segmenter.append(AlignedAudioChunk(startFrame: frame + consumed, frames: n, channels: 2, samples: samples))
                consumed += step
            }
            frame += total
        }
        feed(2.0, mic: 0.1, system: 0.0)   // speech on mic
        feed(1.0, mic: 0.0, system: 0.0)   // mute -> silence
        feed(1.0, mic: 0.1, system: 0.0)
        feed(1.0, mic: 0.0, system: 0.0)
        segmenter.flush()
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].startFrame, 0, "speech starts at session start, pad clamps to 0")
        XCTAssertEqual(segments[0].endFrame, f(2.2))
        XCTAssertEqual(segments[1].startFrame, f(2.8))
        XCTAssertEqual(segments[1].endFrame, f(4.2))
    }

    func testMultipleUtterancesProduceOrderedSegments() {
        let segmenter = EnergyVADSegmenter()
        let segments = run(segmenter, plan: [
            (0.5, 0.0),
            (2.0, 0.1),
            (0.8, 0.0),
            (1.5, 0.1),
            (0.8, 0.0),
        ])
        XCTAssertEqual(segments.count, 2)
        XCTAssertLessThan(segments[0].endFrame, segments[1].endFrame)
        XCTAssertEqual(segments[0].startFrame, f(0.3))
        XCTAssertEqual(segments[0].endFrame, f(2.7))
        XCTAssertEqual(segments[1].startFrame, f(3.1))
        XCTAssertEqual(segments[1].endFrame, f(5.0))
    }
}
