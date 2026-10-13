import Foundation

/// Detects and suppresses acoustic echo in the microphone channel: remote
/// participants' audio played through the machine's speakers and picked up
/// again by the microphone.
///
/// Why this exists. In a stereo session the microphone plane is supposed to
/// carry only the local user, but a laptop mic that hears its own speakers
/// makes the remote voice the loudest thing on that channel. Untreated, the
/// transcriber writes the remote speech twice (once per channel), the
/// relabeler attributes it to `Me`, and clustering sees one voice as many.
///
/// Sample-level cancellation is not usable here: the echo path is nonlinear
/// (speaker response, room reverb, device processing), so the planes correlate
/// at the sample level essentially by chance (r ≈ 0.01) while their short-term
/// energy envelopes correlate strongly (r ≈ 0.78 at a 170 ms lag on a real
/// meeting). This gate therefore works on 20 ms RMS envelopes:
///
///  1. fit an echo **lag** by maximizing the correlation between the microphone
///     envelope and the delayed system envelope over a rolling history;
///  2. fit an echo **gain** as a low quantile of the mic/system envelope ratio
///     while the system channel is active — the low quantile ignores the
///     moments when the local user talks on top of the echo;
///  3. classify each frame as `local` (mic clearly louder than the predicted
///     echo), `echo` (the predicted echo explains the mic), or `silence`;
///  4. attenuate suppressed frames behind an attack/release smoothed gain ramp,
///     so the stream handed to segmentation and the transcriber carries the
///     local voice and silence instead of the remote voice.
///
/// Decisions are retained on a ring so a finished segment can be scored with
/// `localShare(from:to:)`, which is what lets the relabeler tell a genuine
/// local utterance from a gate that has not seen enough echo to learn from.
public final class AcousticEchoGate: @unchecked Sendable {
    public struct Parameters: Sendable {
        /// Analysis window length in seconds (envelope granularity).
        public var frameDuration: Double = 0.02
        /// Shortest plausible speaker-to-microphone delay.
        public var minLagSeconds: Double = 0.01
        /// Longest delay searched. Speaker-to-microphone propagation is a few
        /// milliseconds and the rest is device and software buffering; beyond
        /// ~350 ms the match is not an echo path. Leaving 600 ms in range let a
        /// real meeting lock onto 400 ms with a gain of 0.2, which explained
        /// nothing and suppressed nothing.
        public var maxLagSeconds: Double = 0.35
        /// Envelope history used for the lag/gain fit. Needs to be long enough
        /// that the log-envelope correlation over it is meaningful — measured on
        /// a real meeting, short windows produced correlations too low and too
        /// noisy to cross the trust threshold, and wandered between refits.
        public var fitWindowSeconds: Double = 12
        /// Re-fit lag and gain every this many analysis frames (1 s default).
        public var refitIntervalFrames: Int = 50
        /// Envelope correlation a lag's smoothed score must reach for the fit to
        /// be trusted.
        public var minCorrelation: Double = 0.35
        /// A different lag must beat the current one by this much to replace it.
        public var lagSwitchMargin: Double = 0.05
        /// EMA factor with which each refit's correlation updates a candidate
        /// lag's score. Short windows cannot separate neighbouring lags; the
        /// rolling average across the session is what locks on.
        public var lagScoreSmoothing: Double = 0.25
        /// RMS below which a frame is silence rather than speech.
        public var noiseFloorRMS: Double = 0.0035
        /// Microphone must exceed the predicted echo by this factor …
        public var localOverEchoRatio: Double = 2.5
        /// … and by this absolute envelope margin, to count as the local
        /// speaker. Calibrated on a real speakerphone meeting: the relative test
        /// alone keeps every local frame but leaves ~29% of echo frames looking
        /// local; requiring both takes that to ~20% while still keeping the
        /// local voice during system silence untouched.
        public var localOverEchoMargin: Double = 0.008
        /// Linear gain applied while suppressed. Deep enough that suppressed
        /// frames fall below the segmenter's speech floor, so the microphone
        /// voice-activity detector closes between remote utterances instead of
        /// running continuously: measured on a real speakerphone meeting, −18 dB
        /// left 66 % of the remote-speech frames still above the floor (one
        /// remote monologue became a single 30-second microphone chunk) while
        /// −28 dB leaves 14 %.
        public var suppressionGain: Double = 0.04
        /// Consecutive echo frames before suppression engages.
        public var attackFrames: Int = 2
        /// Local frames before suppression releases. The envelope model misfires
        /// on roughly one echo frame in five (the echo path's gain varies with
        /// content, reverb and mic processing), so suppression must not be ripped
        /// open by a single spurious "local" frame. Requiring five (100 ms) costs
        /// almost nothing in local-speech preservation and a great deal in
        /// suppression depth.
        public var releaseFrames: Int = 5
        /// Consecutive frames that must classify as local before a frame counts
        /// as local *evidence*. Measured on a real speakerphone meeting: the
        /// frames an envelope model misclassifies as local during pure remote
        /// speech come in runs of 1-2 frames (median 2, longest 180 ms), while
        /// genuine local speech sustains for 240-660 ms. Requiring a run of this
        /// length removes ~95 % of the false local evidence without touching real
        /// speech, which is what makes segment-level attribution trustworthy.
        public var minLocalRunFrames: Int = 8
        /// Ramp factor toward the target gain per frame.
        public var gainRamp: Double = 0.45
        /// EMA factor for the gain estimate across refits.
        public var gainSmoothing: Double = 0.3
        /// Quantile of the aligned mic/system ratio used as the echo gain. The
        /// median: a lower quantile under-predicts the echo level, and frames
        /// then look louder than expected and get labelled `local`.
        public var gainQuantile: Double = 0.5
        /// System-active frames required before the fit is trusted.
        public var minFitFrames: Int = 40
        /// Sample-frame range of decisions to retain.
        public var decisionHistorySeconds: Double = 900

