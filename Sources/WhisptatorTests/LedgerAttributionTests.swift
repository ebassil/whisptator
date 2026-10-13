import Foundation
import XCTest

@testable import WhisptatorCore

/// Attribution driven by the session ledger instead of channel energy.
///
/// The old rule — "the microphone channel is active, so that line is the local
/// user" — collapses the moment the microphone hears the laptop's own speakers,
/// because then the microphone is *always* active. These tests pin the new
/// behaviour: the transcriber's own provenance decides, echo duplicates are
/// removed, and energy is only a fallback for sessions with no ledger.
final class LedgerAttributionTests: XCTestCase {
    private func entry(
        channel: AudioChannel,
        start: Double,
        end: Double,
        localShare: Double?,
        text: String
    ) -> TranscriptLedger.Entry {
        TranscriptLedger.Entry(
            lineIndex: 0,
            channel: channel,
            startSeconds: start,
            endSeconds: end,
            localShare: localShare,
            text: text
        )
    }

    private func profile(mic: [(Double, Double)], system: [(Double, Double)], totalSeconds: Double = 60) -> ChannelEnergyProfile {
        let window = 0.1
        let count = Int(totalSeconds / window)
        func fill(_ ranges: [(Double, Double)]) -> [Float] {
            var values = [Float](repeating: 0, count: count)
            for (start, end) in ranges {
                for i in Int(start / window)..<min(count, Int((end / window).rounded(.up))) {
                    values[i] = 0.12
                }
            }
            return values
        }
        return ChannelEnergyProfile(windowSeconds: window, mic: fill(mic), system: fill(system))
    }

    private func lines(_ stamps: [String]) -> [TranscriptRelabeler.TranscriptLine] {
        TranscriptRelabeler.parseLines(stamps.joined(separator: "\n"))
    }

    private func stamp(_ seconds: Int, _ text: String) -> String {
        String(format: "[%02d:%02d:%02d] %@", seconds / 3600, (seconds % 3600) / 60, seconds % 60, text)
    }

