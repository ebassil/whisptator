import AVFoundation
import Foundation
import XCTest

@testable import WhisptatorCore

/// Verification against a real recorded meeting, where the ground truth is
/// known: one participant on the microphone and one on system audio, with the
/// laptop's speakers loud enough for the microphone to hear the remote voice.
///
/// Skips unless `WHISPTATOR_DIAR_AUDIO` points at a session mp3 (and
/// `WHISPTATOR_DIAR_EXPECTED_SYSTEM_SPEAKERS` optionally caps the speaker count
/// the system channel should yield).
///
///     WHISPTATOR_DIAR_AUDIO=~/Documents/Whisptator/Meetings/meeting_x.mp3 \
///       swift test --filter RealMeetingDiarizationTests
///
final class RealMeetingDiarizationTests: XCTestCase {
    private var audioURL: URL? {
        guard let path = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_AUDIO"] else { return nil }
        return FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
    }

    private func modelURL(_ repo: String) -> URL? {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Whisptator/Diarization/\(repo)/onnx/model.onnx")
        return FileManager.default.fileExists(atPath: base.path) ? base : nil
    }

    func testSystemChannelDoesNotInventSpeakers() async throws {
        guard let audio = audioURL else { throw XCTSkip("WHISPTATOR_DIAR_AUDIO not set") }
        guard let seg = modelURL("onnx-community--pyannote-segmentation-3.0"),
              let emb = modelURL("onnx-community--wespeaker-voxceleb-resnet34-LM") else {
            throw XCTSkip("diarization models not downloaded")
        }
        let expected = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_EXPECTED_SYSTEM_SPEAKERS"].flatMap { Int($0) } ?? 3

        let diarizer = PyannoteDiarizer(segmentationModelURL: seg, embeddingModelURL: emb)
        let segments = try await diarizer.diarize(mp3URL: audio)
        let speakers = Set(segments.map(\.speaker))
        for segment in segments {
            print(String(format: "DIAR %.2f-%.2f %@", segment.start, segment.end, segment.speaker))
        }
        print("DIAR summary: \(segments.count) segments, \(speakers.count) speaker(s) (cap \(expected))")
        XCTAssertGreaterThan(segments.count, 0, "the session contains speech")
        XCTAssertLessThanOrEqual(speakers.count, expected, "one remote voice must not become dozens")
    }

    /// Diagnostic: the local-speech share of every microphone segment the gate
    /// produces on this recording, so suppression/skip thresholds can be chosen
    /// from the real distribution instead of guessed.
    func testMicrophoneSegmentLocalShareDistribution() async throws {
        guard let audio = audioURL else { throw XCTSkip("WHISPTATOR_DIAR_AUDIO not set") }
        let planes = try StereoProbe.loadPlanes(from: audio)
        let gate = AcousticEchoGate(sampleRate: planes.sampleRate)
        let micSegmenter = EnergyVADSegmenter(channel: .mic, echoGate: gate)
        let systemSegmenter = EnergyVADSegmenter(channel: .system)

        var micSegments: [SpeechSegment] = []
        var systemCount = 0
        micSegmenter.onSegment = { micSegments.append($0) }
        systemSegmenter.onSegment = { _ in systemCount += 1 }

        let chunkFrames = 4_800
        var index = 0
        while index < planes.mic.count {
            let frames = min(chunkFrames, planes.mic.count - index)
            var samples = [Float](repeating: 0, count: frames * 2)
            for i in 0..<frames {
                samples[i * 2] = planes.mic[index + i]
                samples[i * 2 + 1] = planes.system[index + i]
            }
            let chunk = AlignedAudioChunk(startFrame: Int64(index), frames: frames, channels: 2, samples: samples)
            micSegmenter.append(chunk)
            systemSegmenter.append(chunk)
            index += frames
        }
        micSegmenter.flush()
        systemSegmenter.flush()

        print(String(format: "SHARE system segments=%d, mic segments=%d, gate lag=%.0fms gain=%.2f",
                     systemCount, micSegments.count, gate.diagnostics.lagSeconds * 1000, gate.diagnostics.gain))
        let shares = micSegments.compactMap(\.localShare).sorted()
        for segment in micSegments {
            print(String(format: "SHARE mic %6.2f-%6.2fs localShare=%@",
                         Double(segment.startFrame) / segment.sampleRate,
                         Double(segment.endFrame) / segment.sampleRate,
                         segment.localShare.map { String(format: "%.2f", $0) } ?? "nil"))
        }
        if !shares.isEmpty {
            print(String(format: "SHARE summary: min=%.2f p25=%.2f median=%.2f p75=%.2f max=%.2f",
                         shares.first ?? 0,
                         shares[max(0, shares.count / 4)],
                         shares[shares.count / 2],
                         shares[max(0, shares.count * 3 / 4 - 1)],
                         shares.last ?? 0))
        }
        XCTAssertFalse(micSegments.isEmpty, "the microphone channel carries speech")
    }

