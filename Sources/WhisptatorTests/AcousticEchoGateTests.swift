import Foundation
import XCTest

@testable import WhisptatorCore

/// The gate has to do two opposite things correctly: silence the remote voice
/// that the microphone hears from the speakers, and never silence the local
/// user. Tests drive it with a synthetic echo path (delayed, attenuated, plus
/// room smear) and check both.
final class AcousticEchoGateTests: XCTestCase {
    private let rate = StereoAligner.sampleRate

    /// Builds a system channel of speech bursts and a microphone channel that
    /// contains an attenuated, delayed copy of it, optionally with local speech
    /// on top.
    private struct Scenario {
        var system: [Float]
        var mic: [Float]
        /// Seconds where the local user is speaking into the microphone.
        var localRanges: [(start: Double, end: Double)]
    }

    private func scenario(seconds: Double, lagSeconds: Double, echoGain: Double, localRanges: [(Double, Double)] = []) -> Scenario {
        let total = Int(seconds * rate)
        var system = [Float](repeating: 0, count: total)
        // Speech-like bursts: 2 s on, 1 s off.
        var t = 0.0
        while t < seconds {
            let lo = Int(t * rate)
            let hi = min(total, Int((t + 2.0) * rate))
            for i in lo..<hi {
                let phase = Double(i) / rate
                // Amplitude-modulated tone pair: enough envelope structure for
                // the correlation to lock onto.
                system[i] = Float((0.5 + 0.5 * sin(2 * Double.pi * 3.1 * phase)) * sin(2 * Double.pi * 220 * phase) * 0.18)
            }
            t += 3.0
        }

        let lagSamples = Int(lagSeconds * rate)
        var mic = [Float](repeating: 0, count: total)
        for i in 0..<total {
            let source = i - lagSamples
            let echo = source >= 0 ? Double(system[source]) * echoGain : 0
            // Room smear: a little of the previous sample, so the echo path is
            // not a perfect delayed copy.
            let smear = source >= 1 ? Double(system[source - 1]) * echoGain * 0.25 : 0
            mic[i] = Float(echo + smear + Double.random(in: -0.0006...0.0006))
        }
        for (start, end) in localRanges {
            let lo = Int(start * rate)
            let hi = min(total, Int(end * rate))
            for i in lo..<hi {
                let phase = Double(i) / rate
                mic[i] += Float(sin(2 * Double.pi * 90 * phase) * 0.5 * (0.6 + 0.4 * sin(2 * Double.pi * 4 * phase)))
            }
        }
        return Scenario(system: system, mic: mic, localRanges: localRanges)
    }

    private func run(_ scenario: Scenario, parameters: AcousticEchoGate.Parameters = AcousticEchoGate.Parameters())
        -> (gate: AcousticEchoGate, gated: [Float]) {
        let gate = AcousticEchoGate(sampleRate: rate, parameters: parameters)
        let chunkFrames = 4_800
        var gated = [Float](repeating: 0, count: scenario.mic.count)
        var index = 0
        while index < scenario.mic.count {
            let frames = min(chunkFrames, scenario.mic.count - index)
            let slice = Array(scenario.mic[index..<(index + frames)])
            let reference = Array(scenario.system[index..<(index + frames)])
            let out = gate.process(mic: slice, system: reference, startFrame: Int64(index))
            gated.replaceSubrange(index..<(index + frames), with: out)
            index += frames
        }
        return (gate, gated)
    }

    private func rms(_ samples: ArraySlice<Float>) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + Double($1) * Double($1) }
        return (sum / Double(samples.count)).squareRoot()
    }

    private func rms(_ samples: [Float], from start: Double, to end: Double) -> Double {
        let lo = min(max(0, Int(start * rate)), samples.count)
        let hi = min(max(lo, Int(end * rate)), samples.count)
        return rms(samples[lo..<hi])
    }

    func testLocksOntoTheEchoPathAndSuppressesRemoteOnlyAudio() {
        let scenario = scenario(seconds: 12, lagSeconds: 0.17, echoGain: 0.4)
        let result = run(scenario)

        XCTAssertTrue(result.gate.diagnostics.isTrusted, "an obvious echo path must be learned")
        XCTAssertEqual(result.gate.diagnostics.lagSeconds, 0.17, accuracy: 0.041)
        XCTAssertEqual(result.gate.diagnostics.gain, 0.4, accuracy: 0.25)

        // Measure suppression over a system-active span that ended long enough
        // ago for the fit to have locked on.
        let raw = rms(scenario.mic, from: 5.5, to: 7.5)
        let gated = rms(result.gated, from: 5.5, to: 7.5)
        XCTAssertLessThan(gated, raw * 0.5, "echo-only microphone audio must be attenuated")

        let share = result.gate.localShare(from: Int64(5.5 * rate), to: Int64(7.5 * rate))
        XCTAssertLessThan(share ?? 1, 0.4, "a microphone carried entirely by echo must not look local")
    }

    func testLocalSpeechSurvivesAlongsideEcho() {
        // Local user talks 6.0-7.4 s at four times the echo level.
        let scenario = scenario(seconds: 12, lagSeconds: 0.17, echoGain: 0.4, localRanges: [(6.0, 7.4)])
        let result = run(scenario)

        let echoOnly = rms(result.gated, from: 3.5, to: 5.0)
        let withLocal = rms(result.gated, from: 6.4, to: 7.2)
        XCTAssertGreaterThan(withLocal, echoOnly * 4, "the local voice must stay dominant over suppressed echo")

        let share = result.gate.localShare(from: Int64(6.0 * rate), to: Int64(7.4 * rate))
        XCTAssertNotNil(share)
        XCTAssertGreaterThan(share ?? 0, 0.5, "double-talk must register as local speech")
    }

    func testDoesNotSuppressWhenThereIsNoEcho() {
        // Microphone-only activity with a silent system channel: nothing to learn,
        // nothing to suppress.
        let total = Int(8 * rate)
        var system = [Float](repeating: 0, count: total)
        var mic = [Float](repeating: 0, count: total)
        for i in Int(1.0 * rate)..<Int(5.0 * rate) {
            let phase = Double(i) / rate
            system[i] = 0
            mic[i] = Float(sin(2 * Double.pi * 180 * phase) * 0.2 * (0.6 + 0.4 * sin(2 * Double.pi * 3 * phase)))
        }
        let gate = AcousticEchoGate(sampleRate: rate)
        let chunkFrames = 4_800
        var gated = [Float](repeating: 0, count: total)
        var index = 0
        while index < total {
            let frames = min(chunkFrames, total - index)
            let out = gate.process(
                mic: Array(mic[index..<(index + frames)]),
                system: Array(system[index..<(index + frames)]),
                startFrame: Int64(index)
            )
            gated.replaceSubrange(index..<(index + frames), with: out)
            index += frames
        }
        XCTAssertFalse(gate.diagnostics.isTrusted, "a silent system channel must not produce an echo fit")
        XCTAssertGreaterThan(rms(gated, from: 2.0, to: 4.0), rms(mic, from: 2.0, to: 4.0) * 0.9, "local speech untouched")
    }
}
