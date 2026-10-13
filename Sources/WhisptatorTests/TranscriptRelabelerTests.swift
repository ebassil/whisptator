import AVFoundation
import XCTest
@testable import WhisptatorCore

final class TranscriptRelabelerTests: XCTestCase {
    private func line(_ raw: String) -> TranscriptRelabeler.TranscriptLine {
        TranscriptRelabeler.parseLines(raw)[0]
    }

    private func profile(micActiveRanges: [(Double, Double)], systemActiveRanges: [(Double, Double)], totalSeconds: Double = 10) -> ChannelEnergyProfile {
        let window = 0.1
        let count = Int(totalSeconds / window)
        func fill(_ ranges: [(Double, Double)]) -> [Float] {
            var values = [Float](repeating: 0, count: count)
            for (start, end) in ranges {
                for i in Int(start / window)..<min(count, Int((end / window).rounded(.up))) {
                    values[i] = 0.1
                }
            }
            return values
        }
        return ChannelEnergyProfile(
            windowSeconds: window,
            mic: fill(micActiveRanges),
            system: fill(systemActiveRanges)
        )
    }

    func testParseLinesHandlesTextMarkersAndUnparseable() {
        let lines = TranscriptRelabeler.parseLines("""
        [00:12:05] hello there
        [00:12:30] (mic muted)
        garbage line
        """)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].startSeconds, 725)
        XCTAssertEqual(lines[0].body, "hello there")
        XCTAssertFalse(lines[0].isMarker)
        XCTAssertTrue(lines[1].isMarker)
        XCTAssertEqual(lines[2].startSeconds, -1)
    }

    func testMicDominantLineGetsMe() {
        let lines = [line("[00:00:02] i agree")]
        let energy = profile(micActiveRanges: [(2, 3)], systemActiveRanges: [])
        let labels = TranscriptRelabeler.attributeLabels(
            lines: lines,
            segments: [DiarizedSegment(start: 0, end: 10, speaker: "Speaker 1")],
            energy: energy,
            totalSeconds: 10
        )
        // System channel has a diarized segment overlapping, but it carries no
        // energy while the mic does -> "Me" wins (mic-active/system-silent).
        XCTAssertEqual(labels[0], "Me")
    }

    func testSystemDominantLineTakesDiarizedSpeaker() {
        let lines = [line("[00:00:04] quarterly numbers")]
        let energy = profile(micActiveRanges: [], systemActiveRanges: [(4, 5)])
        let labels = TranscriptRelabeler.attributeLabels(
            lines: lines,
            segments: [DiarizedSegment(start: 3, end: 6, speaker: "Speaker 2")],
            energy: energy,
            totalSeconds: 10
        )
        XCTAssertEqual(labels[0], "Speaker 2")
    }

    func testOverlapUsesSystemChannelSpeaker() {
        let lines = [line("[00:00:05] let me add")]
        let energy = profile(micActiveRanges: [(5, 6)], systemActiveRanges: [(5, 6)])
        let labels = TranscriptRelabeler.attributeLabels(
            lines: lines,
            segments: [DiarizedSegment(start: 4, end: 7, speaker: "Speaker 1")],
            energy: energy,
            totalSeconds: 10
        )
        XCTAssertEqual(labels[0], "Speaker 1", "system channel wins the overlap rule")
    }

    func testMarkerLinesAreNeverRelabeled() {
        let lines = [line("[00:00:05] (mic muted)")]
        let labels = TranscriptRelabeler.attributeLabels(
            lines: lines,
            segments: [DiarizedSegment(start: 0, end: 10, speaker: "Speaker 1")],
            energy: profile(micActiveRanges: [], systemActiveRanges: [(0, 10)]),
            totalSeconds: 10
        )
        XCTAssertNil(labels[0])
    }

    func testUnattributableLineFallsBackToPreviousLabel() {
        let lines = [
            line("[00:00:00] first"),
            line("[00:00:30] second"),
        ]
        let energy = profile(micActiveRanges: [], systemActiveRanges: [(0, 1)])
        let labels = TranscriptRelabeler.attributeLabels(
            lines: lines,
            segments: [DiarizedSegment(start: 0, end: 1, speaker: "Speaker 3")],
            energy: energy,
            totalSeconds: 40
        )
        XCTAssertEqual(labels[0], "Speaker 3")
        XCTAssertEqual(labels[1], "Speaker 3")
    }

    // Task 5.7 smoke: full relabel over a real streamed mp3.
    func testEndToEndRelabelOnStoredSampleMeeting() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("relabel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let audioURL = dir.appendingPathComponent("S.mp3")
        let transcriptURL = dir.appendingPathComponent("S.txt")

        let sink = try LameStreamSink(url: audioURL, sampleRate: 48_000, channels: 2, bitrate: 32, quality: 7)
        let frames = 4_800
        for block in 0..<80 { // 8 s
            let t = Double(block) * 0.1
            func value(_ range: ClosedRange<Double>) -> Float { (t >= range.lowerBound && t <= range.upperBound) ? 0.1 : 0 }
            var samples = [Float](repeating: 0, count: frames * 2)
            let mic = value(0.5...2.0)
            let sys = value(3.0...5.0)
            for i in 0..<frames {
                samples[i * 2] = mic
                samples[i * 2 + 1] = sys
            }
            sink.append(AlignedAudioChunk(startFrame: Int64(block * frames), frames: frames, channels: 2, samples: samples))
        }
        await sink.finish()

        let transcript = """
        [00:00:00] i think we should ship it
        [00:00:02] (mic muted)
        [00:00:04] here are the quarterly numbers
        [00:00:06] let me add one point
        """
        try transcript.write(to: transcriptURL, atomically: true, encoding: .utf8)

        let segments = [
            DiarizedSegment(start: 3, end: 5, speaker: "Speaker 1"),
            DiarizedSegment(start: 5.5, end: 7.5, speaker: "Speaker 2"),
        ]
        _ = try TranscriptRelabeler.relabel(transcriptURL: transcriptURL, audioURL: audioURL, segments: segments)

        let contents = try String(contentsOf: transcriptURL, encoding: .utf8)
        let lines = contents.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines[0], "[00:00:00] Me: i think we should ship it")
        XCTAssertEqual(lines[1], "[00:00:02] (mic muted)", "marker preserved verbatim")
        XCTAssertEqual(lines[2], "[00:00:04] Speaker 1: here are the quarterly numbers")
        // t=6: mic silent (muted at 4), system energy: segment Speaker 2 overlaps [6,8)
        XCTAssertEqual(lines[3], "[00:00:06] Speaker 2: let me add one point")

        // Atomicity: file never disappeared (we read it back successfully); temp is gone.
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertFalse(leftovers.contains { $0.contains("relabeling") })
    }

    func testRelabelFailureLeavesTranscriptUntouchedOnMissingTranscript() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID().uuidString).txt")
        XCTAssertThrowsError(try TranscriptRelabeler.relabel(
            transcriptURL: missing,
            audioURL: missing.appendingPathExtension("mp3"),
            segments: []
        ))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path))
    }
}

