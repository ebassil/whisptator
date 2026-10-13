# Meeting Recording

## Purpose

Record meetings on-device with live, crash-durable output: capture microphone and system audio as discrete stereo channels, stream a timestamped transcript and an `.mp3` to disk during the meeting, surface the running transcript in a floating panel, and optionally identify speakers in a final pass.

## Requirements

### Requirement: Meeting recording start/stop
The system SHALL provide a global keyboard shortcut to start and stop meeting recording. The shortcut SHALL be configurable in Settings and SHALL reliably trigger the recording action when pressed. On start, the system SHALL create the session transcript and audio files in the configured save location and begin live capture, live segmentation, and incremental transcription concurrently. On stop, the system SHALL cease capture, drain queued transcription chunks (appending their results), perform the speaker-identification final pass when enabled, and return to idle.

#### Scenario: Start meeting recording
- **WHEN** the user triggers the meeting start/stop shortcut while not recording
- **THEN** the system begins capturing system audio and/or microphone audio per the configured source, opens `S.txt` and `S.mp3` in the save location, and live transcription begins

#### Scenario: Stop meeting recording
- **WHEN** the user triggers the meeting start/stop shortcut while recording is active
- **THEN** the system stops audio capture, flushes and closes the audio file, finishes any in-flight and queued transcription, relabels with speaker IDs if enabled, and the session becomes idle

#### Scenario: Meeting shortcut reliably triggers recording
- **WHEN** the user presses the meeting recording shortcut
- **THEN** the recording action is triggered immediately and consistently

#### Scenario: Stop while transcription backlog exists
- **WHEN** the user stops a meeting whose transcription queue is not empty
- **THEN** remaining chunks are transcribed and appended (or the speaker pass proceeds with what has landed) and the user sees finalization status

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
The system SHALL support three audio source modes for meeting recording: system + microphone, microphone only, and system only. System + microphone SHALL record both sources as two discrete channels (microphone left, system right) and SHALL NOT downmix to mono. Single-source modes SHALL record mono.

#### Scenario: System + microphone mode
- **WHEN** the audio source is set to "System + Microphone"
- **THEN** microphone audio is captured on the left channel and system audio on the right channel of the recorded stream, with no mono mixing

#### Scenario: Microphone only mode
- **WHEN** the audio source is set to "Microphone only"
- **THEN** only microphone audio is captured, recorded as mono, and no Screen Recording permission is required

#### Scenario: System only mode
- **WHEN** the audio source is set to "System only"
- **THEN** only system audio is captured via ScreenCaptureKit, recorded as mono

### Requirement: Transcript saving
The system SHALL save the meeting transcript to the user-configurable save location (defaulting to ~/Documents/Whisptator/Meetings/) with session filenames using a common stem `S` in format `meeting_YYYY-MM-DD_HH-MM`. Transcript lines SHALL be appended live during recording (see live-transcription) rather than written in one file at stop time. The directory SHALL be created automatically if missing, and the save location SHALL be snapshotted at session start.

#### Scenario: Transcript appended live to configured directory
- **WHEN** transcription chunks complete during a meeting
- **THEN** timestamped lines are appended to `S.txt` in the configured directory as they are produced

#### Scenario: Meeting directory created automatically
- **WHEN** the configured save directory does not exist at session start
- **THEN** the system creates it before writing any session files

#### Scenario: Save location change mid-meeting
- **WHEN** the user changes the save location while a meeting is active
- **THEN** the active session keeps writing to its start-time location and subsequent sessions use the new one

### Requirement: Audio retention policy
The system SHALL support three audio retention modes: keep audio files, delete after finalization, or auto-delete after a configurable number of days. These SHALL apply to the session `.mp3` (and any legacy `.wav`) produced by meeting sessions.

#### Scenario: Keep audio
- **WHEN** retention is set to "Keep"
- **THEN** the session `.mp3` file is kept alongside the transcript after the meeting ends

#### Scenario: Delete after finalization
- **WHEN** retention is set to "Delete after transcription"
- **THEN** the `.mp3` is deleted after the final transcription/diarization pass completes and the transcript is saved

#### Scenario: Auto-delete after days
- **WHEN** retention is set to auto-delete with N days
- **THEN** meeting audio files (`.mp3` and legacy `.wav`) older than N days are deleted on app launch

### Requirement: Meeting recording indicator
The system SHALL display a recording indicator in the menu bar during active meeting recording, including microphone-mute state. The system SHALL also display a system-wide overlay animation to indicate recording state. The transcribing/finalizing overlay state SHALL be shown only while the post-stop finalization pass (queue drain and speaker relabel) is running.

#### Scenario: Menu bar shows recording state
- **WHEN** meeting recording is active
- **THEN** the menu bar status item displays a recording indicator, plus a muted state when the microphone is muted

#### Scenario: Overlay animation during meeting recording
- **WHEN** meeting recording is active
- **THEN** a system-wide overlay animation is displayed on top of all windows indicating recording state

#### Scenario: Finalizing animation after stop
- **WHEN** meeting recording stops with speaker identification enabled and the final pass runs
- **THEN** the overlay transitions to the transcribing/finalizing indication until the session returns to idle

#### Scenario: No finalizing state without diarization
- **WHEN** meeting recording stops with speaker identification disabled
- **THEN** no extended finalizing state is shown beyond the queue drain, which is typically instantaneous from the user's perspective

### Requirement: Live stereo audio capture to MP3
The system SHALL encode the meeting audio to a session `.mp3` file live during recording using incremental LAME encoding, with microphone on the left channel and system audio on the right channel (mono when only one source is active). Encoded bytes SHALL be written to disk continuously and flushed at least every 2 seconds so that an application crash loses no more than approximately 2 seconds of audio tail.

#### Scenario: Audio grows during the meeting
- **WHEN** a meeting has been recording for N minutes
- **THEN** the session `.mp3` file exists in the save directory, is playable, and contains approximately N minutes of audio

#### Scenario: Crash keeps prior audio
- **WHEN** the application crashes during a live meeting
- **THEN** the `.mp3` file contains all audio up to the last flush, and its duration matches the transcript's last timestamp within the flush tolerance

#### Scenario: Audio file shares session stem
- **WHEN** a live session writes transcript `S.txt`
- **THEN** the audio file is `S.mp3` in the same directory

### Requirement: Microphone mute during meeting
The system SHALL allow the user to mute and unmute the microphone during an active meeting via a configurable global keyboard shortcut and via the live transcript panel and menu bar. While muted, the microphone channel SHALL be written as silence (preserving the timeline and stereo alignment), and the system SHALL append a `[HH:MM:SS] (mic muted)` / `(mic unmuted)` marker line to the transcript at each toggle. The mute shortcut SHALL have no effect when no meeting is active.

#### Scenario: Mute with shortcut mid-meeting
- **WHEN** the user presses the configured mute shortcut during a meeting
- **THEN** the left channel becomes silent, the UI reflects the muted state, and a `(mic muted)` marker line is appended

#### Scenario: Unmute restores audio path
- **WHEN** the user presses the mute shortcut again or clicks unmute
- **THEN** microphone samples are written again and a `(mic unmuted)` marker line is appended

#### Scenario: Shortcut while idle
- **WHEN** the mute shortcut is pressed while no meeting is recording
- **THEN** nothing happens
