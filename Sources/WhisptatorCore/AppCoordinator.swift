import Foundation
import Combine

public extension Notification.Name {
    static let startDictation = Notification.Name("startDictation")
    static let startMeeting = Notification.Name("startMeeting")
}

@MainActor
public final class AppCoordinator: ObservableObject {
    public let settings: AppSettings
    public let modelManager: ModelManager
    public let dictationOrchestrator: DictationOrchestrator
    public let meetingRecorder: MeetingRecorder
    public let overlayController: OverlayController
    public let panelController: LiveTranscriptPanelController
    public let diarizationController: DiarizationModelController

    @Published public private(set) var meetingState: MeetingState = .idle
    @Published public private(set) var micMuted = false

    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.settings = AppSettings()
        self.modelManager = ModelManager(selectedModelId: settings.selectedModelId)
        self.dictationOrchestrator = DictationOrchestrator(settings: settings, modelManager: modelManager)
        self.meetingRecorder = MeetingRecorder(settings: settings, modelManager: modelManager)
        self.overlayController = OverlayController(settings: settings)
        self.panelController = LiveTranscriptPanelController(settings: settings)
        self.diarizationController = DiarizationModelController(settings: settings)

        dictationOrchestrator.meetingRecorder = meetingRecorder
        panelController.attach(recorder: meetingRecorder)

        settings.onSettingChange = { [weak self] key in
            AppLogger.shared.log(category: .settings, message: "Setting changed: \(key)")
            if key.hasSuffix("Shortcut") {
                Task { @MainActor in
                    self?.dictationOrchestrator.updateShortcuts()
                }
            }
        }

        AppLogger.shared.loadFrom(settings: settings)

        setupDictationCallbacks()
        setupMeetingCallbacks()
        setupNotifications()

        if settings.speakerIdentificationEnabled {
            Task { await diarizationController.refresh() }
        }
    }

    public func start() throws {
        AppLogger.shared.log(category: .system, message: "AppCoordinator started")
        try dictationOrchestrator.start()
        Task { await modelManager.loadModelOffline() }
    }

    public func stop() {
        AppLogger.shared.log(category: .system, message: "AppCoordinator stopped")
        dictationOrchestrator.stop()
        overlayController.dismiss()
        panelController.shutdown()
    }

    private func setupDictationCallbacks() {
        dictationOrchestrator.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleDictationStateChange(state)
            }
        }

        dictationOrchestrator.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.overlayController.dismiss()
            }
        }

        dictationOrchestrator.onAudioLevel = { [weak self] level in
            DispatchQueue.main.async {
                self?.overlayController.updateAudioLevel(level)
            }
        }
    }

    private func setupMeetingCallbacks() {
        meetingRecorder.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.meetingState = state
                self?.handleMeetingStateChange(state)
            }
        }

        meetingRecorder.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.overlayController.dismiss()
            }
            AppLogger.shared.log(category: .meeting, message: "Meeting error: \(error.localizedDescription)")
        }

        meetingRecorder.onAudioLevel = { [weak self] level in
            DispatchQueue.main.async {
                self?.overlayController.updateAudioLevel(level)
            }
        }

        meetingRecorder.onMicMuteChange = { [weak self] muted in
            DispatchQueue.main.async {
                self?.micMuted = muted
            }
        }

        meetingRecorder.onSessionStarted = { [weak self] info in
            DispatchQueue.main.async {
                self?.panelController.sessionDidStart(info)
            }
        }

        meetingRecorder.diarizerProvider = { [weak self] in
            guard let self else { return MeetingRecorder.DiarizerSetup(diarizer: nil) }
            if await self.diarizationController.ensureModels() {
                if let diarizer = await self.diarizationController.makeDiarizer() {
                    return MeetingRecorder.DiarizerSetup(diarizer: diarizer)
                }
                return MeetingRecorder.DiarizerSetup(diarizer: nil, message: "Speaker identification models could not be loaded.")
            }
            let message = self.diarizationController.failureMessage
                ?? "Speaker identification was not applied: diarization models could not be downloaded."
            return MeetingRecorder.DiarizerSetup(diarizer: nil, message: message)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .startDictation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                AppLogger.shared.log(category: .system, message: "Notification: startDictation")
                if self.dictationOrchestrator.state == .idle {
                    self.dictationOrchestrator.updateShortcuts()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .startMeeting)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                AppLogger.shared.log(category: .system, message: "Notification: startMeeting")
                Task {
                    if self.meetingRecorder.state == .idle {
                        await self.meetingRecorder.startRecording()
                    } else if self.meetingRecorder.state == .recording {
                        await self.meetingRecorder.stopRecording()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func handleDictationStateChange(_ state: DictationState) {
        AppLogger.shared.log(category: .system, message: "Dictation state: \(state)")
        switch state {
        case .idle:
            overlayController.showCompletionThenDismiss()
        case .recording:
            overlayController.show(state: .recording)
        case .transcribing:
            overlayController.updateState(.transcribing)
        case .pasting:
            overlayController.showCompletionThenDismiss()
        case .error:
            overlayController.dismiss()
        }
    }

    private func handleMeetingStateChange(_ state: MeetingState) {
        AppLogger.shared.log(category: .system, message: "Meeting state: \(state)")
        switch state {
        case .idle:
            overlayController.showCompletionThenDismiss()
        case .recording:
            overlayController.show(state: .recording)
        case .finalizing:
            overlayController.updateState(.transcribing)
        case .error:
            overlayController.dismiss()
        }
    }
}
