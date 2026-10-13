import SwiftUI
import WhisptatorCore
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var coordinator: AppCoordinator

    private var isMeetingRecording: Bool {
        coordinator.meetingState == .recording
    }

    private var isMeetingActive: Bool {
        coordinator.meetingState == .recording || coordinator.meetingState == .finalizing
    }

    var body: some View {
        Menu {
            Button("Start Dictation") {
                NotificationCenter.default.post(name: .startDictation, object: nil)
            }
            Button(coordinator.meetingState == .idle ? "Start Meeting" : "Stop Meeting") {
                NotificationCenter.default.post(name: .startMeeting, object: nil)
            }
            .disabled(coordinator.meetingState == .finalizing)

            if isMeetingRecording {
                Text("● LIVE — meeting recording")
                    .disabled(true)
                Button(coordinator.micMuted ? "Unmute Microphone" : "Mute Microphone") {
                    coordinator.meetingRecorder.toggleMicMute()
                }
                if coordinator.meetingRecorder.state == .recording {
                    Button("Stop Meeting") {
                        Task { await coordinator.meetingRecorder.stopRecording() }
                    }
                }
            } else if coordinator.meetingState == .finalizing {
                Text("Finalizing — identifying speakers…")
                    .disabled(true)
            }

            Button("Show Live Transcript") {
                coordinator.panelController.presentCurrentSession()
            }

            Divider()
            SettingsLink()
        } label: {
            Label("Whisptator", systemImage: isMeetingActive ? "record.circle" : "mic.circle")
        }
    }
}
