import SwiftUI
import AVFoundation
import WhisptatorCore

struct OnboardingView: View {
    @State private var settings = AppSettings()
    @State private var permissionGate = PermissionGate()
    @State private var accessibilityGranted = false
    @State private var microphoneGranted = false
    @State private var screenRecordingGranted = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Welcome to Whisptator")
                .font(.title)
                .fontWeight(.bold)

            Text("Whisptator needs a few permissions to work properly.")
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                PermissionGrantRow(
                    name: "Accessibility",
                    description: "Required for global keyboard shortcuts and text pasting",
                    granted: accessibilityGranted,
                    onGrant: {
                        permissionGate.openAccessibilitySettings()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            accessibilityGranted = AXIsProcessTrusted()
                        }
                    }
                )

                PermissionGrantRow(
                    name: "Microphone",
                    description: "Required for audio recording during dictation",
                    granted: microphoneGranted,
                    onGrant: {
                        Task {
                            microphoneGranted = await permissionGate.requestMicrophonePermission()
                        }
                    }
                )

                PermissionGrantRow(
                    name: "Screen Recording",
                    description: "Required for system audio capture during meetings",
                    granted: screenRecordingGranted,
                    onGrant: {
                        Task {
                            screenRecordingGranted = await permissionGate.requestScreenRecordingPermission()
                        }
                    }
                )
            }
            .padding(.horizontal, 40)

            HStack {
                Button("Skip for now") {
                    settings.hasCompletedOnboarding = true
                    dismiss()
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Continue") {
                    settings.hasCompletedOnboarding = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!accessibilityGranted || !microphoneGranted)
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
        .frame(width: 500)
        .onAppear {
            accessibilityGranted = AXIsProcessTrusted()
            microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            screenRecordingGranted = CGPreflightScreenCaptureAccess()
        }
    }
}

struct PermissionGrantRow: View {
    let name: String
    let description: String
    let granted: Bool
    let onGrant: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(granted ? .green : .orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !granted {
                Button("Grant") {
                    onGrant()
                }
                .buttonStyle(.bordered)
            } else {
                Text("Granted")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
    }
}