final class DiarizationEngineTests: XCTestCase {
    func testFFTMatchesReferenceDFT() {
        let n = 64
        var real = (0..<n).map { sin(2 * Double.pi * 3 * Double($0) / Double(n)) + 0.5 * cos(2 * Double.pi * 10 * Double($0) / Double(n)) }
        var imag = [Double](repeating: 0, count: n)
        FFT.realImaginaryTransform(real: &real, imag: &imag, inverse: false)
        let reference = FFT.referenceDFT(real: (0..<n).map { sin(2 * Double.pi * 3 * Double($0) / Double(n)) + 0.5 * cos(2 * Double.pi * 10 * Double($0) / Double(n)) }, imag: [Double](repeating: 0, count: n))
        for k in 0..<n {
            XCTAssertEqual(real[k], reference[k].re, accuracy: 1e-9)
            XCTAssertEqual(imag[k], reference[k].im, accuracy: 1e-9)
        }
    }

    func testLogMelPeakTracksInputFrequency() {
        let rate = 16_000.0
        let seconds = 1.0
        let freq = 1_000.0
        let samples = (0..<Int(rate * seconds)).map { Float(sin(2 * Double.pi * freq * Double($0) / rate) * 0.5) }
        let extractor = LogMelExtractor(normalizeMean: false)
        let frames = extractor.extract(from: samples)
        XCTAssertFalse(frames.isEmpty)
        let frame = frames[frames.count / 2]
        let peak = frame.enumerated().max { $0.element < $1.element }!.offset
        // mel bin for 1 kHz on a 20–7600 Hz 128-bin scale is ~46
        XCTAssertEqual(Double(peak), 46, accuracy: 10)
        XCTAssertGreaterThan(frame[peak], frame[0])
    }

    func testCosineDistanceBasics() {
        let a = [1.0, 0.0]
        let b = [1.0, 0.0]
        let c = [0.0, 1.0]
        XCTAssertEqual(EmbeddingMath.cosineDistance(a, b), 0, accuracy: 1e-9)
        XCTAssertEqual(EmbeddingMath.cosineDistance(a, c), 1, accuracy: 1e-9)
    }