        public init() {}
    }

    public enum FrameClass: UInt8, Sendable {
        case silence = 0
        case local = 1
        case echo = 2
        case unknown = 3
    }

    public struct Diagnostics: Sendable {
        public var isTrusted = false
        public var lagSeconds = 0.0
        public var gain = 0.0
        public var localFrames = 0
        public var echoFrames = 0
        public var suppressedFrames = 0
    }

    public private(set) var diagnostics = Diagnostics()

    private let lock = NSLock()
    private let params: Parameters
    private let frameSamples: Int
    private let historyFrames: Int
    private let maxLagFrames: Int

    /// Rolling envelopes, indexed by absolute frame number modulo the ring size.
    private var micRing: [Double]
    private var sysRing: [Double]
    /// Frame decisions, indexed by absolute frame number modulo `decisions.count`.
    private var decisions: [FrameClass]
    private var framesSeen = 0
    /// Absolute sample offset of the first processed chunk (recording timeline).
    private var baseSampleOffset: Int64 = 0
    private var samplesConsumed: Int64 = 0

    private var micPending: [Double] = []
    private var sysPending: [Double] = []

    private var lagFrames = 0
    /// Smoothed envelope-correlation score per candidate lag.
    private var lagScores: [Double]
    private var gain = 0.0
    private var trusted = false
    private var suppressed = false
    private var echoRun = 0
    private var localRun = 0
    private var appliedGain = 1.0

    public init(sampleRate: Double = StereoAligner.sampleRate, parameters: Parameters = Parameters()) {
        self.params = parameters
        self.frameSamples = max(1, Int((parameters.frameDuration * sampleRate).rounded()))
        self.maxLagFrames = max(1, Int((parameters.maxLagSeconds / parameters.frameDuration).rounded(.up)))
        self.historyFrames = max(8, Int((parameters.fitWindowSeconds / parameters.frameDuration).rounded(.up)))

        let ringSize = historyFrames + maxLagFrames + 2
        self.micRing = [Double](repeating: 0, count: ringSize)
        self.sysRing = [Double](repeating: 0, count: ringSize)
        self.lagScores = [Double](repeating: 0, count: maxLagFrames + 1)
        self.decisions = [FrameClass](repeating: .silence, count: Int((parameters.decisionHistorySeconds / parameters.frameDuration).rounded(.up)))
    }

