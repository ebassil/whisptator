# Overlay Visual Feedback

## Purpose

Provides system-wide visual overlays to indicate recording, transcribing, and completion states during dictation and meeting recording sessions.

## Requirements

### Requirement: System-wide overlay display
The system SHALL display a visual overlay on top of all open windows when recording or transcribing is active.

#### Scenario: Overlay appears during recording
- **WHEN** the user triggers a recording shortcut (dictation or meeting recording)
- **THEN** a visual overlay appears on screen indicating recording is active

#### Scenario: Overlay disappears after completion
- **WHEN** recording stops and transcription completes
- **THEN** the visual overlay is dismissed from the screen

### Requirement: Recording state animation
The system SHALL display a distinct animation on the overlay to indicate active audio recording.

#### Scenario: Recording animation visible
- **WHEN** the overlay is displayed during active recording
- **THEN** the overlay shows a pulsing circle with microphone icon or equivalent recording indicator

#### Scenario: Recording animation responds to audio
- **WHEN** audio is being captured during recording
- **THEN** the recording animation responds to voice input (e.g., waveform, pulse intensity)

### Requirement: Transcribing state animation
The system SHALL display a distinct animation on the overlay to indicate AI model processing/transcription is in progress.

#### Scenario: Transcribing animation visible
- **WHEN** recording stops and transcription begins
- **THEN** the overlay transitions to a different animation indicating processing state

#### Scenario: Transcribing animation distinct from recording
- **WHEN** comparing recording and transcribing animations
- **THEN** the two states are visually distinct (different color, icon, or motion)

### Requirement: Overlay positioning options
The system SHALL support multiple overlay positioning options that can be configured in settings.

#### Scenario: Center position
- **WHEN** overlay position is set to "Center"
- **THEN** the overlay appears centered on the primary display

#### Scenario: Top-right position
- **WHEN** overlay position is set to "Top-Right"
- **THEN** the overlay appears in the top-right corner of the primary display

#### Scenario: Bottom-center position
- **WHEN** overlay position is set to "Bottom-Center"
- **THEN** the overlay appears centered at the bottom of the screen, above the dock

#### Scenario: Follow cursor position
- **WHEN** overlay position is set to "Follow Cursor"
- **THEN** the overlay appears near the current mouse cursor location

### Requirement: Dual-screen support
The system SHALL support displaying the overlay on multiple connected displays.

#### Scenario: Primary display only
- **WHEN** dual-screen mode is set to "Primary Only"
- **THEN** the overlay appears only on the main display

#### Scenario: Both displays
- **WHEN** dual-screen mode is set to "Both Displays"
- **THEN** identical overlay appears simultaneously on all connected displays

#### Scenario: Active application display
- **WHEN** dual-screen mode is set to "Active App Display"
- **THEN** the overlay appears on the display where the frontmost application is located

### Requirement: Overlay visibility settings
The system SHALL allow users to configure overlay appearance in settings.

#### Scenario: Opacity setting
- **WHEN** the user adjusts overlay opacity in settings
- **THEN** the overlay transparency changes accordingly (0-100%)

#### Scenario: Size setting
- **WHEN** the user adjusts overlay size in settings
- **THEN** the overlay scales to the configured size

#### Scenario: Disable overlay
- **WHEN** the user disables overlay in settings
- **THEN** no visual overlay is displayed during recording or transcribing
