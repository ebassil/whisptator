import Foundation
import AVFoundation

public enum MeetingState: Sendable, Equatable {
    case idle
    case recording
    case finalizing
    case error(String)
}

/// Session file bundle: transcript and audio share a stem in the save directory
/// snapshotted at start.
public struct MeetingSessionInfo: Sendable {
    public let transcriptURL: URL
    public let audioURL: URL
}

/// Orchestrates a live meeting session: capture -> aligner -> (mp3 sink, VAD
/// segmenter) -> chunk queue -> transcriber -> transcript writer, with states
/// `idle -> recording -> finalizing? -> idle`.
public final class MeetingRecorder: @unchecked Sendable {
    private let settings: AppSettings
    private let systemAudioCapture: SystemAudioCapture
    private let microphoneCapture: MicrophoneCapture
    private let transcriptionEngine: TranscriptionEngine
    private let textCleanupPipeline = TextCleanupPipeline()

    public var onStateChange: ((MeetingState) -> Void)?
    public var onError: ((Error) -> Void)?
    public var onAudioLevel: ((Float) -> Void)?
    public var onMicMuteChange: ((Bool) -> Void)?
    public var onSessionStarted: ((MeetingSessionInfo) -> Void)?
    public var onSessionEnded: ((MeetingSessionInfo) -> Void)?

    /// Optional provider consulted after stop when speaker identification is
    /// on. Returning nil (models unavailable) must carry a user-visible `message`.
    public struct DiarizerSetup: Sendable {
        public let diarizer: (any SpeakerDiarizer)?
        public let message: String?
        public init(diarizer: (any SpeakerDiarizer)?, message: String? = nil) {
            self.diarizer = diarizer
            self.message = message
        }
    }
    public var diarizerProvider: (() async -> DiarizerSetup)?

    private var currentState: MeetingState = .idle {
        didSet { onStateChange?(currentState) }
    }
    public var state: MeetingState { currentState }

    private var pipeline: LiveMeetingPipeline?
    private var pollTimer: DispatchSourceTimer?
    private let pollQueue = DispatchQueue(label: "com.whisptator.meeting.timer")

    public init(settings: AppSettings, modelManager: ModelManager) {
        self.settings = settings
        self.systemAudioCapture = SystemAudioCapture()
        self.microphoneCapture = MicrophoneCapture()
        self.transcriptionEngine = TranscriptionEngine(modelManager: modelManager)

        self.systemAudioCapture.delegate = self
        self.microphoneCapture.delegate = self
    }

    public var micMuted: Bool { pipeline?.micMuted ?? false }
    public var activeSession: MeetingSessionInfo? {
        guard let pipeline else { return nil }
        return MeetingSessionInfo(transcriptURL: pipeline.transcriptURL, audioURL: pipeline.audioURL)
    }
    public var currentElapsedFrames: Int64 { pipeline?.currentFrame ?? 0 }

    // MARK: - Lifecycle

