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

    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.settings = AppSettings()
        self.modelManager = ModelManager()
        self.dictationOrchestrator = DictationOrchestrator(settings: settings, modelManager: modelManager)
        self.meetingRecorder = MeetingRecorder(settings: settings, modelManager: modelManager)
        self.overlayController = OverlayController(settings: settings)

        dictationOrchestrator.meetingRecorder = meetingRecorder

        setupDictationCallbacks()
        setupMeetingCallbacks()
        setupNotifications()
    }

    public func start() throws {
        try dictationOrchestrator.start()
    }

    public func stop() {
        dictationOrchestrator.stop()
        overlayController.dismiss()
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
                self?.handleMeetingStateChange(state)
            }
        }

        meetingRecorder.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.overlayController.dismiss()
            }
        }

        meetingRecorder.onAudioLevel = { [weak self] level in
            DispatchQueue.main.async {
                self?.overlayController.updateAudioLevel(level)
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .startDictation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.dictationOrchestrator.state == .idle {
                    self.dictationOrchestrator.updateShortcuts()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .startMeeting)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
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
        switch state {
        case .idle:
            overlayController.showCompletionThenDismiss()
        case .recording:
            overlayController.show(state: .recording)
        case .transcribing:
            overlayController.updateState(.transcribing)
        case .saving:
            overlayController.showCompletionThenDismiss()
        case .error:
            overlayController.dismiss()
        }
    }
}
