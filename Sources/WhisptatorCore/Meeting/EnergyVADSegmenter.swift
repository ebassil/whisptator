import Foundation

/// Energy (RMS) voice-activity segmenter.
///
/// One instance per source channel: a stereo session runs a microphone segmenter
/// and a system-audio segmenter side by side, so the transcriber is never handed
/// a fold of two speakers talking over each other (which produced half-garbled
/// lines and phantom speakers when both planes were mixed together).
///
/// Cuts a segment at >= 400 ms trailing silence or at a 30 s hard cap, discards
/// detections shorter than 300 ms, and pads emitted chunks by ~0.2 s at head
/// and tail where audio is available. All frame constants are on the shared
/// 48 kHz recording timeline. Thresholds are initial values pending the
/// calibration pass (tasks 8.1).
public final class EnergyVADSegmenter: SpeechSegmenter, @unchecked Sendable {
    public struct Parameters: Sendable {
        public var silenceCutDuration: Double = 0.4
        public var maxSpeechDuration: Double = 30
        public var minSpeechDuration: Double = 0.3
        public var paddingDuration: Double = 0.2
        public var detectionWindowDuration: Double = 0.01
        /// Absolute RMS floor before a window counts as speech (~ -45 dBFS).
        public var absoluteFloorRMS: Float = 0.0056
        /// Speech must exceed noise floor by this factor.
        public var noiseFloorMultiplier: Float = 3.5
        /// EMA rate for the noise-floor estimate (updated in non-speech).
        public var noiseFloorAlpha: Double = 0.0005
        public var historySeconds: Double = 35

        public init() {}

        func frames(_ seconds: Double, rate: Double) -> Int64 { Int64((seconds * rate).rounded()) }
    }

    private let lock = NSLock()
    public var onSegment: ((SpeechSegment) -> Void)?
    private let sampleRate: Double
    private var params: Parameters
    /// Channel this instance segments; tags every emitted segment.
    private let channel: AudioChannel
    /// Optional echo gate for the microphone plane. When present, incoming
    /// microphone audio is gated against the system plane before detection, so
    /// remote speech leaking through the speakers neither opens the VAD nor
    /// reaches the transcriber.
    private let echoGate: AcousticEchoGate?

    private var silenceCutFrames: Int64 { params.frames(params.silenceCutDuration, rate: sampleRate) }
    private var maxSpeechFrames: Int64 { params.frames(params.maxSpeechDuration, rate: sampleRate) }
    private var minSpeechFrames: Int64 { params.frames(params.minSpeechDuration, rate: sampleRate) }
    private var padFrames: Int64 { params.frames(params.paddingDuration, rate: sampleRate) }
    private var windowFrames: Int { Int(params.frames(params.detectionWindowDuration, rate: sampleRate)) }

    private struct SampleRing {
        let capacity: Int
        var buffer: [Float]
        var endFrame: Int64 = 0
        var startFrame: Int64 { max(0, endFrame - Int64(capacity)) }

        init(capacity: Int) {
            self.capacity = capacity
            buffer = [Float](repeating: 0, count: capacity)
        }

        mutating func append(_ samples: ArraySlice<Float>) {
            for s in samples {
                buffer[Int(endFrame % Int64(capacity))] = s
                endFrame += 1
            }
        }

        func slice(from: Int64, to: Int64) -> [Float] {
            let lo = max(from, startFrame)
            let hi = min(to, endFrame)
            guard hi > lo else { return [] }
            var out = [Float]()
            out.reserveCapacity(Int(hi - lo))
            var frame = lo
            while frame < hi {
                let head = frame % Int64(capacity)
                let tail = min(hi, frame + (Int64(capacity) - head))
                let ti = Int(tail - frame)
                if head + Int64(ti) > Int64(capacity) {
                    out.append(contentsOf: buffer[Int(head)...])
                    let wrapped = Int(head + Int64(ti) - Int64(capacity))
                    out.append(contentsOf: buffer[0..<wrapped])
                } else {
                    out.append(contentsOf: buffer[Int(head)..<Int(head) + ti])
                }
                frame = tail
            }
            return out
        }
    }

    private var ring: SampleRing
    private var pending: [Float] = []
    private var noiseFloor: Float = 1e-5
    private var speechActive = false
    private var segmentStartFrame: Int64 = 0
    private var lastSpeechFrame: Int64 = 0
    private var silenceRunFrames: Int64 = 0
    private var isFlushed = false

    public init(
        sampleRate: Double = StereoAligner.sampleRate,
        parameters: Parameters = Parameters(),
        channel: AudioChannel = .mic,
        echoGate: AcousticEchoGate? = nil
    ) {
        self.sampleRate = sampleRate
        self.params = parameters
        self.channel = channel
        self.echoGate = echoGate
        self.ring = SampleRing(capacity: Int(parameters.frames(parameters.historySeconds, rate: sampleRate)))
    }

