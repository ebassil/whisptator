import Foundation

/// Streams aligned audio chunks to a session `.mp3` file with periodic fsync,
/// so a crash loses at most one flush window of audio.
///
/// All encoding happens on one serial queue (LAME is not thread-safe).
public final class LameStreamSink: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.whisptator.lame-stream-sink")
    private let encoder: MP3Encoder
    private let handle: FileHandle
    private let flushIntervalNanos: UInt64
    private var lastFlushNanos: UInt64 = 0
    private var bytesWritten = 0
    private var closed = false

    public private(set) var fileURL: URL

    public init(
        url: URL,
        sampleRate: Int,
        channels: Int,
        bitrate: Int = 256,
        quality: Int = 2,
        flushInterval: TimeInterval = 2.0
    ) throws {
        FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)
        guard let handle = FileHandle(forWritingAtPath: url.path) else {
            throw NSError(domain: "LameStreamSink", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open \(url.path) for writing"])
        }
        guard let encoder = MP3Encoder(sampleRate: sampleRate, channels: channels, bitrate: bitrate, quality: quality) else {
            try? handle.close()
            throw NSError(domain: "LameStreamSink", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not initialize LAME encoder"])
        }
        self.handle = handle
        self.encoder = encoder
        self.fileURL = url
        self.flushIntervalNanos = UInt64(max(0.25, flushInterval) * 1_000_000_000)
    }

    deinit {
        if !closed {
            try? handle.close()
        }
    }

    public var totalBytesWritten: Int {
        queue.sync { bytesWritten }
    }

    /// Resumes after every append enqueued before this call has completed.
    public func awaitPendingWrites() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { continuation.resume() }
        }
    }

    public func append(_ chunk: AlignedAudioChunk) {
        queue.async { [weak self] in
            guard let self, !self.closed else { return }
            let now = DispatchTime.now().uptimeNanoseconds
            let data = self.encoder.append(interleavedSamples: chunk.samples)
            self.write(data, nowNanos: now)
            self.maybeSynchronize(nowNanos: now)
        }
    }

    /// Periodic call (e.g. from the session clock) that flushes the encoder's
    /// internal frames and fsyncs; guarantees the on-disk audio lags the live
    /// stream by at most `flushInterval` when appends keep flowing.
    public func tick(nowNanos: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        queue.async { [weak self] in
            guard let self, !self.closed else { return }
            let data = self.encoder.flushGap()
            self.write(data, nowNanos: nowNanos)
            if nowNanos > self.lastFlushNanos + self.flushIntervalNanos {
                self.synchronize(nowNanos: nowNanos)
            }
        }
    }

    public func finish() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self, !self.closed else {
                    continuation.resume()
                    return
                }
                let tail = self.encoder.finish()
                self.handle.write(tail)
                self.bytesWritten += tail.count
                do {
                    try self.handle.synchronize()
                } catch {
                    AppLogger.shared.log(category: .audio, message: "Sink fsync on close failed: \(error.localizedDescription)")
                }
                try? self.handle.close()
                self.closed = true
                continuation.resume()
            }
        }
    }

    // MARK: - Private (queue-isolated)

    private func write(_ data: Data, nowNanos: UInt64) {
        guard !data.isEmpty else { return }
        handle.write(data)
        bytesWritten += data.count
    }

    private func synchronize(nowNanos: UInt64) {
        do {
            try handle.synchronize()
            lastFlushNanos = nowNanos
        } catch {
            AppLogger.shared.log(category: .audio, message: "Sink fsync failed: \(error.localizedDescription)")
        }
    }

    /// Called from the append path too, so bytes hit the OS even without a tick.
    private func maybeSynchronize(nowNanos: UInt64) {
        if nowNanos > lastFlushNanos + flushIntervalNanos {
            synchronize(nowNanos: nowNanos)
        }
    }
}
