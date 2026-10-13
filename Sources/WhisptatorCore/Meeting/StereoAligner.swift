import Foundation

public final class StereoAligner: @unchecked Sendable {
    public enum Mode: Sendable {
        case stereo
        case micOnly
        case systemOnly

        public var channels: Int { self == .stereo ? 2 : 1 }
    }

    public static let sampleRate: Double = 48000
    private static let maxBacklogFrames: Int64 = 30 * 48000

    private struct ChannelRing {
        var headFrame: Int64 = 0
        var samples: [Float] = []

        var endFrame: Int64 { headFrame + Int64(samples.count) }

        mutating func append(_ new: some Sequence<Float>, startFrame newStart: Int64) {
            var iterator = new.makeIterator()
            var first = iterator.next()
            guard let head = first else { return }

            let end = endFrame
            if newStart >= end {
                let gap = newStart - end
                if gap > 0 { samples.append(contentsOf: repeatElement(0, count: Int(gap))) }
                samples.append(head)
                while let s = iterator.next() { samples.append(s) }
            } else {
                var skip = Int(end - newStart)
                while let s = iterator.next() {
                    if skip > 0 { skip -= 1; continue }
                    samples.append(s)
                }
            }
        }

        mutating func consume(to frame: Int64) {
            guard frame > headFrame else { return }
            let drop = min(Int(frame - headFrame), samples.count)
            samples.removeFirst(drop)
            headFrame += Int64(drop)
        }

        func values(from start: Int64, frames: Int) -> ArraySlice<Float> {
            let lo = min(max(0, Int(start - headFrame)), samples.count)
            let hi = min(samples.count, lo + frames)
            return samples[lo..<hi]
        }
    }

    private let lock = NSLock()
    private let mode: Mode
    private var micRing = ChannelRing()
    private var systemRing = ChannelRing()
    private var outputFrame: Int64 = 0
    private var epochNanos: UInt64?
    private var micLastArrivalNanos: UInt64?
    private var systemLastArrivalNanos: UInt64?
    private var _micMuted = false

    public var stallGraceNanos: UInt64 = 500_000_000

    public init(mode: Mode) {
        self.mode = mode
    }

