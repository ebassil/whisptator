## Why

The General Settings panel displays a green "Granted" checkmark for Microphone permission but not for Accessibility permission, even when the user has granted both in System Settings. This causes user confusion about whether the app is properly configured and undermines trust in the permission checking system.

## What Changes

- Fix the Accessibility permission status display in General Settings to accurately reflect the granted state
- Change the Accessibility "Grant in Settings" deep-link to open the correct System Settings pane (Privacy_Accessibility instead of the generic Privacy pane)
- Make permission status checks reactive so the UI updates after the user grants permission while the settings panel is open
- Add Screen Recording permission row to General Settings (currently missing, only shown in onboarding)
- Update permission checking to handle the macOS TCC path-invalidation edge case where `AXIsProcessTrusted()` returns false after a rebuild

## Capabilities

### New Capabilities
- `general-settings-permissions`: Unified permission display in General Settings with reactive status checking for all three required permissions (Accessibility, Microphone, Screen Recording)

### Modified Capabilities
- *(No existing specs to modify - `openspec/specs/` is empty)*

## Impact

- `SettingsView.swift` - General Settings tab permission section needs rework
- `PermissionGate.swift` - May need additional helper methods for reactive permission checks
- `OnboardingView.swift` - Minor alignment if PermissionGate API changes
- No new dependencies required
- No breaking changes to existing functionality