    func testMicrophoneLinesBecomeMeAndSystemLinesTakeTheDiarizedSpeaker() {
        let transcript = lines([
            stamp(5, "let me jump in here"),
            stamp(10, "here is the plan for next quarter"),
        ])
        let ledger = [
            entry(channel: .mic, start: 5, end: 8, localShare: 0.92, text: "let me jump in here"),
            entry(channel: .system, start: 10, end: 16, localShare: nil, text: "here is the plan for next quarter"),
        ]
        let segments = [DiarizedSegment(start: 9.5, end: 16.5, speaker: "Speaker 2")]

        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: segments,
            ledger: ledger,
            energy: profile(mic: [(5, 8)], system: [(9, 17)]),
            totalSeconds: 30
        )
        XCTAssertEqual(attribution.labels[0], "Me")
        XCTAssertEqual(attribution.labels[1], "Speaker 2")
        XCTAssertTrue(attribution.dropped.isEmpty)
    }

    func testEchoCarriedMicrophoneLineFollowsTheRemoteSpeaker() {
        // The gate measured this microphone chunk as echo; the words belong to
        // whoever is on the system channel.
        let transcript = lines([stamp(12, "and the mechanics were afraid")])
        let ledger = [entry(channel: .mic, start: 12, end: 16, localShare: 0.1, text: "and the mechanics were afraid")]
        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: [DiarizedSegment(start: 11, end: 17, speaker: "Speaker 1")],
            ledger: ledger,
            energy: profile(mic: [(11, 17)], system: [(11, 17)]),
            totalSeconds: 30
        )
        XCTAssertEqual(attribution.labels[0], "Speaker 1")
    }

    func testEchoDuplicateOfASystemLineIsDropped() {
        // The same utterance reached the transcriber twice: once from the clean
        // system plane and once through the microphone before the gate locked on.
        let transcript = lines([
            stamp(20, "the story spreads quickly the ai suggested replacing the camera"),
            stamp(21, "the story spreads quickly the ai suggested replacing the camera"),
        ])
        let ledger = [
            entry(channel: .system, start: 20, end: 26, localShare: nil, text: "the story spreads quickly the ai suggested replacing the camera"),
            entry(channel: .mic, start: 21, end: 26, localShare: 0.05, text: "the story spreads quickly the ai suggested replacing the camera"),
        ]
        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: [DiarizedSegment(start: 19.5, end: 26.5, speaker: "Speaker 1")],
            ledger: ledger,
            energy: profile(mic: [(19, 27)], system: [(19, 27)]),
            totalSeconds: 40
        )
        XCTAssertEqual(attribution.labels[0], "Speaker 1")
        XCTAssertTrue(attribution.dropped.contains(1), "the echo copy must not be written twice")
    }

    func testLocalSpeechIsNotDroppedWhenTheSameTopicWasDiscussedOnSystemAudio() {
        let transcript = lines([
            stamp(30, "we agreed on the camera replacement"),
            stamp(31, "that is exactly what I meant"),
        ])
        let ledger = [
            entry(channel: .system, start: 30, end: 34, localShare: nil, text: "we agreed on the camera replacement"),
            entry(channel: .mic, start: 31, end: 35, localShare: 0.8, text: "that is exactly what I meant"),
        ]
        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: [DiarizedSegment(start: 29.5, end: 35.5, speaker: "Speaker 1")],
            ledger: ledger,
            energy: profile(mic: [(31, 35)], system: [(29, 35)]),
            totalSeconds: 40
        )
        XCTAssertEqual(attribution.labels[1], "Me", "different words stay the local user's")
        XCTAssertTrue(attribution.dropped.isEmpty)
    }

    func testSystemLinesNeverInheritMeFromAPrecedingMicrophoneLine() {
        let transcript = lines([
            stamp(10, "I agree with that"),
            stamp(14, "and here is the rest of my answer"),
        ])
        let ledger = [
            entry(channel: .mic, start: 10, end: 12, localShare: 0.9, text: "I agree with that"),
            // A system line whose window the segmentation never covered.
            entry(channel: .system, start: 14, end: 18, localShare: nil, text: "and here is the rest of my answer"),
        ]
        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: [DiarizedSegment(start: 20, end: 24, speaker: "Speaker 1")],
            ledger: ledger,
            energy: profile(mic: [(10, 12)], system: [(14, 18)]),
            totalSeconds: 30
        )
        XCTAssertEqual(attribution.labels[0], "Me")
        XCTAssertNotEqual(attribution.labels[1], "Me")
    }

    /// Two channels can start speaking inside the same second, which produces two
    /// transcript lines with the same timestamp. Attribution must not fall apart
    /// when "until the next line" turns out to be an empty window.
    func testLinesSharingATimestampAreBothAttributed() {
        let transcript = lines([
            stamp(14, "Diagnosed the root cause"),
            stamp(14, "and then speed up the repairs"),
        ])
        let ledger = [
            entry(channel: .mic, start: 14.3, end: 15.9, localShare: 0.85, text: "Diagnosed the root cause"),
            entry(channel: .system, start: 14.65, end: 22.2, localShare: nil, text: "and then speed up the repairs"),
        ]
        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: [DiarizedSegment(start: 14.65, end: 22.2, speaker: "Speaker 1")],
            ledger: ledger,
            energy: profile(mic: [(14, 16)], system: [(14, 23)]),
            totalSeconds: 40
        )
        XCTAssertEqual(attribution.labels[0], "Me")
        XCTAssertEqual(attribution.labels[1], "Speaker 1", "a same-second system line must still get its speaker")
    }

    func testLedgerMismatchFallsBackToEnergyAttribution() {
        // An older session (or a crash): no ledger, so energy decides as before.
        let transcript = lines([stamp(4, "quarterly numbers")])
        let attribution = TranscriptRelabeler.attributeLines(
            lines: transcript,
            segments: [DiarizedSegment(start: 3, end: 6, speaker: "Speaker 2")],
            ledger: [],
            energy: profile(mic: [], system: [(3, 6)]),
            totalSeconds: 20
        )
        XCTAssertEqual(attribution.labels[0], "Speaker 2")
    }

    func testLongestCommonSubsequenceRatioDetectsDuplication() {
        let a = TranscriptRelabeler.tokens("the story spreads quickly the ai")
        let b = TranscriptRelabeler.tokens("and the story spreads quickly the ai system")
        XCTAssertGreaterThan(TranscriptRelabeler.longestCommonSubsequenceRatio(a, b), 0.8)
        let c = TranscriptRelabeler.tokens("nothing related at all here")
        XCTAssertLessThan(TranscriptRelabeler.longestCommonSubsequenceRatio(a, c), 0.4)
    }
}
