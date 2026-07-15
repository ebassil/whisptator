## ADDED Requirements

### Requirement: System-wide dictation trigger
The system SHALL provide a global keyboard shortcut that triggers speech-to-text dictation from any application on macOS. The shortcut SHALL work regardless of which application has focus.

#### Scenario: Dictation triggered from any app
- **WHEN** the user presses the configured dictation shortcut in any application
- **THEN** the system begins recording audio from the configured microphone device

#### Scenario: Dictation shortcut does not interfere with apps
- **WHEN** the user presses the dictation shortcut
- **THEN** the key event is not forwarded to the frontmost application

### Requirement: Push-to-talk mode
The system SHALL support push-to-talk dictation where holding the shortcut key records audio and releasing it stops recording and triggers transcription.

#### Scenario: Push-to-talk recording
- **WHEN** the user presses and holds the push-to-talk shortcut key
- **THEN** the system begins recording audio and displays a floating HUD with a timer

#### Scenario: Push-to-talk stop and transcribe
- **WHEN** the user releases the push-to-talk shortcut key
- **THEN** the system stops recording, transcribes the audio, runs text cleanup, and pastes the result into the frontmost application

### Requirement: Hands-free mode
The system SHALL support hands-free dictation where tapping the shortcut key starts recording and tapping it again stops recording.

#### Scenario: Hands-free start
- **WHEN** the user taps the hands-free shortcut key
- **THEN** the system begins recording audio and displays a floating HUD with a timer

#### Scenario: Hands-free stop
- **WHEN** the user taps the hands-free shortcut key while recording is active
- **THEN** the system stops recording, transcribes the audio, runs text cleanup, and pastes the result into the frontmost application

### Requirement: Recording indicator
The system SHALL display a floating HUD panel during active recording showing the recording status and elapsed time.

#### Scenario: HUD displayed during recording
- **WHEN** recording is active
- **THEN** a small floating panel is displayed showing a recording indicator and elapsed time in MM:SS format

#### Scenario: HUD dismissed after recording
- **WHEN** recording stops
- **THEN** the floating HUD panel is dismissed

### Requirement: Transcription latency
The system SHALL complete transcription of recorded audio within 2 seconds for recordings up to 30 seconds long on Apple Silicon hardware.

#### Scenario: Short dictation latency
- **WHEN** the user completes a 10-second dictation
- **THEN** the transcribed text is pasted into the frontmost application within 2 seconds of recording stopping

### Requirement: Audio device selection
The system SHALL allow the user to select which microphone device to use for dictation from a list of available audio input devices.

#### Scenario: Device list populated
- **WHEN** the user opens Settings and navigates to Dictation
- **THEN** the system displays a list of all available audio input devices

#### Scenario: Device selection persisted
- **WHEN** the user selects a different audio input device
- **THEN** the selection is saved and used for all subsequent dictation sessions
