@preconcurrency import AVFoundation

public enum DictationState: Sendable, Equatable {
    case idle
    case recording
    case transcribing
    case pasting
    case error(String)

    public static func == (lhs: DictationState, rhs: DictationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording), (.transcribing, .transcribing), (.pasting, .pasting):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

public final class DictationOrchestrator: @unchecked Sendable {
    private let settings: AppSettings
    private let hotkeyMonitor: HotkeyMonitor
    private let microphoneCapture: MicrophoneCapture
    private let transcriptionEngine: TranscriptionEngine
    private let textCleanupPipeline: TextCleanupPipeline
    private let pasteEngine: PasteEngine

    public var onStateChange: ((DictationState) -> Void)?
    public var onError: ((Error) -> Void)?
    public var meetingRecorder: MeetingRecorder?
    public var onAudioLevel: ((Float) -> Void)?

    private var currentState: DictationState = .idle {
        didSet { onStateChange?(currentState) }
    }

    public var state: DictationState { currentState }

    private var recordedBuffers: [AVAudioPCMBuffer] = []
    private let bufferQueue = DispatchQueue(label: "com.whisptator.buffer")

    public init(
        settings: AppSettings,
        modelManager: ModelManager
    ) {
        self.settings = settings
        self.hotkeyMonitor = HotkeyMonitor(settings: settings)
        self.microphoneCapture = MicrophoneCapture()
        self.transcriptionEngine = TranscriptionEngine(modelManager: modelManager)
        self.textCleanupPipeline = TextCleanupPipeline()
        self.pasteEngine = PasteEngine()

        self.hotkeyMonitor.delegate = self
        self.microphoneCapture.delegate = self
    }

    public func start() throws {
        try hotkeyMonitor.start()
    }

    public func stop() {
        hotkeyMonitor.stop()
        if microphoneCapture.isRecording {
            microphoneCapture.stopCapture()
        }
        currentState = .idle
    }

    public func updateShortcuts() {
        hotkeyMonitor.updateShortcuts(settings: settings)
    }

    private func startRecording() {
        guard currentState == .idle else { return }
        bufferQueue.sync { recordedBuffers.removeAll() }
        currentState = .recording
        AppLogger.shared.log(category: .dictation, message: "Dictation recording started")
        microphoneCapture.startCapture(deviceID: settings.selectedAudioDeviceID.isEmpty ? nil : settings.selectedAudioDeviceID)
    }

    private func stopRecordingAndTranscribe() {
        guard currentState == .recording else { return }
        AppLogger.shared.log(category: .dictation, message: "Dictation recording stopping")

        microphoneCapture.stopCapture { [weak self] in
            guard let self else { return }
            self.currentState = .transcribing
            AppLogger.shared.log(category: .dictation, message: "Dictation recording stopped, starting transcription")

            let audioSaver = AudioFileSaver()
            let saveAudio = self.settings.saveAudioFiles
            let audioDir = self.settings.audioSaveLocation
            let audioSettings = self.settings.audioSaveSettings

            Task {
                if saveAudio {
                    let allSamples = self.snapshotRecordedBuffers()
                    if let path = audioSaver.saveAudioFile(samples: allSamples, sampleRate: 48000, to: audioDir, settings: audioSettings) {
                        AppLogger.shared.log(category: .dictation, message: "Audio saved to: \(path)")
                    }
                }
                await self.performTranscription()
            }
        }
    }