    /// Gate one microphone chunk against the system chunk covering the same
    /// timeline range.
    ///
    /// - Parameters:
    ///   - mic: microphone samples.
    ///   - system: system-audio samples for the same frames (same count).
    ///   - startFrame: position of the chunk on the recording timeline.
    /// - Returns: microphone samples with echo attenuated. Until the fit is
    ///   trusted the input is returned unchanged.
    public func process(mic: [Float], system: [Float], startFrame: Int64) -> [Float] {
        lock.lock(); defer { lock.unlock() }
        guard mic.count > 0, mic.count == system.count else { return mic }
        if samplesConsumed == 0 { baseSampleOffset = startFrame }

        var output = mic
        var index = 0
        // Start of the frame currently being filled, inside this buffer; nil
        // when that frame began in an earlier chunk. Session chunks are exact
        // multiples of the analysis frame, so that only happens for a ragged
        // tail, whose few samples are simply left ungated.
        var frameStart: Int? = nil
        while index < mic.count {
            if micPending.isEmpty { frameStart = index }
            let take = min(frameSamples - micPending.count, mic.count - index)
            for i in 0..<take {
                micPending.append(Double(mic[index + i]))
                sysPending.append(Double(system[index + i]))
            }
            index += take
            samplesConsumed += Int64(take)
            if micPending.count == frameSamples {
                let target = advanceFrame(mic: micPending, system: sysPending)
                if let start = frameStart {
                    apply(target, to: &output, startingAt: start, count: frameSamples)
                }
                micPending.removeAll(keepingCapacity: true)
                sysPending.removeAll(keepingCapacity: true)
            }
        }
        return output
    }

    /// Share of a sample-frame range attributable to the local speaker, counted
    /// as frames inside a *sustained* local run (see `minLocalRunFrames`).
    ///
    /// Frame-level classification alone is not trustworthy evidence: the envelope
    /// model misfires on roughly one echo frame in five, and those come in runs of
    /// one or two frames, while real speech sustains. Counting only sustained runs
    /// is what makes this number usable for "was this the local user?" decisions.
    ///
    /// `nil` when the range is outside the retained decision history or the fit
    /// was never trusted (mono sessions, or a call with no echo to learn from) —
    /// callers must then fall back to their own judgement.
    public func localShare(from startFrame: Int64, to endFrame: Int64) -> Double? {
        lock.lock(); defer { lock.unlock() }
        guard trusted, framesSeen > 0 else { return nil }
        let lo = frameNumber(for: startFrame)
        let hi = frameNumber(for: max(endFrame, startFrame + 1))
        guard hi > lo else { return nil }
        let minRun = max(1, params.minLocalRunFrames)

        // Scan a little wider than the range so a run that started before `lo`
        // or continues past `hi` is measured at its true length.
        let scanLo = max(0, lo - minRun)
        let scanHi = hi + minRun

        var voiced = 0
        var sustained = 0
        var runStart = 0
        var inRun = false
        var frame = scanLo
        while frame < scanHi {
            let decision = decisionAt(frame)
            if decision == .local {
                if !inRun { inRun = true; runStart = frame }
            } else if inRun {
                if frame - runStart >= minRun {
                    sustained += max(0, min(frame, hi) - max(runStart, lo))
                }
                inRun = false
            }
            if frame >= lo, frame < hi, decision == .local || decision == .echo { voiced += 1 }
            frame += 1
        }
        if inRun, scanHi - runStart >= minRun {
            sustained += max(0, min(scanHi, hi) - max(runStart, lo))
        }

        guard voiced > 0 else { return nil }
        return Double(min(sustained, voiced)) / Double(voiced)
    }

    public func reset() {
        lock.lock()
        micRing = [Double](repeating: 0, count: micRing.count)
        sysRing = [Double](repeating: 0, count: sysRing.count)
        decisions = [FrameClass](repeating: .silence, count: decisions.count)
        framesSeen = 0
        baseSampleOffset = 0
        samplesConsumed = 0
        micPending = []
        sysPending = []
        lagFrames = 0
        lagScores = [Double](repeating: 0, count: lagScores.count)
        gain = 0
        trusted = false
        suppressed = false
        echoRun = 0
        localRun = 0
        appliedGain = 1.0
        diagnostics = Diagnostics()
        lock.unlock()
    }