    /// The microphone plane of this recording is mostly the remote voice coming
    /// back through the speakers; the gate must lock onto that path and find the
    /// local speech inside it.
    func testEchoGateSeparatesLocalSpeechFromSpeakerPlayback() async throws {
        guard let audio = audioURL else { throw XCTSkip("WHISPTATOR_DIAR_AUDIO not set") }

        let planes = try StereoProbe.loadPlanes(from: audio)
        let mic = planes.mic
        let system = planes.system
        let rate = planes.sampleRate

        let gate = AcousticEchoGate(sampleRate: rate)
        let chunkFrames = 4_800
        var index = 0
        while index < mic.count {
            let frames = min(chunkFrames, mic.count - index)
            _ = gate.process(
                mic: Array(mic[index..<(index + frames)]),
                system: Array(system[index..<(index + frames)]),
                startFrame: Int64(index)
            )
            index += frames
        }
        let diagnostics = gate.diagnostics
        print(String(format: "ECHO trusted=%d lag=%.0fms gain=%.3f local=%d echo=%d suppressed=%d",
                     diagnostics.isTrusted ? 1 : 0, diagnostics.lagSeconds * 1000, diagnostics.gain,
                     diagnostics.localFrames, diagnostics.echoFrames, diagnostics.suppressedFrames))

        // Raw comparison: how much of the microphone is explained by the system
        // channel before and after gating.
        let rawLocalShare = gate.localShare(from: 0, to: Int64(mic.count))
        XCTAssertTrue(diagnostics.isTrusted, "a session this talky should yield an echo fit")
        if let share = rawLocalShare {
            print(String(format: "ECHO local share of microphone audio: %.2f", share))
            XCTAssertLessThan(share, 0.9, "the microphone is dominated by echo in this recording")
        }
    }
}

/// Reads the two planes of a session file for offline probes.
enum StereoProbe {
    struct Planes { let mic: [Float]; let system: [Float]; let sampleRate: Double }

    static func loadPlanes(from url: URL) throws -> Planes {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let channels = Int(format.channelCount)
        var planes = Array(repeating: [Float](), count: channels)
        let readFrames = 48_000
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(readFrames)) else {
            throw NSError(domain: "StereoProbe", code: 1)
        }
        var absolute: AVAudioFramePosition = 0
        while absolute < file.length {
            try file.read(into: buffer)
            if buffer.frameLength == 0 { break }
            absolute += AVAudioFramePosition(buffer.frameLength)
            guard let data = buffer.floatChannelData else { break }
            for ch in 0..<channels {
                planes[ch].append(contentsOf: Array(UnsafeBufferPointer(start: data[ch], count: Int(buffer.frameLength))))
            }
        }
        let mic = planes[0]
        let system = channels > 1 ? planes[1] : [Float](repeating: 0, count: mic.count)
        return Planes(mic: mic, system: system, sampleRate: format.sampleRate)
    }
}
