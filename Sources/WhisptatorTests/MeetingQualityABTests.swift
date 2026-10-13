import AVFoundation
import Foundation
import XCTest

@testable import WhisptatorCore

/// Runs the real recognizer over a recorded meeting twice: the old way (both
/// channels folded into one mono stream) and the new way (per-channel
/// segmentation with the microphone echo gated, then the speaker-identification
/// pass), so the change in transcript quality is measurable rather than asserted.
///
///     WHISPTATOR_DIAR_AUDIO=/path/to/meeting.mp3 WHISPTATOR_AB_SECONDS=100 \
///       swift test --filter MeetingQualityABTests
///
/// Requires the ASR model to be cached locally, and optionally the diarization
/// models (`WHISPTATOR_DIAR_SEG` / `WHISPTATOR_DIAR_EMB`) to exercise the final
/// relabel pass. Transcripts are written to `WHISPTATOR_AB_OUT`.
final class MeetingQualityABTests: XCTestCase {
    private struct Result {
        var live: String
        var relabeled: String?
        var duplicatesLive: Int
        var duplicatesFinal: Int
        /// Near-duplicate pairs where the two lines came from different sources
        /// (microphone vs system audio) — the signature of one utterance being
        /// written twice. Same-label pairs are the speaker's own words, not an
        /// echo artifact, and must not be counted here.
        var echoPairsLive: Int
        var echoPairsFinal: Int?
    }

    private var audioURL: URL? {
        guard let path = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_AUDIO"] else { return nil }
        return FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
    }

