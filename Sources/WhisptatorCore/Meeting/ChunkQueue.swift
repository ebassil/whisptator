import Foundation

/// Bounded, FIFO-ordered queue of pending transcription chunks.
/// Overflow drops the oldest untranscribed chunk (audio is never dropped).
public final class ChunkQueue: @unchecked Sendable {
    public let capacity: Int
    private let lock = NSLock()
    private var segments: [SpeechSegment] = []
    private var dequeueWaiters: [CheckedContinuation<SpeechSegment?, Never>] = []
    private var drainBoxes: [DrainBox] = []
    private var activeWork = 0
    private var closed = false

    public init(capacity: Int = 60) {
        self.capacity = capacity
    }

    public var pendingCount: Int {
        lock.lock(); defer { lock.unlock() }
        return segments.count
    }

    /// Enqueue a segment in order. Returns the dropped segment when the queue was full.
    @discardableResult
    public func enqueue(_ segment: SpeechSegment) -> SpeechSegment? {
        lock.lock()
        guard !closed else {
            lock.unlock()
            return segment
        }
        var dropped: SpeechSegment?
        if segments.count >= capacity {
            dropped = segments.removeFirst()
        }
        segments.append(segment)

        var handed: CheckedContinuation<SpeechSegment?, Never>?
        var handedSegment: SpeechSegment?
        if let waiter = dequeueWaiters.first {
            dequeueWaiters.removeFirst()
            handedSegment = segments.removeFirst()
            activeWork += 1
            handed = waiter
        }
        let droppedInfo = dropped
        lock.unlock()

        if let droppedInfo {
            AppLogger.shared.log(
                category: .transcription,
                message: "Chunk queue full (\(capacity)); dropped oldest chunk [frame \(droppedInfo.startFrame)-\(droppedInfo.endFrame)] - transcript gap expected, audio file unaffected"
            )
        }
        handed?.resume(returning: handedSegment)
        return droppedInfo
    }

    /// Await the next segment in order; `nil` when closed and no work remains.
    public func dequeue() async -> SpeechSegment? {
        await withCheckedContinuation { (cont: CheckedContinuation<SpeechSegment?, Never>) in
            lock.lock()
            if !segments.isEmpty {
                let segment = segments.removeFirst()
                activeWork += 1
                lock.unlock()
                cont.resume(returning: segment)
                return
            }
            if closed {
                lock.unlock()
                cont.resume(returning: nil)
                return
            }
            dequeueWaiters.append(cont)
            lock.unlock()
        }
    }

    /// Worker calls this after finishing (success or failure) one segment.
    public func completeWork() {
        lock.lock()
        activeWork = max(0, activeWork - 1)
        let boxes = takeSettledDrainBoxes()
        lock.unlock()
        for box in boxes { box.resume(returning: true) }
    }

    /// Resolves `true` once the queue has no pending or in-flight work, `false` on timeout.
    public func waitForDrain(timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            let box = DrainBox(continuation: cont)
            lock.lock()
            let settled = segments.isEmpty && activeWork == 0
            if settled {
                let boxes = drainBoxes
                drainBoxes = []
                lock.unlock()
                for b in boxes { b.resume(returning: true) }
                box.resume(returning: true)
                return
            }
            drainBoxes.append(box)
            lock.unlock()

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(max(0.01, timeout) * 1_000_000_000))
                self?.expireDrainBox(box)
            }
        }
    }

    /// No further segments will arrive. Pending untranscribed segments are discarded.
    public func close() {
        lock.lock()
        closed = true
        let waiters = dequeueWaiters
        dequeueWaiters = []
        segments = []
        let boxes = takeSettledDrainBoxes()
        lock.unlock()
        for w in waiters { w.resume(returning: nil) }
        for box in boxes { box.resume(returning: true) }
    }

    // MARK: - Private

    /// Caller must hold the lock.
    private func takeSettledDrainBoxes() -> [DrainBox] {
        guard segments.isEmpty && activeWork == 0 else { return [] }
        let boxes = drainBoxes
        drainBoxes = []
        return boxes
    }

    private func expireDrainBox(_ box: DrainBox) {
        lock.lock()
        if let idx = drainBoxes.firstIndex(where: { $0.id == box.id }) {
            drainBoxes.remove(at: idx)
            lock.unlock()
            box.resume(returning: false)
        } else {
            lock.unlock()
        }
    }

    private final class DrainBox {
        let id = UUID()
        private let continuation: CheckedContinuation<Bool, Never>
        private let resumeLock = NSLock()
        private var resumed = false

        init(continuation: CheckedContinuation<Bool, Never>) {
            self.continuation = continuation
        }

        func resume(returning value: Bool) {
            resumeLock.lock()
            guard !resumed else { resumeLock.unlock(); return }
            resumed = true
            resumeLock.unlock()
            continuation.resume(returning: value)
        }
    }
}