    // MARK: - Private

    /// Consume one analysis frame and return the target gain for it.
    private func advanceFrame(mic: [Double], system: [Double]) -> Double {
        let number = framesSeen
        micRing[number % micRing.count] = rms(mic)
        sysRing[number % sysRing.count] = rms(system)
        framesSeen += 1

        if number % max(1, params.refitIntervalFrames) == params.refitIntervalFrames - 1 {
            refit()
        }

        let predicted = gain * sysAt(frame: number - lagFrames)
        let level = micRing[number % micRing.count]
        let classification: FrameClass
        if level < params.noiseFloorRMS {
            classification = .silence
        } else if !trusted {
            classification = .unknown
        } else if predicted < params.noiseFloorRMS {
            // Nothing is playing, so nothing can be echoing: audible microphone
            // audio is the local speaker.
            classification = .local
        } else if level >= max(params.localOverEchoRatio * predicted, predicted + params.localOverEchoMargin) {
            classification = .local
        } else {
            classification = .echo
        }
        decisions[number % decisions.count] = classification

        switch classification {
        case .local:
            localRun += 1
            echoRun = 0
            if suppressed, localRun >= params.releaseFrames {
                suppressed = false
                localRun = 0
            }
        case .echo:
            localRun = 0
            echoRun += 1
            if echoRun >= params.attackFrames {
                suppressed = true
            }
        case .silence, .unknown:
            echoRun = 0
            localRun = 0
        }

        switch classification {
        case .local: diagnostics.localFrames += 1
        case .echo: diagnostics.echoFrames += 1
        default: break
        }
        if suppressed { diagnostics.suppressedFrames += 1 }
        diagnostics.isTrusted = trusted
        diagnostics.lagSeconds = Double(lagFrames) * params.frameDuration
        diagnostics.gain = gain

        return suppressed ? params.suppressionGain : 1.0
    }

    /// Ramp the applied gain toward `target` across the frame, avoiding clicks
    /// at frame boundaries.
    private func apply(_ target: Double, to buffer: inout [Float], startingAt start: Int, count: Int) {
        guard count > 0, start + count <= buffer.count else { return }
        let from = appliedGain
        let to = from + (target - from) * params.gainRamp
        appliedGain = to
        // Nothing to do when the ramp is sitting at unity.
        guard from < 0.999 || to < 0.999 else { return }
        let denom = Double(max(1, count - 1))
        var i = 0
        while i < count {
            let g = from + (to - from) * (Double(i) / denom)
            buffer[start + i] = Float(Double(buffer[start + i]) * g)
            i += 1
        }
    }

    private func frameNumber(for sampleFrame: Int64) -> Int {
        let relative = max(0, sampleFrame - baseSampleOffset)
        return Int(relative / Int64(frameSamples))
    }

    private func micAt(frame number: Int) -> Double {
        guard number >= 0, number < framesSeen, number >= framesSeen - micRing.count else { return 0 }
        return micRing[number % micRing.count]
    }

    private func sysAt(frame number: Int) -> Double {
        guard number >= 0, number < framesSeen, number >= framesSeen - sysRing.count else { return 0 }
        return sysRing[number % sysRing.count]
    }

    private func decisionAt(_ number: Int) -> FrameClass {
        guard number >= 0, number < framesSeen, number >= framesSeen - decisions.count else { return .silence }
        return decisions[number % decisions.count]
    }

