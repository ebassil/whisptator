import Foundation
import AVFoundation
import AppKit

public struct PermissionStatus: Sendable {
    public let accessibility: Bool
    public let microphone: Bool
    public let screenRecording: Bool

    public init(accessibility: Bool, microphone: Bool, screenRecording: Bool) {
        self.accessibility = accessibility
        self.microphone = microphone
        self.screenRecording = screenRecording
    }

    public var allGranted: Bool {
        accessibility && microphone && screenRecording
    }
}

public final class PermissionGate: @unchecked Sendable {
    public init() {}

    public func checkPermissions() -> PermissionStatus {
        PermissionStatus(
            accessibility: checkAccessibilityPermission(),
            microphone: checkMicrophonePermission(),
            screenRecording: checkScreenRecordingPermission()
        )
    }

    public func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    public func checkMicrophonePermission() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    public func checkScreenRecordingPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    public func requestMicrophonePermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    public func requestScreenRecordingPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
        return CGRequestScreenCaptureAccess()
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

}
