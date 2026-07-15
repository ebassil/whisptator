import SwiftUI
import ServiceManagement
import AVFoundation
import WhisptatorCore

@main
struct WhisptatorApp: App {
    @State private var settings = AppSettings()
    @State private var showOnboarding = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .onAppear {
                    if settings.showInDock {
                        NSApp.setActivationPolicy(.regular)
                    } else {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
                .task {
                    guard !settings.hasCompletedOnboarding else { return }
                    await AVCaptureDevice.requestAccess(for: .audio)
                    settings.hasCompletedOnboarding = true
                }
        } label: {
            Image(systemName: "mic.circle")
        }

        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }

    func checkOnboarding() {
        if !settings.hasCompletedOnboarding {
            showOnboarding = true
        }
    }
}
