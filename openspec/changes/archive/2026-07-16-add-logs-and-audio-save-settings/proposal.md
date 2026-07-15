# Add Logs Section and Audio Save Settings

## Why

The application currently has no visibility into its internal operations. When something goes wrong — a shortcut fails to register, a model download stalls, or transcription errors occur — there is no way for the user (or developer) to understand what happened. Adding a logs section in Settings gives users transparency into the app's behavior and helps with debugging.

Additionally, dictation audio files are currently never saved to disk. Users who want to keep recordings for later review or processing have no option to do so. Adding a toggle to save audio files and a directory picker for their location gives users control over their recorded data.

## What Changes

1. **New Logs tab in Settings** — A scrollable, auto-updating log viewer that displays timestamped log messages from all subsystems: keyboard shortcut events, state machine transitions, model loading, transcription status, setting changes, errors, and audio device operations.

2. **Audio save settings in Dictation tab** — Two new controls in the existing Dictation settings section:
   - A toggle: "Save audio files" (default: off)
   - A directory picker: "Save location" (shown only when toggle is on), defaulting to `~/Documents/Whisptator/Audio`

3. **Logging infrastructure** — A new `AppLogger` module in WhisptatorCore that provides a centralized, thread-safe logging system. All subsystems will emit structured log messages through this logger.

4. **Log emission at critical points** — Log messages added to:
   - HotkeyMonitor: shortcut key down/up events, modifier-only chord detection, tap re-enable
   - DictationOrchestrator: state transitions (idle→recording→transcribing→pasting→error)
   - MeetingRecorder: state transitions, audio source selection
   - ModelManager: download start, progress, completion, failure
   - TranscriptionEngine: transcription start, completion, errors
   - MicrophoneCapture: capture start/stop, errors
   - AppSettings: setting value changes
   - AppCoordinator: notification handling, state change routing

## Capabilities Impacted

- **settings-ui** — New Logs tab added; Dictation tab gains audio save controls
- **dictation** — Audio file saving option added to dictation flow
- **hotkey-system** — Logging added to shortcut detection
- **meeting-recording** — Logging added to meeting state machine
- **whisper-stt** — Logging added to model download and transcription
- **overlay-visual-feedback** — Logging added to overlay state changes

## Non-Goals

- Log persistence across app restarts (logs are in-memory only)
- Log filtering or search
- Log export functionality
- Remote logging or telemetry
- Log level configuration (all logs are informational)
