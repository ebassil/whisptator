## ADDED Requirements

### Requirement: Meeting recording start/stop
The system SHALL provide a global keyboard shortcut to start and stop meeting recording. The shortcut SHALL be configurable in Settings.

#### Scenario: Start meeting recording
- **WHEN** the user triggers the meeting start/stop shortcut while not recording
- **THEN** the system begins capturing system audio and/or microphone audio based on the configured audio source setting

#### Scenario: Stop meeting recording
- **WHEN** the user triggers the meeting start/stop shortcut while recording is active
- **THEN** the system stops audio capture, transcribes the accumulated audio, and saves the transcript to disk

### Requirement: System audio capture
The system SHALL use ScreenCaptureKit with `capturesAudio: true` and `excludesCurrentProcessAudio: true` to capture system audio output.

#### Scenario: System audio captured
- **WHEN** meeting recording is active with system audio enabled
- **THEN** all system audio output (except the app's own audio) is captured

#### Scenario: Screen Recording permission required
- **WHEN** the user enables system audio capture and Screen Recording permission has not been granted
- **THEN** the system displays a permission prompt directing the user to System Settings

### Requirement: Microphone audio capture
The system SHALL use AVFoundation to capture audio from the selected microphone device during meeting recording.

#### Scenario: Microphone captured during meeting
- **WHEN** meeting recording is active with microphone enabled
- **THEN** audio from the configured microphone device is captured

### Requirement: Audio source modes
The system SHALL support three audio source modes for meeting recording: system + microphone, microphone only, and system only.

#### Scenario: System + microphone mode
- **WHEN** the audio source is set to "System + Microphone"
- **THEN** both system audio and microphone audio are captured and mixed into a single stream

#### Scenario: Microphone only mode
- **WHEN** the audio source is set to "Microphone only"
- **THEN** only microphone audio is captured and no Screen Recording permission is required

#### Scenario: System only mode
- **WHEN** the audio source is set to "System only"
- **THEN** only system audio is captured via ScreenCaptureKit

### Requirement: Transcript saving
The system SHALL save the transcribed meeting text to ~/Documents/Whisptator/Meetings/ with a filename format of `meeting_YYYY-MM-DD_HH-MM.txt`.

#### Scenario: Transcript saved to disk
- **WHEN** meeting recording stops and transcription completes
- **THEN** the transcript text is saved to a .txt file in the Meetings directory

#### Scenario: Meeting directory created automatically
- **WHEN** the Meetings directory does not exist
- **THEN** the system creates it before saving

### Requirement: Audio retention policy
The system SHALL support three audio retention modes: keep audio files, delete after transcription, or auto-delete after a configurable number of days.

#### Scenario: Keep audio
- **WHEN** retention is set to "Keep"
- **THEN** the recorded audio .wav file is saved alongside the transcript

#### Scenario: Delete after transcription
- **WHEN** retention is set to "Delete after transcription"
- **THEN** the audio file is deleted after the transcript is saved

#### Scenario: Auto-delete after days
- **WHEN** retention is set to auto-delete with N days
- **THEN** audio files older than N days are deleted on app launch

### Requirement: Meeting recording indicator
The system SHALL display a recording indicator in the menu bar during active meeting recording.

#### Scenario: Menu bar shows recording state
- **WHEN** meeting recording is active
- **THEN** the menu bar status item displays a recording indicator (e.g., red dot or "Recording" text)
