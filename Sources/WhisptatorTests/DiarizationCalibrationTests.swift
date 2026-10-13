import AVFoundation
import Foundation
import XCTest

@testable import WhisptatorCore

/// Speaker-count regression against ground-truth multi-speaker audio.
///
/// The failure this guards against is the one that turned a two-person meeting
/// into "50 speakers": clustering every 3 s embedding window on its own, with a
/// merge threshold tighter than the natural spread of one voice, invents a new
/// speaker for almost every window. Pooling windows per turn first, then
/// clustering turns with a support floor, is what makes the count track reality.
///
/// Needs the calibration clip from `Scripts/make-diar-calibration.sh` (three
/// distinct voices, mp3 round-tripped so it resembles a real meeting channel)
/// plus its ground truth:
///
///     DIAR_CALIB_WAV=synth3_mp3.wav DIAR_CALIB_JSON=synth3.json \
///       swift test --filter DiarizationCalibrationTests
///
final class DiarizationCalibrationTests: XCTestCase {
    private struct Turn { let start: Double; let end: Double; let speaker: Int }

    private func urlIfPresent(_ env: String) -> URL? {
        guard let path = ProcessInfo.processInfo.environment[env],
              FileManager.default.fileExists(atPath: path) else { return nil }
        return URL(fileURLWithPath: path)
    }

    private func embeddingModelURL() -> URL? {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Whisptator/Diarization/onnx-community--wespeaker-voxceleb-resnet34-LM/onnx/model.onnx")
        return FileManager.default.fileExists(atPath: base.path) ? base : nil
    }

    func testTurnLevelClusteringRecoversTheRealSpeakerCount() async throws {
        guard let wav = urlIfPresent("DIAR_CALIB_WAV"), let truth = urlIfPresent("DIAR_CALIB_JSON"),
              let modelPath = embeddingModelURL() else {
            throw XCTSkip("set DIAR_CALIB_WAV / DIAR_CALIB_JSON to run the calibration")
        }
        let turns = try decodeTurns(truth)
        let audio = try await SystemChannelLoader.load16kHzMono(from: wav)
        let embedder = WeSpeakerEmbedder(model: try OrtModel(url: modelPath))
        let parameters = PyannoteDiarizer.Parameters()

        // Embed windows inside each known turn.
        let window = Int(2.0 * 16_000)
        let hop = Int(1.0 * 16_000)
        var windows: [(turn: Int, speaker: Int, start: Double, embedding: [Double])] = []
        for (index, turn) in turns.enumerated() {
            var offset = Int(turn.start * 16_000)
            let limit = min(audio.count, Int(turn.end * 16_000)) - window
            while offset <= limit {
                let slice = Array(audio[offset..<(offset + window)])
                if let embedding = embedder.embed(slice) {
                    windows.append((index, turn.speaker, Double(offset) / 16_000, embedding))
                }
                offset += hop
            }
        }
        let actualSpeakers = Set(turns.map(\.speaker)).count
        XCTAssertFalse(windows.isEmpty, "calibration clip produced no embeddings")

        // What window-level clustering does: this is the old behaviour, and it is
        // kept as an assertion so a regression to it is loud.
        let windowLabels = AgglomerativeClustering.cluster(
            vectors: windows.map(\.embedding),
            distanceThreshold: parameters.clusterDistanceThreshold,
            weights: windows.map { _ in 2.0 },
            maxClusters: nil,
            minClusterWeight: nil
        )
        let fragmented = Set(windowLabels.labels).count
        print("DIAR window-level clustering: \(fragmented) clusters for \(actualSpeakers) true speakers")

        // Turn pooling is what the pipeline actually does.
        var pooled: [(speaker: Int, embedding: [Double], seconds: Double)] = []
        for (index, turn) in turns.enumerated() {
            let group = windows.filter { $0.turn == index }
            guard !group.isEmpty else { continue }
            pooled.append((
                turn.speaker,
                EmbeddingMath.l2Normalize(EmbeddingMath.weightedMean(group.map(\.embedding), weights: group.map { _ in 1.0 })),
                turn.end - turn.start
            ))
        }
        let turnResult = AgglomerativeClustering.cluster(
            vectors: pooled.map(\.embedding),
            distanceThreshold: parameters.clusterDistanceThreshold,
            weights: pooled.map(\.seconds),
            maxClusters: parameters.maxSpeakers,
            minClusterWeight: parameters.minClusterSeconds
        )
        let predicted = Set(turnResult.labels).count
        print("DIAR turn-pooled clustering: \(predicted) clusters for \(actualSpeakers) true speakers")

        XCTAssertEqual(predicted, actualSpeakers, "turn-level clustering must recover the speaker count")
        XCTAssertLessThan(fragmented, windows.count, "even window-level clustering should merge something")

        // Same-speaker turns must share a label and different speakers must not.
        var labelsBySpeaker: [Int: Set<Int>] = [:]
        for (position, turn) in turns.enumerated() where position < turnResult.labels.count {
            labelsBySpeaker[turn.speaker, default: []].insert(turnResult.labels[position])
        }
        let merged = labelsBySpeaker.filter { $0.value.count > 1 }
        XCTAssertTrue(merged.isEmpty, "one speaker split across clusters: \(labelsBySpeaker)")
        let distinct = Set(turnResult.labels)
        XCTAssertEqual(distinct.count, actualSpeakers)
    }

    private func decodeTurns(_ url: URL) throws -> [Turn] {
        let data = try Data(contentsOf: url)
        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "calibration", code: 1)
        }
        return array.compactMap { entry in
            guard let start = entry["start"] as? Double, let end = entry["end"] as? Double,
                  let speaker = entry["speaker"] as? Int else { return nil }
            return Turn(start: start, end: end, speaker: speaker)
        }
    }
}
