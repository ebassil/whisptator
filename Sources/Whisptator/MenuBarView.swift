import SwiftUI
import WhisptatorCore
import ServiceManagement

struct MenuBarView: View {
    @State private var settings = AppSettings()

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
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "mic.circle")
        }
    }
}

extension Notification.Name {
    static let startDictation = Notification.Name("startDictation")
    static let startMeeting = Notification.Name("startMeeting")
}