    public func startRecording() async {
        guard currentState == .idle, pipeline == nil else { return }

        let sourceSnapshot = settings.meetingAudioSource
        let stem = Self.sessionStem(for: Date())
        let config = LiveMeetingPipeline.Config(
            saveDirectory: settings.meetingSaveLocation,
            audioSource: sourceSnapshot,
            mp3Bitrate: settings.mp3Bitrate,
            sessionStem: stem
        )

        let pipeline: LiveMeetingPipeline
        do {
            pipeline = try LiveMeetingPipeline(
                config: config,
                transcriber: WhisperChunkTranscriber(engine: transcriptionEngine),
                lineProcessor: makeLineProcessor()
            )
        } catch {
            AppLogger.shared.log(category: .meeting, message: "Meeting start failed: \(error.localizedDescription)")
            currentState = .error(error.localizedDescription)
            onError?(error)
            return
        }

        pipeline.onAudioLevel = { [weak self] level in
            self?.onAudioLevel?(level)
        }
        pipeline.startTranscribing()
        self.pipeline = pipeline
        currentState = .recording
        AppLogger.shared.log(category: .meeting, message: "Meeting recording started (source: \(sourceSnapshot.rawValue), stem: \(stem))")

        do {
            switch sourceSnapshot {
            case .systemAndMicrophone:
                try await systemAudioCapture.startCapture()
                microphoneCapture.startCapture(deviceID: settings.selectedAudioDeviceID.isEmpty ? nil : settings.selectedAudioDeviceID)
            case .microphoneOnly:
                microphoneCapture.startCapture(deviceID: settings.selectedAudioDeviceID.isEmpty ? nil : settings.selectedAudioDeviceID)
            case .systemOnly:
                try await systemAudioCapture.startCapture()
            }
        } catch {
            AppLogger.shared.log(category: .meeting, message: "Meeting capture failed: \(error.localizedDescription)")
            await pipeline.cancel()
            self.pipeline = nil
            currentState = .error(error.localizedDescription)
            onError?(error)
            return
        }

        startPollTimer()
        onSessionStarted?(MeetingSessionInfo(transcriptURL: pipeline.transcriptURL, audioURL: pipeline.audioURL))
    }

    public func stopRecording() async {
        guard currentState == .recording, let pipeline else { return }
        AppLogger.shared.log(category: .meeting, message: "Meeting recording stopping (pending chunks: \(pipeline.queue.pendingCount))")

        stopPollTimer()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            microphoneCapture.stopCapture {
                continuation.resume()
            }
        }
        await systemAudioCapture.stopCapture()

        let pending = pipeline.queue.pendingCount
        let drainTimeout = max(30.0, Double(pending) * 20.0)
        _ = await pipeline.finalize(drainTimeout: drainTimeout)

        let sessionInfo = MeetingSessionInfo(transcriptURL: pipeline.transcriptURL, audioURL: pipeline.audioURL)

        if settings.speakerIdentificationEnabled {
            currentState = .finalizing
            let setup = await diarizerProvider?() ?? DiarizerSetup(diarizer: nil)
            if let diarizer = setup.diarizer, await diarizer.isReady {
                do {
                    let segments = try await diarizer.diarize(mp3URL: pipeline.audioURL)
                    let relabeled = try TranscriptRelabeler.relabel(
                        transcriptURL: pipeline.transcriptURL,
                        audioURL: pipeline.audioURL,
                        segments: segments
                    )
                    AppLogger.shared.log(category: .meeting, message: "Speaker labels applied to \(relabeled.path)")
                } catch {
                    AppLogger.shared.log(category: .meeting, message: "Diarization failed; live transcript kept: \(error.localizedDescription)")
                    onError?(DiarizationFailure(underlying: error))
                }
            } else {
                let message = setup.message ?? "Speaker identification was not applied: diarization models are unavailable."
                AppLogger.shared.log(category: .meeting, message: message)
                onError?(DiarizationUnavailable(message: message))
            }
            currentState = .idle
        } else {
            currentState = .idle
        }

