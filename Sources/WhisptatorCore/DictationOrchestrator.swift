import Foundation
import AVFoundation

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

    private var currentState: DictationState = .idle {
        didSet { onStateChange?(currentState) }
    }

    public var state: DictationState { currentState }

    private var recordedBuffers: [AVAudioPCMBuffer] = []

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
        recordedBuffers = []
        currentState = .recording
        microphoneCapture.startCapture(deviceID: settings.selectedAudioDeviceID.isEmpty ? nil : settings.selectedAudioDeviceID)
    }

    private func stopRecordingAndTranscribe() {
        guard currentState == .recording else { return }
        currentState = .transcribing
        microphoneCapture.stopCapture()

        Task {
            await performTranscription()
        }
    }

    private func performTranscription() async {
        let allSamples = mergeBuffers(recordedBuffers)
        recordedBuffers = []

        guard !allSamples.isEmpty else {
            currentState = .idle
            return
        }

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

            currentState = .pasting
            pasteEngine.paste(cleanedText, mode: settings.pasteMode)
            currentState = .idle
        } catch {
            currentState = .error(error.localizedDescription)
            onError?(error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.currentState = .idle
            }
        }
    }

    private func mergeBuffers(_ buffers: [AVAudioPCMBuffer]) -> [Float] {
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
        // Handled by MeetingRecorder
    }
}

extension DictationOrchestrator: MicrophoneCaptureDelegate {
    public func microphoneCapture(_ capture: MicrophoneCapture, didCaptureAudio buffer: AVAudioPCMBuffer) {
        guard currentState == .recording else { return }
        recordedBuffers.append(buffer)
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
