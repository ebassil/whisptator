import Foundation
import AVFoundation

public enum MeetingState: Sendable, Equatable {
    case idle
    case recording
    case transcribing
    case saving
    case error(String)

    public static func == (lhs: MeetingState, rhs: MeetingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording), (.transcribing, .transcribing), (.saving, .saving):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

public final class MeetingRecorder: @unchecked Sendable {
    private let settings: AppSettings
    private let systemAudioCapture: SystemAudioCapture
    private let microphoneCapture: MicrophoneCapture
    private let audioMixer: AudioMixer
    private let transcriptionEngine: TranscriptionEngine
    private let transcriptSaver: TranscriptSaver

    public var onStateChange: ((MeetingState) -> Void)?
    public var onError: ((Error) -> Void)?
    public var onAudioLevel: ((Float) -> Void)?

    private var currentState: MeetingState = .idle {
        didSet { onStateChange?(currentState) }
    }

    public var state: MeetingState { currentState }

    private var mixedBuffers: [AVAudioPCMBuffer] = []
    private let lock = NSLock()

    public init(settings: AppSettings, modelManager: ModelManager) {
        self.settings = settings
        self.systemAudioCapture = SystemAudioCapture()
        self.microphoneCapture = MicrophoneCapture()
        self.audioMixer = AudioMixer()
        self.transcriptionEngine = TranscriptionEngine(modelManager: modelManager)
        self.transcriptSaver = TranscriptSaver()

        self.systemAudioCapture.delegate = self
        self.microphoneCapture.delegate = self
    }

    public func startRecording() async {
        guard currentState == .idle else { return }
        currentState = .recording
        mixedBuffers = []
        AppLogger.shared.log(category: .meeting, message: "Meeting recording started (source: \(settings.meetingAudioSource.rawValue))")

        do {
            try audioMixer.start()

            switch settings.meetingAudioSource {
            case .systemAndMicrophone:
                try await systemAudioCapture.startCapture()
                microphoneCapture.startCapture(deviceID: settings.selectedAudioDeviceID.isEmpty ? nil : settings.selectedAudioDeviceID)
            case .microphoneOnly:
                microphoneCapture.startCapture(deviceID: settings.selectedAudioDeviceID.isEmpty ? nil : settings.selectedAudioDeviceID)
            case .systemOnly:
                try await systemAudioCapture.startCapture()
            }
        } catch {
            AppLogger.shared.log(category: .meeting, message: "Meeting error: \(error.localizedDescription)")
            currentState = .error(error.localizedDescription)
            onError?(error)
        }
    }

    public func stopRecording() async {
        guard currentState == .recording else { return }
        currentState = .transcribing
        AppLogger.shared.log(category: .meeting, message: "Meeting recording stopped, starting transcription")

        microphoneCapture.stopCapture()
        await systemAudioCapture.stopCapture()
        audioMixer.stop()

        do {
            let allSamples = mergeBuffers(mixedBuffers)
            mixedBuffers = []

            guard !allSamples.isEmpty else {
                currentState = .idle
                return
            }

            let text = try await transcriptionEngine.transcribe(audio: allSamples, sampleRate: 48000)
            AppLogger.shared.log(category: .meeting, message: "Meeting transcription completed (chars: \(text.count))")

            currentState = .saving
            transcriptSaver.saveTranscript(text, to: settings.meetingSaveLocation)
            AppLogger.shared.log(category: .meeting, message: "Transcript saved to: \(settings.meetingSaveLocation)")

            currentState = .idle
        } catch {
            AppLogger.shared.log(category: .meeting, message: "Meeting error: \(error.localizedDescription)")
            currentState = .error(error.localizedDescription)
            onError?(error)
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

    private func addBuffer(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        mixedBuffers.append(buffer)
        lock.unlock()

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
}

extension MeetingRecorder: SystemAudioCaptureDelegate {
    public func systemAudioCapture(_ capture: SystemAudioCapture, didCaptureAudio buffer: AVAudioPCMBuffer) {
        guard currentState == .recording else { return }
        addBuffer(buffer)
    }

    public func systemAudioCaptureDidStart(_ capture: SystemAudioCapture) {}

    public func systemAudioCaptureDidStop(_ capture: SystemAudioCapture) {}

    public func systemAudioCapture(_ capture: SystemAudioCapture, didFailWithError error: Error) {
        currentState = .error(error.localizedDescription)
        onError?(error)
    }
}

extension MeetingRecorder: MicrophoneCaptureDelegate {
    public func microphoneCapture(_ capture: MicrophoneCapture, didCaptureAudio buffer: AVAudioPCMBuffer) {
        guard currentState == .recording else { return }
        addBuffer(buffer)
    }

    public func microphoneCaptureDidStart(_ capture: MicrophoneCapture) {}

    public func microphoneCaptureDidStop(_ capture: MicrophoneCapture) {}

    public func microphoneCapture(_ capture: MicrophoneCapture, didFailWithError error: Error) {
        currentState = .error(error.localizedDescription)
        onError?(error)
    }
}
