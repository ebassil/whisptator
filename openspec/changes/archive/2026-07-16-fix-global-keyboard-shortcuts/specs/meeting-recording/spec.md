## MODIFIED Requirements

### Requirement: Meeting recording start/stop
The system SHALL provide a global keyboard shortcut to start and stop meeting recording. The shortcut SHALL be configurable in Settings and SHALL reliably trigger the recording action when pressed.

#### Scenario: Start meeting recording
- **WHEN** the user triggers the meeting start/stop shortcut while not recording
- **THEN** the system begins capturing system audio and/or microphone audio based on the configured audio source setting

#### Scenario: Stop meeting recording
- **WHEN** the user triggers the meeting start/stop shortcut while recording is active
- **THEN** the system stops audio capture, transcribes the accumulated audio, and saves the transcript to disk

#### Scenario: Meeting shortcut reliably triggers recording
- **WHEN** the user presses the meeting recording shortcut
- **THEN** the recording action is triggered immediately and consistently

### Requirement: Meeting recording indicator
The system SHALL display a recording indicator in the menu bar during active meeting recording. The system SHALL also display a system-wide overlay animation to indicate recording and transcribing states.

#### Scenario: Menu bar shows recording state
- **WHEN** meeting recording is active
- **THEN** the menu bar status item displays a recording indicator (e.g., red dot or "Recording" text)

#### Scenario: Overlay animation during meeting recording
- **WHEN** meeting recording is active
- **THEN** a system-wide overlay animation is displayed on top of all windows indicating recording state

#### Scenario: Transcribing animation during meeting processing
- **WHEN** meeting recording stops and transcription begins
- **THEN** the overlay animation transitions to indicate transcribing/processing state