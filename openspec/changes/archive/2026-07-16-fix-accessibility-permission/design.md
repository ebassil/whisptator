## Context

The General Settings tab (`SettingsView.swift`) displays permission status for Accessibility and Microphone using `PermissionRow` views. Each row evaluates the check once at view construction time — no reactive observation. The Accessibility "Grant in Settings" button deep-links to the generic Privacy & Security pane (`Privacy`) instead of the Accessibility-specific pane (`Privacy_Accessibility`). Screen Recording is entirely absent from General Settings, despite being shown in the onboarding flow and required for meeting functionality.

macOS 15 (Sequoia) TCC behavior:
- `AXIsProcessTrusted()` is path-sensitive — each rebuild invalidates prior TCC grants
- Ad-hoc signed binaries (the default development path) may not be properly recognized by the Accessibility subsystem
- Microphone uses `AVCaptureDevice.authorizationStatus()` which is more resilient across builds
- No programmatic API exists to prompt for Accessibility — only a System Settings deep-link is available

## Goals / Non-Goals

**Goals:**
- Fix the General Settings Accessibility row to correctly show "Granted" when the user has granted the permission
- Fix the Accessibility deep-link to open the correct System Settings pane
- Make permission status reactive so the UI updates when the user grants permission while settings are open
- Add the missing Screen Recording permission row to General Settings
- Provide consistent permission status display across onboarding and settings

**Non-Goals:**
- Changing the underlying macOS TCC permission model
- Adding programmatic Accessibility permission requests (not possible on macOS)
- Modifying the onboarding flow (OnboardingView.swift) behavior

## Decisions

1. **Reactive permission checking via onAppear + onReceive** — Use SwiftUI's `.onAppear` and a periodic timer (`Timer.publish`) to re-check permission status while the General Settings tab is visible. This handles the case where the user switches to System Settings, grants permission, and returns. Alternative considered: `@Observable` wrapper; rejected because `AXIsProcessTrusted()` is a synchronous C function that cannot be observed via KVO.

2. **Deep-link to `Privacy_Accessibility`** — Change the Accessibility button URL from `com.apple.preference.security?Privacy` to `com.apple.preference.security?Privacy_Accessibility` to open directly to the Accessibility sub-pane. This matches `PermissionGate.openAccessibilitySettings()`.

3. **Ad-hoc signing + bundled app recommendation** — Document in code comments that `AXIsProcessTrusted()` reliability depends on proper codesigning. The Makefile already handles bundling and ad-hoc signing; users should `make run-debug` instead of `swift run`.

4. **PermissionGate as single source of truth** — Route all permission checks through `PermissionGate.checkPermissions()` instead of inline calls to `AXIsProcessTrusted()` / `AVCaptureDevice.authorizationStatus()`. This centralizes permission logic.

## Risks / Trade-offs

- **Reactive checking adds minor CPU overhead** — A 2-second polling interval is negligible but ensures timely UI updates. Mitigation: cancel timer when view disappears using `.onDisappear`.
- **Ad-hoc signing limitations** — On macOS 15+, `AXIsProcessTrusted()` may still return false for ad-hoc signed apps even when listed in Accessibility. This is a platform limitation, not a code bug. Mitigation: document that a Developer ID or Apple Distribution signing certificate is recommended for production.
- **Screen Recording permission check is a new addition** — Adding it to General Settings is low risk but increases the settings panel's visual footprint. The existing `PermissionRow` pattern keeps it consistent.