    /// Re-estimate the echo lag and gain from the rolling envelope history.
    ///
    /// Candidate lags accumulate a smoothed correlation score across refits: one
    /// short window cannot separate a 120 ms echo from a 180 ms one, so a rolling
    /// average is what locks on. Once locked, a different lag has to beat the
    /// current one by `lagSwitchMargin` before it takes over, so a marginally
    /// better but wrong candidate cannot chase the estimate around.
    private func refit() {
        guard framesSeen > maxLagFrames + 8 else { return }
        let minLag = max(1, Int((params.minLagSeconds / params.frameDuration).rounded()))
        let maxLag = min(lagScores.count - 1, max(minLag, maxLagFrames))

        // Newest frames first, so a stale tail falls out of the window.
        let newest = framesSeen - 1
        let span = min(historyFrames, max(0, newest - maxLag))
        guard span > 8 else { return }

        var bestLag = 0
        var bestScore = params.minCorrelation
        var currentScore = 0.0
        var observed = 0

        var lag = minLag
        while lag <= maxLag {
            let (corr, n) = correlationAndCount(at: lag, newest: newest, span: span)
            if n > 8 {
                // Seed with the first observation: averaging up from zero would
                // attenuate every score and a genuine echo path could never cross
                // the correlation threshold.
                let seeded = lagScores[lag] == 0 ? corr : lagScores[lag]
                let smoothed = seeded * (1 - params.lagScoreSmoothing) + corr * params.lagScoreSmoothing
                lagScores[lag] = smoothed
                observed = max(observed, n)
                if lag == lagFrames { currentScore = smoothed }
                if smoothed > bestScore {
                    bestScore = smoothed
                    bestLag = lag
                }
            }
            lag += 1
        }

        guard bestLag > 0, observed >= params.minFitFrames else { return }
        if lagFrames > 0, bestLag != lagFrames, bestScore < currentScore + params.lagSwitchMargin {
            bestLag = lagFrames
        } else {
            lagFrames = bestLag
        }

        var ratios: [Double] = []
        ratios.reserveCapacity(span)
        for i in 0..<span {
            // Same pairing as the correlation: microphone frame now, the system
            // frame `lagFrames` that produced it.
            let micFrame = newest - i
            let m = micAt(frame: micFrame)
            guard m > 0 else { continue }
            let s = sysAt(frame: micFrame - lagFrames)
            guard s > params.noiseFloorRMS * 2 else { continue }
            ratios.append(m / s)
        }
        guard ratios.count >= params.minFitFrames else { return }
        ratios.sort()
        let index = min(ratios.count - 1, max(0, Int(Double(ratios.count - 1) * params.gainQuantile)))
        let estimate = min(max(ratios[index], 0.02), 8.0)
        gain = gain == 0 ? estimate : gain * (1 - params.gainSmoothing) + estimate * params.gainSmoothing

        if !trusted {
            trusted = true
            AppLogger.shared.log(
                category: .audio,
                message: String(format: "Echo gate locked on: lag %.0f ms, gain %.2f", Double(lagFrames) * params.frameDuration * 1000, gain)
            )
        }
    }

    /// Pearson correlation of log envelopes at a candidate lag, over the newest
    /// `span` microphone frames.
    ///
    /// The pairing is microphone frame against the system frame `lag` EARLIER:
    /// sound leaves the speakers first and reaches the microphone afterwards.
    /// Correlating the other way round measures nothing (verified on a real
    /// meeting: correct direction peaks at r = 0.76 around 170 ms, inverted
    /// direction sits near r = -0.1 at every lag), and the gate then locks onto
    /// whatever noise happens to be highest.
    private func correlationAndCount(at lag: Int, newest: Int, span: Int) -> (correlation: Double, samples: Int) {
        guard lag > 0, span > 8 else { return (0, 0) }
        var sumA = 0.0, sumB = 0.0, sumAA = 0.0, sumBB = 0.0, sumAB = 0.0
        var n = 0
        for i in 0..<span {
            let micFrame = newest - i
            let m = micAt(frame: micFrame)
            guard m > 0 else { continue }
            let s = sysAt(frame: micFrame - lag)
            guard s > params.noiseFloorRMS else { continue }
            let a = log(max(m, 1e-6))
            let b = log(max(s, 1e-6))
            sumA += a; sumB += b
            sumAA += a * a; sumBB += b * b; sumAB += a * b
            n += 1
        }
        guard n > 8 else { return (0, n) }
        let cov = sumAB - sumA * sumB / Double(n)
        let varA = max(1e-12, sumAA - sumA * sumA / Double(n))
        let varB = max(1e-12, sumBB - sumB * sumB / Double(n))
        return (cov / sqrt(varA * varB), n)
    }

    private func rms(_ samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 0 }
        var sum = 0.0
        for s in samples { sum += s * s }
        return (sum / Double(samples.count)).squareRoot()
    }
}