    private var outDir: URL {
        let path = ProcessInfo.processInfo.environment["WHISPTATOR_AB_OUT"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("whisptator-ab", isDirectory: true).path
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testPerChannelTranscriptionBeatsMonoFold() async throws {
        guard let audio = audioURL else { throw XCTSkip("WHISPTATOR_DIAR_AUDIO not set") }
        let seconds = Double(ProcessInfo.processInfo.environment["WHISPTATOR_AB_SECONDS"] ?? "100") ?? 100

        let manager = ModelManager()
        await manager.loadModelOffline()
        guard manager.isModelLoaded else {
            throw XCTSkip("no ASR model cached locally; skipping the A/B run")
        }
        let engine = TranscriptionEngine(modelManager: manager)

        let planes = try StereoProbe.loadPlanes(from: audio)
        let rate = planes.sampleRate
        let limit = min(planes.mic.count, Int(seconds * rate))
        let mic = Array(planes.mic[0..<limit])
        let system = Array(planes.system[0..<limit])

        let folded = await runMonoFold(mic: mic, system: system, rate: rate, engine: engine)
        let separated = await runPerChannel(mic: mic, system: system, rate: rate, engine: engine, diarizerModels: diarizerModels())

        try? folded.write(to: outDir.appendingPathComponent("A_mono_fold.txt"), atomically: true, encoding: .utf8)
        try? separated.live.write(to: outDir.appendingPathComponent("B_per_channel_live.txt"), atomically: true, encoding: .utf8)
        try? separated.relabeled?.write(to: outDir.appendingPathComponent("C_per_channel_final.txt"), atomically: true, encoding: .utf8)

        print("AB ===== A: folded mono =====")
        print(folded)
        print("AB ===== B: per channel + echo gate (live) =====")
        print(separated.live)
        print("AB ===== C: after speaker identification =====")
        print(separated.relabeled ?? "(no diarization models)")
        print(String(format: "AB words: A=%d B=%d C=%d", wordCount(folded), wordCount(separated.live), wordCount(separated.relabeled ?? "")))
        print("AB near-duplicate line pairs: B(live)=\(separated.duplicatesLive) C(final)=\(separated.duplicatesFinal)")
        print("AB echo-duplicate pairs (cross-source): B(live)=\(separated.echoPairsLive) C(final)=\(separated.echoPairsFinal ?? -1)")

        XCTAssertFalse(separated.live.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "B produced no text")

        // The visible symptom in the original transcript was the recognizer
        // looping on one fragment; the gated per-channel path must not do that.
        if let loop = longestRunLoop(in: separated.live) {
            XCTAssertLessThanOrEqual(loop.count, 6, "no runaway recognition loop expected in B (\(loop.token) × \(loop.count))")
        }
        // Echo duplicates may appear live, but none may survive the final pass:
        // on a two-channel recording, a line that repeats a nearby line from the
        // other channel is the remote voice written a second time.
        if let echoPairsFinal = separated.echoPairsFinal {
            XCTAssertEqual(echoPairsFinal, 0,
                           "no cross-source duplicates may survive the relabel pass (\(separated.echoPairsLive) → \(echoPairsFinal))")
        }
    }

    // MARK: - Runs

    /// Old behaviour: fold both planes into one mono stream and segment that.
    private func runMonoFold(mic: [Float], system: [Float], rate: Double, engine: TranscriptionEngine) async -> String {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ab-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let transcriptURL = dir.appendingPathComponent("A.txt")
        let writer = try! TranscriptWriter(url: transcriptURL)
        let queue = ChunkQueue(capacity: 60)
        // No channel separation, no gate: exactly what the pipeline did before.
        let segmenter = EnergyVADSegmenter(channel: .mic)
        segmenter.onSegment = { queue.enqueue($0) }
        let transcriber = ChunkTranscriber(
            queue: queue,
            transcriber: WhisperChunkTranscriber(engine: engine),
            writer: writer,
            lineProcessor: RepetitionCollapser.collapse
        )
        transcriber.start()

        let chunkFrames = 4_800
        var frame = 0
        while frame < mic.count {
            let frames = min(chunkFrames, mic.count - frame)
            var folded = [Float](repeating: 0, count: frames)
            for i in 0..<frames { folded[i] = (mic[frame + i] + system[frame + i]) * 0.5 }
            segmenter.append(AlignedAudioChunk(startFrame: Int64(frame), frames: frames, channels: 1, samples: folded))
            frame += frames
            await pace(queue)
        }
        segmenter.flush()
        _ = await queue.waitForDrain(timeout: 900)
        await transcriber.stop()
        await writer.close()
        return (try? String(contentsOf: transcriptURL, encoding: .utf8)) ?? ""
    }

    /// New behaviour: the live pipeline with one segmenter per channel and the
    /// echo gate in front of the microphone, then the diarization + relabel pass.
    private func runPerChannel(
        mic: [Float],
        system: [Float],
        rate: Double,
        engine: TranscriptionEngine,
        diarizerModels: (segmentation: URL, embedding: URL)?
    ) async -> Result {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ab-\(UUID().uuidString)", isDirectory: true)
        let pipeline = try! LiveMeetingPipeline(
            config: .init(saveDirectory: dir.path, audioSource: .systemAndMicrophone, mp3Bitrate: 32, sessionStem: "B"),
            transcriber: WhisperChunkTranscriber(engine: engine),
            lineProcessor: RepetitionCollapser.collapse
        )
        pipeline.startTranscribing()

        let chunkFrames = 4_800
        let base = DispatchTime.now().uptimeNanoseconds
        var frame = 0
        while frame < mic.count {
            let frames = min(chunkFrames, mic.count - frame)
            let arrival = base + UInt64(Double(frame) / rate * 1_000_000_000)
            pipeline.ingestMic(Array(mic[frame..<(frame + frames)]), arrivalNanos: arrival)
            pipeline.ingestSystem(Array(system[frame..<(frame + frames)]), arrivalNanos: arrival + 5_000_000)
            frame += frames
            await pace(pipeline.queue)
        }
        _ = await pipeline.finalize(drainTimeout: 900)

        let live = (try? String(contentsOf: pipeline.transcriptURL, encoding: .utf8)) ?? ""
        if let echo = pipeline.echoDiagnostics {
            print(String(format: "AB echo gate: trusted=%d lag=%.0fms gain=%.3f local=%d echo=%d suppressed=%d",
                         echo.isTrusted ? 1 : 0, echo.lagSeconds * 1000, echo.gain,
                         echo.localFrames, echo.echoFrames, echo.suppressedFrames))
        }
        let shares = pipeline.ledger.all.compactMap(\.localShare)
        if !shares.isEmpty {
            print(String(format: "AB ledger: %d lines (%d with measured localShare) mean localShare=%.2f",
                         pipeline.ledger.count, shares.count, shares.reduce(0, +) / Double(shares.count)))
        }

        var relabeled: String?
        if let models = diarizerModels {
            let diarizer = PyannoteDiarizer(segmentationModelURL: models.segmentation, embeddingModelURL: models.embedding)
            let segments = try? await diarizer.diarize(mp3URL: pipeline.audioURL)
            if let segments {
                try? TranscriptRelabeler.relabel(
                    transcriptURL: pipeline.transcriptURL,
                    audioURL: pipeline.audioURL,
                    segments: segments,
                    ledger: pipeline.ledger
                )
                relabeled = try? String(contentsOf: pipeline.transcriptURL, encoding: .utf8)
            }
        }
        return Result(
            live: live,
            relabeled: relabeled,
            duplicatesLive: nearDuplicatePairs(live),
            duplicatesFinal: nearDuplicatePairs(relabeled ?? ""),
            echoPairsLive: crossChannelDuplicatePairs(pipeline.ledger.all),
            echoPairsFinal: relabeled.map { crossLabelDuplicatePairs($0) }
        )
    }

    private func diarizerModels() -> (segmentation: URL, embedding: URL)? {
        guard let seg = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_SEG"],
              let emb = ProcessInfo.processInfo.environment["WHISPTATOR_DIAR_EMB"],
              FileManager.default.fileExists(atPath: seg),
              FileManager.default.fileExists(atPath: emb) else { return nil }
        return (URL(fileURLWithPath: seg), URL(fileURLWithPath: emb))
    }

    /// Recognition is slower than the fast-forwarded clock, so let the backlog
    /// drain instead of letting the queue drop chunks and starve the comparison.
    private func pace(_ queue: ChunkQueue) async {
        while queue.pendingCount > 30 {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    // MARK: - Measures

    /// Echo duplicates seen live: near-identical lines within 3 s that came from
    /// *different* channels — the remote voice captured by both planes. Ledger
    /// entries carry the channel each line was transcribed from, so this counts
    /// exactly what the gate let through before the relabel pass got to it.
    private func crossChannelDuplicatePairs(_ entries: [TranscriptLedger.Entry]) -> Int {
        var pairs = 0
        for i in entries.indices {
            for j in (i + 1)..<entries.count {
                guard entries[i].channel != entries[j].channel else { continue }
                guard entries[j].startSeconds - entries[i].startSeconds <= 3 else { continue }
                let a = TranscriptRelabeler.tokens(entries[i].text)
                let b = TranscriptRelabeler.tokens(entries[j].text)
                guard a.count >= 3, b.count >= 3 else { continue }
                if TranscriptRelabeler.longestCommonSubsequenceRatio(a, b) >= 0.6 { pairs += 1 }
            }
        }
        return pairs
    }

    /// Echo duplicates in the final transcript: near-identical lines within 3 s
    /// carrying *different* speaker labels. Same-label neighbours are one voice
    /// speaking in sequence — rhetorical repetition belongs to the speaker, not
    /// to the echo path, and removing it would delete real content.
    private func crossLabelDuplicatePairs(_ text: String) -> Int {
        let parsed = TranscriptRelabeler.parseLines(text).filter { !$0.isMarker && $0.startSeconds >= 0 }
        var pairs = 0
        for i in parsed.indices {
            for j in (i + 1)..<parsed.count {
                guard parsed[j].startSeconds - parsed[i].startSeconds <= 3 else { continue }
                guard let labelA = speakerLabel(parsed[i].body), let labelB = speakerLabel(parsed[j].body),
                      labelA != labelB else { continue }
                let a = TranscriptRelabeler.tokens(TranscriptRelabeler.stripSpeaker(parsed[i].body))
                let b = TranscriptRelabeler.tokens(TranscriptRelabeler.stripSpeaker(parsed[j].body))
                guard a.count >= 3, b.count >= 3 else { continue }
                if TranscriptRelabeler.longestCommonSubsequenceRatio(a, b) >= 0.6 { pairs += 1 }
            }
        }
        return pairs
    }

    private func speakerLabel(_ body: String) -> String? {
        guard let colon = body.firstIndex(of: ":") else { return nil }
        let label = String(body[body.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
        return (label == "Me" || label.hasPrefix("Speaker ")) ? label : nil
    }

    /// Count of line pairs within 3 s of each other sharing most of their words:
    /// the signature of one utterance transcribed from both channels.
    private func nearDuplicatePairs(_ text: String) -> Int {
        let parsed = TranscriptRelabeler.parseLines(text).filter { !$0.isMarker && $0.startSeconds >= 0 }
        var pairs = 0
        for i in 0..<parsed.count {
            for j in (i + 1)..<parsed.count {
                guard parsed[j].startSeconds - parsed[i].startSeconds <= 3 else { continue }
                let a = TranscriptRelabeler.tokens(TranscriptRelabeler.stripSpeaker(parsed[i].body))
                let b = TranscriptRelabeler.tokens(TranscriptRelabeler.stripSpeaker(parsed[j].body))
                guard a.count >= 3, b.count >= 3 else { continue }
                if TranscriptRelabeler.longestCommonSubsequenceRatio(a, b) >= 0.6 { pairs += 1 }
            }
        }
        return pairs
    }

    private func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    /// Longest run of a repeated token, as a proxy for a recognizer loop.
    private func longestRunLoop(in text: String) -> (token: String, count: Int)? {
        let tokens = text.split(whereSeparator: \.isWhitespace).map { $0.lowercased() }
        var best: (token: String, count: Int)?
        var index = 0
        while index < tokens.count {
            var run = 1
            while index + run < tokens.count, tokens[index + run] == tokens[index] { run += 1 }
            if best == nil || run > best!.count { best = (tokens[index], run) }
            index += run
        }
        return best
    }
}