    private func performTranscription() async {
        let allSamples = snapshotRecordedBuffers()
        bufferQueue.sync { recordedBuffers.removeAll() }

        guard !allSamples.isEmpty else {
            AppLogger.shared.log(category: .dictation, message: "Empty audio, skipping transcription")
            currentState = .idle
            return
        }

        AppLogger.shared.log(category: .dictation, message: "Transcription started (samples: \(allSamples.count))")

        let convertedSamples: [Float]
        if let firstBuffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!,
            frameCapacity: AVAudioFrameCount(allSamples.count)
        ) {
            firstBuffer.frameLength = AVAudioFrameCount(allSamples.count)
            if let channelData = firstBuffer.floatChannelData?[0] {
                for (i, sample) in allSamples.enumerated() {
                    channelData[i] = sample
                }
            }
            if let converted = MicrophoneCapture.convertTo16kHzMono(firstBuffer) {
                convertedSamples = Array(UnsafeBufferPointer(start: converted.floatChannelData?[0], count: Int(converted.frameLength)))
            } else {
                convertedSamples = allSamples
            }
        } else {
            convertedSamples = allSamples
        }

        do {
            let rawText = try await transcriptionEngine.transcribe(
                audio: convertedSamples,
                sampleRate: 16000,
                language: settings.language == "auto" ? nil : settings.language
            )

            let cleanedText = textCleanupPipeline.process(
                rawText,
                mode: settings.cleanupMode,
                fillerWords: settings.fillerWords,
                wordReplacements: settings.wordReplacements,
                snippets: settings.snippets
            )

            AppLogger.shared.log(category: .dictation, message: "Transcription completed (chars: \(cleanedText.count))")
            currentState = .pasting
            AppLogger.shared.log(category: .dictation, message: "Pasted text (mode: \(settings.pasteMode.rawValue), chars: \(cleanedText.count))")
            pasteEngine.paste(cleanedText, mode: settings.pasteMode)
            currentState = .idle
        } catch {
            AppLogger.shared.log(category: .dictation, message: "Transcription failed: \(error.localizedDescription)")
            currentState = .error(error.localizedDescription)
            onError?(error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.currentState = .idle
            }
        }
    }

    private func snapshotRecordedBuffers() -> [Float] {
        let buffers = bufferQueue.sync { recordedBuffers }
        var allSamples: [Float] = []
        for buffer in buffers {
            if let channelData = buffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
                allSamples.append(contentsOf: samples)
            }
        }
        return allSamples
    }
}

extension DictationOrchestrator: HotkeyMonitorDelegate {
    public func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectPushToTalkDown shortcut: ShortcutKeyCode) {
        startRecording()
    }

    public func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectPushToTalkUp shortcut: ShortcutKeyCode) {
        stopRecordingAndTranscribe()
    }

    public func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectHandsFreeTap shortcut: ShortcutKeyCode) {
        if currentState == .idle {
            startRecording()
        } else if currentState == .recording {
            stopRecordingAndTranscribe()
        }
    }

    public func hotkeyMonitor(_ monitor: HotkeyMonitor, didDetectMeetingToggle shortcut: ShortcutKeyCode) {
        guard let meetingRecorder else { return }
        if meetingRecorder.state == .idle {
            Task { await meetingRecorder.startRecording() }
        } else if meetingRecorder.state == .recording {
            Task { await meetingRecorder.stopRecording() }
        }
    }
}

extension DictationOrchestrator: MicrophoneCaptureDelegate {
    public func microphoneCapture(_ capture: MicrophoneCapture, didCaptureAudio buffer: AVAudioPCMBuffer) {
        bufferQueue.sync { recordedBuffers.append(buffer) }

        if let channelData = buffer.floatChannelData?[0] {
            let frameLength = Int(buffer.frameLength)
            var sumOfSquares: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sumOfSquares += sample * sample
            }
            let rms = sqrt(sumOfSquares / max(1, Float(frameLength)))
            let normalizedLevel = min(rms * 5, 1.0)
            onAudioLevel?(normalizedLevel)
        }
    }

    public func microphoneCaptureDidStart(_ capture: MicrophoneCapture) {}

    public func microphoneCaptureDidStop(_ capture: MicrophoneCapture) {}

    public func microphoneCapture(_ capture: MicrophoneCapture, didFailWithError error: Error) {
        currentState = .error(error.localizedDescription)
        onError?(error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.currentState = .idle
        }
    }
}
