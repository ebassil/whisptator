import Foundation

/// Watches a transcript file for appended data with a DispatchSource on the
/// file descriptor plus a 1 s polling fallback (network volumes may not emit
/// FSEvents). Reads only bytes after the saved offset; when the file shrinks
/// or its inode changes (atomic rename from the speaker relabel), reloads from
/// the beginning.
public final class TranscriptFileWatcher: @unchecked Sendable {
    public enum Change: Sendable, Equatable {
        case appended([String])
        case reloaded([String])
    }

    public var onChange: ((Change) -> Void)?

    private let url: URL
    private let queue: DispatchQueue
    private let pollInterval: TimeInterval

    private var fd: Int32 = -1
    private var offset: Int64 = 0
    private var source: DispatchSourceFileSystemObject?
    private var pollTimer: DispatchSourceTimer?
    private var pendingBytes = Data()
    private var isStopped = true

    public init(url: URL, queue: DispatchQueue = .main, pollInterval: TimeInterval = 1.0) {
        self.url = url
        self.queue = queue
        self.pollInterval = pollInterval
    }

    public func start() {
        queue.async { [weak self] in
            guard let self else { return }
            self.isStopped = false
            self.restartWatching(fromZero: true)
            self.startPollTimer()
        }
    }

    public func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.isStopped = true
            self.source?.cancel()
            self.source = nil
            self.pollTimer?.cancel()
            self.pollTimer = nil
            if self.fd >= 0 {
                close(self.fd)
                self.fd = -1
            }
        }
    }

    /// Re-attach the watcher to a (possibly different) transcript file.
    public func repoint(to newURL: URL) {
        queue.async { [weak self] in
            guard let self else { return }
            let fileURL = newURL
            self.pendingBytes = Data()
            self.offset = 0
            self.stopSource()
            self.restartWatching(url: fileURL, fromZero: true)
        }
    }

    // MARK: - Private (queue-isolated)

    private func startPollTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + pollInterval, repeating: pollInterval)
        timer.setEventHandler { [weak self] in
            guard let self, !self.isStopped else { return }
            if self.fd < 0 {
                self.restartWatching(fromZero: true)
            } else {
                self.checkForChange()
            }
        }
        timer.resume()
        pollTimer = timer
    }

    private func stopSource() {
        source?.cancel()
        source = nil
        if fd >= 0 {
            close(fd)
            fd = -1
        }
    }

    private func restartWatching(url: URL? = nil, fromZero: Bool) {
        let fileURL = url ?? self.url
        stopSource()
        guard fromZero else { return }
        openAndDrain(fileURL)
    }

    private func openAndDrain(_ fileURL: URL) {
        let newFD = open(fileURL.path, O_RDONLY)
        guard newFD >= 0 else {
            // File may not exist yet (session starts momentarily later); the
            // poll timer retries.
            return
        }
        fd = newFD
        offset = 0
        pendingBytes = Data()

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename],
            queue: queue
        )
        src.setEventHandler { [weak self] in
            guard let self, !self.isStopped else { return }
            let flags = self.source?.data ?? []
            if flags.contains(.delete) || flags.contains(.rename) {
                // Underlying file replaced (atomic rename) or deleted. Reopen
                // the current path and reload fully.
                let currentURL = fileURL
                self.stopSource()
                self.openAndDrain(currentURL)
                self.emitReload()
            } else {
                self.checkForChange()
            }
        }
        src.setCancelHandler { }
        source = src
        src.resume()

        // Emit anything already present.
        let lines = readNewLines(wholeFile: true)
        if !lines.isEmpty {
            onChange?(.reloaded(lines))
        }
    }

    private func checkForChange() {
        guard fd >= 0 else {
            openAndDrain(url)
            return
        }
        var statBuf = stat()
        if fstat(fd, &statBuf) == 0, statBuf.st_size < offset {
            // Shrunk via replacement through the same fd (shouldn't happen for
            // rename, but is the spec'd shrink signal).
            offset = 0
            pendingBytes = Data()
            emitReload()
            return
        }
        let lines = readNewLines(wholeFile: false)
        if !lines.isEmpty {
            onChange?(.appended(lines))
        }
    }

    private func emitReload() {
        offset = 0
        pendingBytes = Data()
        let lines = readNewLines(wholeFile: true)
        onChange?(.reloaded(lines))
    }

    /// Decodes complete lines since the saved offset; a trailing partial line
    /// (no newline yet) stays in `pendingBytes`.
    private func readNewLines(wholeFile: Bool) -> [String] {
        guard fd >= 0 else { return [] }
        let start: Int64
        if wholeFile {
            start = 0
            pendingBytes = Data()
        } else {
            start = offset
        }
        lseek(fd, start, SEEK_SET)

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let n = read(fd, &buffer, buffer.count)
            if n <= 0 { break }
            data.append(contentsOf: buffer[0..<n])
        }
        offset = start + Int64(data.count)

        pendingBytes.append(data)
        var completed: [String] = []
        while let newlineIndex = pendingBytes.firstIndex(of: 0x0A) {
            let lineData = pendingBytes.subdata(in: pendingBytes.startIndex..<newlineIndex)
            pendingBytes.removeSubrange(pendingBytes.startIndex...newlineIndex)
            if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                completed.append(line)
            }
        }
        return completed
    }
}