    func testAgglomerativeClusteringSeparatesGroups() {
        let v1 = [1.0, 0.0, 0.0]
        let v2 = [0.99, 0.1, 0.0]
        let v3 = [0.98, 0.15, 0.0]
        let w1 = [0.0, 1.0, 0.0]
        let w2 = [0.1, 0.99, 0.0]
        let u1 = [0.0, 0.0, 1.0]
        let labels = AgglomerativeClustering.cluster(vectors: [v1, v2, w1, v3, w2, u1], distanceThreshold: 0.4)
        // v-group, w-group, u singleton => 3 clusters
        let distinct = Set(labels)
        XCTAssertEqual(distinct.count, 3)
        XCTAssertEqual(labels[0], labels[1])
        XCTAssertEqual(labels[0], labels[3])
        XCTAssertEqual(labels[2], labels[4])
        XCTAssertNotEqual(labels[0], labels[2])
        XCTAssertNotEqual(labels[5], labels[0])
        XCTAssertNotEqual(labels[5], labels[2])
    }

    func testClusteringSingleVector() {
        XCTAssertEqual(AgglomerativeClustering.cluster(vectors: [[1, 2, 3]], distanceThreshold: 0.5), [0])
        XCTAssertEqual(AgglomerativeClustering.cluster(vectors: [], distanceThreshold: 0.5), [])
    }

    func testSpeakerSegmentsNumberedByFirstAppearance() async {
        let turns: [(start: Double, end: Double)] = [
            (0, 2), (3, 5), (6, 8), (9, 11),
        ]
        let pieces = [
            PyannoteDiarizer.Piece(turnIndex: 0, start: 0, end: 2, embedding: [1, 0]),
            PyannoteDiarizer.Piece(turnIndex: 1, start: 3, end: 5, embedding: [0, 1]),
            PyannoteDiarizer.Piece(turnIndex: 2, start: 6, end: 8, embedding: [1, 0]),
            PyannoteDiarizer.Piece(turnIndex: 3, start: 9, end: 11, embedding: [0, 1]),
        ]
        let labels = [0, 1, 0, 1]
        let diarizer = PyannoteDiarizer(
            segmentationModelURL: URL(fileURLWithPath: "/dev/null"),
            embeddingModelURL: URL(fileURLWithPath: "/dev/null")
        )
        let segments = await diarizer.speakerSegments(turns: turns, pieces: pieces, labels: labels)
        XCTAssertEqual(segments.count, 4)
        // first appearance: turn 0 cluster 0 -> Speaker 1, turn 1 cluster 1 -> Speaker 2
        XCTAssertEqual(segments.map(\.speaker), ["Speaker 1", "Speaker 2", "Speaker 1", "Speaker 2"])
        XCTAssertEqual(segments[2].start, 6)
    }
}

final class WeSpeakerFbankTests: XCTestCase {
    func testFrameCountAndShape() {
        let samples = [Float](repeating: 0.1, count: 48_000)
        let frames = WeSpeakerFbank().extract(from: samples)
        XCTAssertEqual(frames.count, 298)
        XCTAssertEqual(frames.first?.count, 80)
    }

    func testShortInputPadsToMinFrames() {
        let samples = [Float](repeating: 0.1, count: 500)
        let frames = WeSpeakerFbank().extract(from: samples)
        XCTAssertEqual(frames.count, 9)
    }

    func testCepstralMeanIsRemovedPerBin() {
        let rate = 16_000.0
        let samples = (0..<32_000).map { Float(sin(2 * Double.pi * 300 * Double($0) / rate) * 0.4) }
        let frames = WeSpeakerFbank().extract(from: samples)
        guard let first = frames.first else { return XCTFail("no frames") }
        for bin in 0..<first.count {
            let mean = frames.reduce(0.0) { $0 + $1[bin] } / Double(frames.count)
            XCTAssertEqual(mean, 0, accuracy: 1e-6)
        }
    }

    func testSinePeakLandsNearExpectedMelBin() {
        let rate = 16_000.0
        // Slow amplitude modulation keeps frames distinct so per-bin mean
        // subtraction does not cancel a stationary tone.
        let samples = (0..<48_000).map { i in
            let t = Double(i) / rate
            return Float(sin(2 * Double.pi * 1_000 * t) * 0.5 * (0.4 + 0.6 * sin(2 * Double.pi * 0.5 * t) * sin(2 * Double.pi * 7.3 * t)))
        }
        let frames = WeSpeakerFbank().extract(from: samples)
        let loudest = frames.max { a, b in
            a.reduce(0) { $0 + abs($1) } < b.reduce(0) { $0 + abs($1) }
        }!
        let peak = loudest.enumerated().max { $0.element < $1.element }!.offset
        // 1 kHz on the kaldi-mel scale between 20 Hz and 8 kHz with 80 bins sits at ~bin 27
        XCTAssertEqual(Double(peak), 27, accuracy: 4)
    }

