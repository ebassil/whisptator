## MODIFIED Requirements

### Requirement: System-wide dictation trigger
The system SHALL provide a global keyboard shortcut that triggers speech-to-text dictation from any application on macOS. The shortcut SHALL work regardless of which application has focus and SHALL reliably trigger the dictation action.

#### Scenario: Dictation triggered from any app
- **WHEN** the user presses the configured dictation shortcut in any application
- **THEN** the system begins recording audio from the configured microphone device

#### Scenario: Dictation shortcut does not interfere with apps
- **WHEN** the user presses the dictation shortcut
- **THEN** the key event is not forwarded to the frontmost application

#### Scenario: Dictation shortcut reliably triggers recording
- **WHEN** the user presses the configured dictation shortcut
- **THEN** the recording action is triggered immediately and consistently

### Requirement: Recording indicator
The system SHALL display a floating HUD panel during active recording showing the recording status and elapsed time. The system SHALL also display a system-wide overlay animation to indicate recording state.

#### Scenario: HUD displayed during recording
- **WHEN** recording is active
- **THEN** a small floating panel is displayed showing a recording indicator and elapsed time in MM:SS format

#### Scenario: HUD dismissed after recording
- **WHEN** recording stops
- **THEN** the floating HUD panel is dismissed

#### Scenario: Overlay animation during recording
- **WHEN** recording is active
- **THEN** a system-wide overlay animation is displayed on top of all windows indicating recording state

#### Scenario: Transcribing animation during processing
- **WHEN** recording stops and transcription begins
- **THEN** the overlay animation transitions to indicate transcribing/processing state