        applyRetention()
        onSessionEnded?(sessionInfo)
        self.pipeline = nil
    }

    private func applyRetention() {
        guard let audioURL = pipeline?.audioURL else { return }
        switch settings.meetingRetention {
        case .deleteAfterTranscription:
            try? FileManager.default.removeItem(at: audioURL)
            AppLogger.shared.log(category: .meeting, message: "Meeting audio deleted per retention policy: \(audioURL.lastPathComponent)")
        case .autoDeleteAfterDays:
            let dir = settings.meetingSaveLocation
            TranscriptSaver().cleanupOldAudioFiles(in: dir, olderThanDays: settings.meetingRetentionDays)
        case .keep:
            break
        }
    }

    /// Toggles mic mute for the active session (no effect when idle).
    public func toggleMicMute() {
        guard currentState == .recording, let pipeline else { return }
        let muted = pipeline.toggleMicMute()
        onMicMuteChange?(muted)
    }

    private func makeLineProcessor() -> @Sendable (String) -> String {
        let settings = self.settings
        let pipeline = self.textCleanupPipeline
        let modeSnapshot = settings.cleanupMode
        return { raw in
            guard modeSnapshot == .clean else { return raw }
            return pipeline.process(
                raw,
                mode: modeSnapshot,
                fillerWords: settings.fillerWords,
                wordReplacements: settings.wordReplacements,
                snippets: settings.snippets
            )
        }
    }

    private static func sessionStem(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "meeting_\(formatter.string(from: date))"
    }

    private func startPollTimer() {
        let timer = DispatchSource.makeTimerSource(queue: pollQueue)
        timer.schedule(deadline: .now() + 0.5, repeating: 0.5)
        timer.setEventHandler { [weak self] in
            self?.pipeline?.poll()
        }
        timer.resume()
        pollTimer = timer
    }

    private func stopPollTimer() {
        pollTimer?.cancel()
        pollTimer = nil
    }
}

/// Marker error so the UI can distinguish "labels were not applied" from a
/// session failure. The live transcript and audio remain valid.
public struct DiarizationFailure: Error, LocalizedError {
    public let underlying: Error
    public var errorDescription: String? {
        "Speaker identification failed; the transcript was saved without labels. (\(underlying.localizedDescription))"
    }
}

public struct DiarizationUnavailable: Error, LocalizedError {
    public let message: String
    public var errorDescription: String? { message }
}

// MARK: - Capture delegates

extension MeetingRecorder: SystemAudioCaptureDelegate {
    public func systemAudioCapture(_ capture: SystemAudioCapture, didCaptureAudio buffer: AVAudioPCMBuffer) {
        guard let samples = Self.extractMonoSamples(from: buffer) else { return }
        pipeline?.ingestSystem(samples, arrivalNanos: DispatchTime.now().uptimeNanoseconds)
    }

    public func systemAudioCaptureDidStart(_ capture: SystemAudioCapture) {}

    public func systemAudioCaptureDidStop(_ capture: SystemAudioCapture) {}

    public func systemAudioCapture(_ capture: SystemAudioCapture, didFailWithError error: Error) {
        AppLogger.shared.log(category: .meeting, message: "System audio failed mid-session: \(error.localizedDescription)")
        Task { await self.failSession(error) }
    }

    private func failSession(_ error: Error) async {
        guard currentState == .recording, let pipeline else { return }
        stopPollTimer()
        microphoneCapture.stopCapture()
        await systemAudioCapture.stopCapture()
        await pipeline.cancel()
        self.pipeline = nil
        currentState = .error(error.localizedDescription)
        onError?(error)
    }
}

extension MeetingRecorder: MicrophoneCaptureDelegate {
    public func microphoneCapture(_ capture: MicrophoneCapture, didCaptureAudio buffer: AVAudioPCMBuffer) {
        guard let samples = Self.extractMonoSamples(from: buffer) else { return }
        pipeline?.ingestMic(samples, arrivalNanos: DispatchTime.now().uptimeNanoseconds)
    }

    public func microphoneCaptureDidStart(_ capture: MicrophoneCapture) {}

    public func microphoneCaptureDidStop(_ capture: MicrophoneCapture) {}

    public func microphoneCapture(_ capture: MicrophoneCapture, didFailWithError error: Error) {
        AppLogger.shared.log(category: .meeting, message: "Microphone failed mid-session: \(error.localizedDescription)")
        Task { await self.failSession(error) }
    }
}

private extension MeetingRecorder {
    static func extractMonoSamples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return nil }
        if buffer.format.channelCount > 1 {
            var out = [Float](repeating: 0, count: frameLength)
            for ch in 0..<Int(buffer.format.channelCount) {
                let ptr = channelData[ch]
                for i in 0..<frameLength { out[i] += ptr[i] / Float(buffer.format.channelCount) }
            }
            return out
        }
        return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
    }
}
