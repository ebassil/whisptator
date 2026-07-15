import SwiftUI
import WhisptatorCore
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Menu {
            Button("Start Dictation") {
                NotificationCenter.default.post(name: .startDictation, object: nil)
            }
            Button("Start Meeting") {
                NotificationCenter.default.post(name: .startMeeting, object: nil)
            }
            Divider()
            SettingsLink()
            Divider()
            Button("Quit") {
                coordinator.stop()
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "mic.circle")
        }
    }
}