    public func append(_ chunk: AlignedAudioChunk) {
        lock.lock(); defer { lock.unlock() }
        guard chunk.frames > 0 else { return }
        let mono = samples(of: chunk)
        guard !mono.isEmpty else { return }
        ring.append(mono[...])

        pending.append(contentsOf: mono)
        let w = windowFrames
        var processed = 0
        while pending.count - processed >= w {
            let window = ArraySlice(pending[(processed)..<(processed + w)])
            processed += w
            processWindow(window, chunkStart: chunk.startFrame, chunkConsumedFrames: Int64(processed))
        }
        if processed > 0 {
            pending.removeFirst(processed)
        }
    }

    public func flush() {
        lock.lock(); defer { lock.unlock() }
        if !pending.isEmpty {
            let start = ring.endFrame - Int64(pending.count)
            processWindow(ArraySlice(pending), chunkStart: start, chunkConsumedFrames: Int64(pending.count))
            pending.removeAll()
        }
        if speechActive {
            if lastSpeechFrame - segmentStartFrame >= minSpeechFrames {
                emitSegment(endFrame: min(ring.endFrame, lastSpeechFrame + padFrames))
            }
        }
        speechActive = false
        silenceRunFrames = 0
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        ring = SampleRing(capacity: ring.capacity)
        pending = []
        noiseFloor = 1e-5
        speechActive = false
        silenceRunFrames = 0
    }

    // MARK: - Private

    /// This instance's slice of the chunk: the channel plane, gated for the
    /// microphone when an echo gate is attached.
    private func samples(of chunk: AlignedAudioChunk) -> [Float] {
        if chunk.channels == 1 {
            // Mono session: the single plane belongs to whichever channel this
            // instance was created for.
            return Array(chunk.samples.prefix(chunk.frames))
        }
        let plane = chunk.plane(channel)
        if channel == .mic, let echoGate, chunk.channels >= 2 {
            return echoGate.process(mic: plane, system: chunk.plane(.system), startFrame: chunk.startFrame)
        }
        return plane
    }

    private func processWindow(_ samples: ArraySlice<Float>, chunkStart: Int64, chunkConsumedFrames: Int64) {
        let windowFramesCount = Int64(samples.count)
        let windowStart = chunkStart + chunkConsumedFrames - windowFramesCount
        let rms = rmsOf(samples)

        if speechActive {
            if rms >= threshold() {
                lastSpeechFrame = windowStart + windowFramesCount
                silenceRunFrames = 0
            } else {
                silenceRunFrames += windowFramesCount
            }

            if silenceRunFrames >= silenceCutFrames {
                let speechDuration = lastSpeechFrame - segmentStartFrame
                if speechDuration >= minSpeechFrames {
                    emitSegment(endFrame: lastSpeechFrame + padFrames)
                    speechActive = false
                    silenceRunFrames = 0
                } else {
                    discardActiveRun()
                }
            } else if ring.endFrame - segmentStartFrame >= maxSpeechFrames {
                // Forced cut mid-speech at the 30 s boundary.
                let cutFrame = segmentStartFrame + maxSpeechFrames
                emitSegment(endFrame: cutFrame)
                segmentStartFrame = cutFrame
                silenceRunFrames = 0
            }
        } else {
            if rms >= threshold() {
                speechActive = true
                segmentStartFrame = windowStart
                lastSpeechFrame = windowStart + windowFramesCount
                silenceRunFrames = 0
            } else {
                noiseFloor = Float(Double(noiseFloor) * (1 - params.noiseFloorAlpha) + Double(rms) * params.noiseFloorAlpha)
            }
        }
    }

    private func discardActiveRun() {
        speechActive = false
        silenceRunFrames = 0
    }

    private func emitSegment(endFrame: Int64) {
        let startFrame = segmentStartFrame
        let clampedEnd = min(endFrame, ring.endFrame)
        guard clampedEnd > startFrame else { return }
        let paddedStart = max(startFrame - padFrames, ring.startFrame)
        let samples = ring.slice(from: paddedStart, to: clampedEnd)
        guard !samples.isEmpty else { return }
        let segment = SpeechSegment(
            startFrame: paddedStart,
            endFrame: clampedEnd,
            samples: samples,
            sampleRate: sampleRate,
            channel: channel,
            localShare: channel == .mic ? echoGate?.localShare(from: paddedStart, to: clampedEnd) : nil
        )
        onSegment?(segment)
    }

    private func threshold() -> Float {
        max(noiseFloor * params.noiseFloorMultiplier, params.absoluteFloorRMS)
    }

    private func rmsOf(_ samples: ArraySlice<Float>) -> Float {
        guard !samples.isEmpty else { return 0 }
        var sum: Double = 0
        for s in samples { sum += Double(s) * Double(s) }
        return Float((sum / Double(samples.count)).squareRoot())
    }
}
