import SwiftUI
import ServiceManagement
import AVFoundation
import WhisptatorCore

@main
struct WhisptatorApp: App {
    @State private var coordinator = AppCoordinator()
    @State private var showOnboarding = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: coordinator)
                .onAppear {
                    if coordinator.settings.showInDock {
                        NSApp.setActivationPolicy(.regular)
                    } else {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
                .task {
                    if !coordinator.settings.hasCompletedOnboarding {
                        await AVCaptureDevice.requestAccess(for: .audio)
                        coordinator.settings.hasCompletedOnboarding = true
                    }
                    try? coordinator.start()
                }
        } label: {
            Image(systemName: "mic.circle")
        }

        Settings {
            SettingsView(coordinator: coordinator)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