    func testSilenceProducesFiniteValues() {
        let samples = [Float](repeating: 0, count: 16_000)
        let frames = WeSpeakerFbank().extract(from: samples)
        for frame in frames {
            for value in frame {
                XCTAssertTrue(value.isFinite)
            }
        }
    }
}

/// End-to-end diarization against the real ONNX weights. Skipped unless
/// WHISPTATOR_DIAR_SEG / WHISPTATOR_DIAR_EMB point at the segmentation and
/// embedding `model.onnx` files (Settings → Model downloads them automatically).
final class PyannoteDiarizerE2ETests: XCTestCase {
    private func voiceMix(sampleRate: Double, seconds: Double, f0: Double, syllableRate: Double, seed: UInt64) -> [Float] {
        var rng = SeededGenerator(seed: seed)
        var phase = 0.0
        var out = [Float](repeating: 0, count: Int(sampleRate * seconds))
        for i in 0..<out.count {
            let t = Double(i) / sampleRate
            let vib = f0 * (1.0 + 0.015 * sin(2 * Double.pi * 4.7 * t))
            phase += 2 * Double.pi * vib / sampleRate
            var s = 0.0
            for k in 1...10 { s += sin(Double(k) * phase) / pow(Double(k), 1.5) }
            let env = max(0.0, 0.35 + 0.28 * sin(2 * Double.pi * syllableRate * t))
            let noise = Double.random(in: -1...1, using: &rng)
            out[i] = Float(s * 0.16 * env + noise * 0.006 * env + noise * 0.002)
        }
        return out
    }

    func testTwoVoicesGetDistinctSpeakerLabels() async throws {
        guard let segPath = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_SEG"],
              let embPath = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_EMB"],
              FileManager.default.fileExists(atPath: segPath),
              FileManager.default.fileExists(atPath: embPath) else {
            throw XCTSkip("set WHISPTATOR_DIAR_SEG / WHISPTATOR_DIAR_EMB to run with real models")
        }

        let rate = 48_000.0
        let totalSeconds = 24.0
        let total = Int(rate * totalSeconds)
        let voiceA = voiceMix(sampleRate: rate, seconds: 8.0, f0: 120, syllableRate: 3.0, seed: 11)
        let voiceB = voiceMix(sampleRate: rate, seconds: 8.0, f0: 260, syllableRate: 4.2, seed: 97)
        var right = [Float](repeating: 0, count: total)
        for (i, v) in voiceA.enumerated() { right[Int(2.0 * rate) + i] = v * 0.8 }
        for (i, v) in voiceB.enumerated() { right[Int(11.0 * rate) + i] = v * 0.8 }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("diar-e2e-\(UUID().uuidString).mp3")
        defer { try? FileManager.default.removeItem(at: url) }
        let sink = try LameStreamSink(url: url, sampleRate: 48_000, channels: 2, bitrate: 64, quality: 2, flushInterval: 2.0)
        let chunkFrames = 4_800
        var frame = 0
        while frame < total {
            let frames = min(chunkFrames, total - frame)
            var samples = [Float](repeating: 0, count: frames * 2)
            for i in 0..<frames {
                samples[i * 2 + 1] = right[frame + i]
            }
            sink.append(AlignedAudioChunk(startFrame: Int64(frame), frames: frames, channels: 2, samples: samples))
            frame += frames
        }
        await sink.finish()

        let diarizer = PyannoteDiarizer(segmentationModelURL: URL(fileURLWithPath: segPath), embeddingModelURL: URL(fileURLWithPath: embPath))
        let segments = try await diarizer.diarize(mp3URL: url)

        XCTAssertFalse(segments.isEmpty, "expected detected speech")
        let speakers = Set(segments.map(\.speaker))
        XCTAssertGreaterThanOrEqual(speakers.count, 2, "two distinct voices should cluster apart; got \(segments)")
        let overlapFirst = segments.first { $0.start < 4 && $0.end > 4 }
        let overlapSecond = segments.first { $0.start < 13 && $0.end > 13 }
        XCTAssertNotNil(overlapFirst)
        XCTAssertNotNil(overlapSecond)
        if let a = overlapFirst, let b = overlapSecond {
            XCTAssertNotEqual(a.speaker, b.speaker)
        }
        for segment in segments {
            XCTAssertLessThan(segment.start, segment.end)
        }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
