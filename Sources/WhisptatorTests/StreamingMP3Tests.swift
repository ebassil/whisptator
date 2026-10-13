import XCTest
import AVFoundation
@testable import WhisptatorCore

final class StreamingMP3Tests: XCTestCase {

    private func makeStereoChunk(startFrame: Int64, frames: Int, frequency: Double) -> AlignedAudioChunk {
        var samples = [Float](repeating: 0, count: frames * 2)
        for i in 0..<frames {
            let t = Double(startFrame + Int64(i)) / StereoAligner.sampleRate
            samples[i * 2] = Float(sin(2 * .pi * frequency * t) * 0.3)
            samples[i * 2 + 1] = Float(sin(2 * .pi * (frequency / 2) * t) * 0.2)
        }
        return AlignedAudioChunk(startFrame: startFrame, frames: frames, channels: 2, samples: samples)
    }

    // Task 1.3: synthetic 30-min stereo signal -> playable mp3, byte monotonicity.
    func testStreamedThirtyMinuteStereoFileIsPlayable() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lame-sink-\(UUID().uuidString).mp3")
        defer { try? FileManager.default.removeItem(at: url) }

        let sink = try LameStreamSink(
            url: url,
            sampleRate: 48_000,
            channels: 2,
            bitrate: 32,
            quality: 7,
            flushInterval: 2.0
        )

        let totalFrames: Int64 = 48_000 * 60 * 30
        let chunkFrames = 4_800 // 100 ms
        var frame: Int64 = 0
        var previousBytes = 0
        var chunkIndex = 0

        while frame < totalFrames {
            let frames = Int(min(Int64(chunkFrames), totalFrames - frame))
            sink.append(makeStereoChunk(startFrame: frame, frames: frames, frequency: 440))
            frame += Int64(frames)
            chunkIndex += 1
            if chunkIndex % 100 == 0 {
                let bytes = sink.totalBytesWritten // serialized after the queued appends
                XCTAssertGreaterThanOrEqual(bytes, previousBytes, "byte count must be monotonic")
                XCTAssertGreaterThan(bytes, 0)
                previousBytes = bytes
                sink.tick()
            }
        }

        let finished = expectation(description: "sink finished")
        Task { await sink.finish(); finished.fulfill() }
        wait(for: [finished], timeout: 120)

        XCTAssertGreaterThanOrEqual(sink.totalBytesWritten, previousBytes)

        let file = try AVAudioFile(forReading: url)
        XCTAssertEqual(file.processingFormat.sampleRate, 48_000, accuracy: 1.0)
        XCTAssertEqual(file.processingFormat.channelCount, 2)
        let duration = Double(file.length) / file.processingFormat.sampleRate
        XCTAssertEqual(duration, 1800, accuracy: 2.0, "decoded duration should track streamed length within flush tolerance")

        let probe = AVAudioFrameCount(48_000)
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: probe)!
        try file.read(into: buffer, frameCount: probe)
        XCTAssertEqual(buffer.frameLength, probe)
        XCTAssertNotNil(buffer.floatChannelData)
    }

    func testFinishIsIdempotentAndMonoStreamDecodes() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lame-sink-mono-\(UUID().uuidString).mp3")
        defer { try? FileManager.default.removeItem(at: url) }

        let sink = try LameStreamSink(url: url, sampleRate: 48_000, channels: 1, bitrate: 32, quality: 7)
        var samples = [Float](repeating: 0, count: 48_000)
        for i in 0..<48_000 {
            samples[i] = Float(sin(2 * .pi * 300 * Double(i) / 48_000) * 0.25)
        }
        sink.append(AlignedAudioChunk(startFrame: 0, frames: 48_000, channels: 1, samples: samples))
        await sink.finish()
        await sink.finish() // idempotent

        let file = try AVAudioFile(forReading: url)
        let duration = Double(file.length) / file.processingFormat.sampleRate
        XCTAssertEqual(duration, 1.0, accuracy: 0.1)
    }
}
