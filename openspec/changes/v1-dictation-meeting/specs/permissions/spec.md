## ADDED Requirements

### Requirement: Accessibility permission check
The system SHALL check whether Accessibility permission is granted on launch using `AXIsProcessTrusted()`. The system SHALL display a warning if the permission is not granted.

#### Scenario: Permission granted
- **WHEN** the application launches and Accessibility permission is granted
- **THEN** the CGEvent tap is activated and global hotkeys function normally

#### Scenario: Permission not granted
- **WHEN** the application launches and Accessibility permission is not granted
- **THEN** a warning is displayed in the menu bar and Settings, with a button to open System Settings > Privacy & Security > Accessibility

### Requirement: Microphone permission check
The system SHALL check whether Microphone permission is granted when the user first attempts to record audio. The system SHALL request permission if not already granted.

#### Scenario: Microphone permission granted
- **WHEN** the user triggers dictation and Microphone permission is granted
- **THEN** audio recording begins normally

#### Scenario: Microphone permission not granted
- **WHEN** the user triggers dictation and Microphone permission is not granted
- **THEN** the system displays a prompt directing the user to System Settings > Privacy & Security > Microphone

### Requirement: Screen Recording permission check
The system SHALL check whether Screen Recording permission is granted when the user attempts to start a meeting recording with system audio enabled.

#### Scenario: Screen Recording permission granted
- **WHEN** the user starts a meeting recording with system audio and Screen Recording permission is granted
- **THEN** system audio capture begins normally via ScreenCaptureKit

#### Scenario: Screen Recording permission not granted
- **WHEN** the user starts a meeting recording with system audio and Screen Recording permission is not granted
- **THEN** the system displays a prompt directing the user to System Settings > Privacy & Security > Screen Recording

#### Scenario: Microphone-only meeting skips Screen Recording check
- **WHEN** the user starts a meeting recording with "Microphone only" audio source
- **THEN** the system does not check or require Screen Recording permission

### Requirement: Permission onboarding flow
The system SHALL display a first-launch onboarding dialog that explains which permissions are needed and why, with buttons to grant each permission.

#### Scenario: First launch onboarding
- **WHEN** the application launches for the first time
- **THEN** an onboarding dialog is displayed listing Accessibility, Microphone, and Screen Recording permissions with explanations and grant buttons

#### Scenario: Skip onboarding
- **WHEN** the user clicks "Skip for now" in the onboarding dialog
- **THEN** the dialog is dismissed and the app continues with reduced functionality until permissions are granted

### Requirement: Permission status in Settings
The system SHALL display the current status of all required permissions in the General settings tab.

#### Scenario: Permission status indicators
- **WHEN** the user opens General settings
- **THEN** each permission shows "✅ Granted" or "⚠️ Grant in System Settings" with a link to the relevant System Settings pane