    public var micMuted: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _micMuted }
        set { lock.lock(); _micMuted = newValue; lock.unlock() }
    }

    public var currentFrame: Int64 {
        lock.lock(); defer { lock.unlock() }
        return outputFrame
    }

    public func reset() {
        lock.lock()
        micRing = ChannelRing()
        systemRing = ChannelRing()
        outputFrame = 0
        epochNanos = nil
        micLastArrivalNanos = nil
        systemLastArrivalNanos = nil
        lock.unlock()
    }

    public func appendMic(_ samples: [Float], arrivalNanos: UInt64) {
        lock.lock(); defer { lock.unlock() }
        anchorEpoch(arrivalNanos, sampleCount: samples.count)
        micLastArrivalNanos = arrivalNanos
        let start = estimatedStartFrame(arrivalNanos, sampleCount: samples.count)
        if _micMuted {
            micRing.append(repeatElement(0, count: samples.count), startFrame: start)
        } else {
            micRing.append(samples, startFrame: start)
        }
        trimBacklog(ring: &micRing, name: "mic")
    }

    public func appendSystem(_ samples: [Float], arrivalNanos: UInt64) {
        lock.lock(); defer { lock.unlock() }
        anchorEpoch(arrivalNanos, sampleCount: samples.count)
        systemLastArrivalNanos = arrivalNanos
        let start = estimatedStartFrame(arrivalNanos, sampleCount: samples.count)
        systemRing.append(samples, startFrame: start)
        trimBacklog(ring: &systemRing, name: "system")
    }

    public func nextChunk(maxFrames: Int, nowNanos: UInt64) -> AlignedAudioChunk? {
        lock.lock(); defer { lock.unlock() }
        return drainChunk(maxFrames: maxFrames, nowNanos: nowNanos, force: false)
    }

    public func flushAll(maxFrames: Int) -> [AlignedAudioChunk] {
        lock.lock(); defer { lock.unlock() }
        var chunks: [AlignedAudioChunk] = []
        while let chunk = drainChunk(maxFrames: maxFrames, nowNanos: UInt64.max, force: true) {
            chunks.append(chunk)
        }
        return chunks
    }

    // MARK: - Private

    private func drainChunk(maxFrames: Int, nowNanos: UInt64, force: Bool) -> AlignedAudioChunk? {
        guard epochNanos != nil else { return nil }
        switch mode {
        case .micOnly:
            return drainMono(ring: micRing, maxFrames: maxFrames, stalled: isStalled(micLastArrivalNanos, nowNanos: nowNanos), force: force)
        case .systemOnly:
            return drainMono(ring: systemRing, maxFrames: maxFrames, stalled: isStalled(systemLastArrivalNanos, nowNanos: nowNanos), force: force)
        case .stereo:
            let micAvail = max(0, micRing.endFrame - outputFrame)
            let sysAvail = max(0, systemRing.endFrame - outputFrame)
            let common = min(micAvail, sysAvail)
            if common >= Int64(maxFrames) {
                return emitStereo(frames: maxFrames)
            }
            let stalled = isStalled(micLastArrivalNanos, nowNanos: nowNanos) || isStalled(systemLastArrivalNanos, nowNanos: nowNanos)
            guard force || stalled else { return nil }
            let total = max(micAvail, sysAvail)
            guard total > 0 else { return nil }
            return emitStereo(frames: Int(min(Int64(maxFrames), total)))
        }
    }

    private func drainMono(ring: ChannelRing, maxFrames: Int, stalled: Bool, force: Bool) -> AlignedAudioChunk? {
        let available = max(0, ring.endFrame - outputFrame)
        guard available > 0, force || stalled || available >= Int64(maxFrames) else { return nil }
        let frames = Int(min(Int64(maxFrames), available))
        guard frames > 0 else { return nil }
        let out = Array(ring.values(from: outputFrame, frames: frames))
        outputFrame += Int64(frames)
        micRing.consume(to: outputFrame)
        systemRing.consume(to: outputFrame)
        return AlignedAudioChunk(startFrame: outputFrame - Int64(frames), frames: frames, channels: 1, samples: out)
    }

    private func emitStereo(frames: Int) -> AlignedAudioChunk {
        let startFrame = outputFrame
        let mic = Array(micRing.values(from: startFrame, frames: frames))
        let sys = Array(systemRing.values(from: startFrame, frames: frames))
        var interleaved = [Float](repeating: 0, count: frames * 2)
        for (i, s) in mic.enumerated() { interleaved[i * 2] = s }
        for (i, s) in sys.enumerated() { interleaved[i * 2 + 1] = s }
        outputFrame += Int64(frames)
        micRing.consume(to: outputFrame)
        systemRing.consume(to: outputFrame)
        return AlignedAudioChunk(startFrame: startFrame, frames: frames, channels: 2, samples: interleaved)
    }

    private func isStalled(_ lastArrival: UInt64?, nowNanos: UInt64) -> Bool {
        let reference: UInt64
        if let last = lastArrival {
            reference = last
        } else {
            guard let epoch = epochNanos else { return false }
            reference = epoch
        }
        return nowNanos > reference + stallGraceNanos
    }

    private func anchorEpoch(_ arrivalNanos: UInt64, sampleCount: Int) {
        guard epochNanos == nil else { return }
        let span = UInt64(max(0, sampleCount)) &* 1_000_000_000 / UInt64(Self.sampleRate)
        epochNanos = arrivalNanos > span ? arrivalNanos - span : 0
    }

    private func estimatedStartFrame(_ arrivalNanos: UInt64, sampleCount: Int) -> Int64 {
        guard let epoch = epochNanos else { return 0 }
        let delta = arrivalNanos > epoch ? arrivalNanos - epoch : 0
        let endFrame = Int64(delta * 3 / 62_500)
        return endFrame - Int64(sampleCount)
    }

    private func trimBacklog(ring: inout ChannelRing, name: String) {
        let backlog = ring.endFrame - outputFrame
        guard backlog > Self.maxBacklogFrames else { return }
        let drop = backlog - Self.maxBacklogFrames
        ring.consume(to: ring.endFrame - Self.maxBacklogFrames)
        AppLogger.shared.log(category: .audio, message: "StereoAligner \(name) backlog exceeded 30 s; dropped \(drop) stale frames")
    }
}
