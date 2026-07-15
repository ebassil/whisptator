# General Settings Permissions

## Purpose

Display and manage macOS permissions (Accessibility, Microphone, Screen Recording) within the General Settings tab, with reactive status updates and deep-link support to System Settings.

## Requirements

### Requirement: Display Accessibility permission status in General Settings
The General Settings tab SHALL display the current Accessibility permission status using a `PermissionRow`. The status SHALL be determined by `AXIsProcessTrusted()`. The status SHALL update reactively while the settings panel is visible.

#### Scenario: Accessibility permission granted
- **WHEN** the user opens General Settings and Accessibility permission is granted
- **THEN** the Accessibility row shows "Granted" with a green checkmark icon

#### Scenario: Accessibility permission not granted
- **WHEN** the user opens General Settings and Accessibility permission is not granted
- **THEN** the Accessibility row shows a "Grant in Settings" button

#### Scenario: Permission granted while settings are visible
- **WHEN** the user grants Accessibility permission in System Settings while General Settings is open
- **THEN** the row updates to show "Granted" within 3 seconds

### Requirement: Display Microphone permission status in General Settings
The General Settings tab SHALL display the current Microphone permission status with reactive updates.

#### Scenario: Microphone permission granted
- **WHEN** the user opens General Settings and Microphone permission is granted
- **THEN** the Microphone row shows "Granted" with a green checkmark icon

#### Scenario: Microphone permission not granted
- **WHEN** the user opens General Settings and Microphone permission is not granted
- **THEN** the Microphone row shows a "Grant in Settings" button

### Requirement: Display Screen Recording permission status in General Settings
The General Settings tab SHALL display the current Screen Recording permission status using a `PermissionRow`. The status SHALL be determined by `CGPreflightScreenCaptureAccess()` and SHALL update reactively.

#### Scenario: Screen Recording permission granted
- **WHEN** the user opens General Settings and Screen Recording permission is granted
- **THEN** the Screen Recording row shows "Granted" with a green checkmark icon

#### Scenario: Screen Recording permission not granted
- **WHEN** the user opens General Settings and Screen Recording permission is not granted
- **THEN** the Screen Recording row shows a "Grant in Settings" button

### Requirement: Accessibility deep-link opens correct System Settings pane
The Accessibility "Grant in Settings" button SHALL open the Accessibility-specific pane in System Settings.

#### Scenario: Correct deep-link
- **WHEN** the user clicks "Grant in Settings" for Accessibility
- **THEN** System Settings opens to Privacy & Security > Accessibility

### Requirement: All permission checks use PermissionGate
The General Settings tab SHALL route all permission status checks through `PermissionGate.checkPermissions()` for consistency.

#### Scenario: Permission status from PermissionGate
- **WHEN** the General Settings tab loads
- **THEN** it calls `PermissionGate.checkPermissions()` to get all permission statuses

### Requirement: Reactive permission polling
The General Settings tab SHALL poll permission status at a regular interval while the tab is visible, and SHALL stop polling when the tab is no longer visible.

#### Scenario: Polling active while visible
- **WHEN** the General Settings tab is visible
- **THEN** permission statuses are re-checked every 2 seconds

#### Scenario: Polling stops on disappear
- **WHEN** the General Settings tab is no longer visible
- **THEN** polling stops
