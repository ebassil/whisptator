# Tasks: Logs Section and Audio Save Settings

## 1. Create AppLogger infrastructure

- [x] Create `Sources/WhisptatorCore/Settings/AppLogger.swift`
  - [x] Define `LogCategory` enum: shortcut, dictation, meeting, model, transcription, audio, settings, overlay, system
  - [x] Define `LogEntry` struct: `id: UUID`, `timestamp: Date`, `category: LogCategory`, `message: String`
  - [x] Create `AppLogger` class with `@Observable` conformance
  - [x] Add `entries: [LogEntry]` array (capped at 1000, auto-evict oldest)
  - [x] Add `log(category: LogCategory, message: String)` method
  - [x] Add `clear()` method
  - [x] Expose as singleton via `static let shared` or via `AppCoordinator`

## 2. Add audio save settings to AppSettings

- [x] Add `saveAudioFiles: Bool` property (UserDefaults key: `saveAudioFiles`, default: false)
- [x] Add `audioSaveLocation: String` property (UserDefaults key: `audioSaveLocation`, default: `~/Documents/Whisptator/Audio`)
- [x] Add corresponding `Key` enum cases

## 3. Create AudioFileSaver utility

- [x] Create `Sources/WhisptatorCore/Audio/AudioFileSaver.swift`
  - [x] `saveAudioFile(samples: [Float], sampleRate: Int, to directory: String) -> String?` method
  - [x] Write WAV file: PCM 16-bit mono, proper WAV header (RIFF, fmt, data chunks)
  - [x] Generate filename with timestamp: `dictation_YYYY-MM-DD_HH-mm-ss.wav`
  - [x] Create directory if it doesn't exist
  - [x] Run on a background queue

## 4. Add log emission to HotkeyMonitor

- [x] Import `AppLogger` in `HotkeyMonitor.swift`
- [x] Log on `start()` — "Hotkey monitor started"
- [x] Log on `stop()` — "Hotkey monitor stopped"
- [x] Log on push-to-talk key down — "Push-to-talk down: keyCode=XX"
- [x] Log on push-to-talk key up — "Push-to-talk up"
- [x] Log on hands-free tap — "Hands-free tap detected"
- [x] Log on meeting toggle — "Meeting toggle detected"
- [x] Log on modifier-only chord match — "Modifier-only shortcut matched: <keys>"
- [x] Log on tap re-enable — "Event tap re-enabled (timeout recovery)"
- [x] Log on `start()` accessibility check failure — "Hotkey start failed: accessibility not granted"

## 5. Add log emission to DictationOrchestrator

- [x] Import `AppLogger` in `DictationOrchestrator.swift`
- [x] Log on state transitions: idle→recording, recording→transcribing, transcribing→pasting, any→error
- [x] Log on `startRecording()` — "Dictation recording started"
- [x] Log on `stopRecordingAndTranscribe()` — "Dictation recording stopped, starting transcription"
- [x] Log on `performTranscription()` start — "Transcription started (samples: N)"
- [x] Log on transcription success — "Transcription completed (chars: N)"
- [x] Log on transcription error — "Transcription failed: <error>"
- [x] Log on empty audio — "Empty audio, skipping transcription"
- [x] Log on paste — "Pasted text (mode: <mode>, chars: N)"

## 5. Add log emission to MeetingRecorder

- [x] Import `AppLogger` in `MeetingRecorder.swift`
- [x] Log on state transitions: idle→recording, recording→transcribing, transcribing→saving, any→error
- [x] Log on `startRecording()` — "Meeting recording started (source: <mode>)"
- [x] Log on `stopRecording()` — "Meeting recording stopped, starting transcription"
- [x] Log on transcription success — "Meeting transcription completed (chars: N)"
- [x] Log on save — "Transcript saved to: <path>"
- [x] Log on error — "Meeting error: <error>"

## 5. Add log emission to ModelManager

- [x] Import `AppLogger` in `ModelManager.swift`
- [x] Log on download start — "Model download started: <modelId>"
- [x] Log on download progress — "Model download progress: <progress>%"
- [x] Log on download complete — "Model download complete"
- [x] Log on model loaded — "Model loaded successfully"
- [x] Log on model load failure — "Model load failed: <error>"
- [x] Log on offline load — "Model loaded from cache"

## 6. Add log emission to TranscriptionEngine

- [x] Import `AppLogger` in `TranscriptionEngine.swift`
- [x] Log on transcribe start — "Transcription started (samples: N, sampleRate: N)"
- [x] Log on transcribe success — "Transcription completed (text length: N)"
- [x] Log on transcribe error — "Transcription error: <error>"

## 7. Add log emission to MicrophoneCapture

- [x] Import `AppLogger` in `MicrophoneCapture.swift`
- [x] Log on capture start — "Microphone capture started (device: <name>)"
- [x] Log on capture stop — "Microphone capture stopped"
- [x] Log on device not found — "Microphone error: device not found"
- [x] Log on cannot add input — "Microphone error: cannot add input"
- [x] Log on cannot add output — "Microphone error: cannot add output"

## 8. Add log emission to AppSettings

- [x] Import `AppLogger` in `AppSettings.swift`
- [x] Add `onSettingChange: ((String) -> Void)?` callback
- [x] Log on every property setter — "Setting changed: <key> = <value>"
- [x] Wire `onSettingChange` to `AppLogger` in `AppCoordinator`

## 9. Add log emission to AppCoordinator

- [x] Import `AppLogger` in `AppCoordinator.swift`
- [x] Log on `start()` — "AppCoordinator started"
- [x] Log on `stop()` — "AppCoordinator stopped"
- [x] Log on dictation state change — "Dictation state: <state>"
- [x] Log on meeting state change — "Meeting state: <state>"
- [x] Log on notification received — "Notification: <name>"
- [x] Wire `settings.onSettingChange` to `AppLogger`

## 10. Add log emission to OverlayController

- [x] Import `AppLogger` in `OverlayController.swift`
- [x] Log on `show()` — "Overlay shown (state: <state>, screens: N)"
- [x] Log on `updateState()` — "Overlay state updated: <state>"
- [x] Log on `dismiss()` — "Overlay dismissed"
- [x] Log on `showCompletionThenDismiss()` — "Overlay showing completion, will dismiss in 1.5s"

## 11. Add Logs tab to SettingsView

- [x] Create `LogsSettingsTab` view in `SettingsView.swift`
  - [x] Scrollable list of log entries (newest first)
  - [x] Each entry: timestamp (HH:MM:SS), category badge, message
  - [x] Auto-scroll to newest entry
  - [x] "Clear" button to clear all entries
  - [x] Bind to `AppLogger.shared.entries`
- [x] Add `LogsSettingsTab` to the `TabView` in `SettingsView`
  - [x] Tab label: "Logs" with `systemImage: "list.bullet.rectangle"`
- [x] Pass `AppLogger` reference through `AppCoordinator` to `SettingsView`

## 6. Add audio save controls to DictationSettingsTab

- [x] Add "Save audio files" toggle to DictationSettingsTab
- [x] Add "Save location" row with path display and "Change" button (shown only when toggle is on)
- [x] Use `NSOpenPanel` for directory selection (reuse pattern from MeetingSettingsTab)

## 7. Wire audio file saving in DictationOrchestrator

- [x] Import `AudioFileSaver` in `DictationOrchestrator.swift`
- [x] After `microphoneCapture.stopCapture()` in `stopRecordingAndTranscribe()`:
  - [x] If `settings.saveAudioFiles` is true, save merged audio to WAV file
  - [x] Log the save action
- [x] Run file save on a background queue

## 8. Add log emission to remaining subsystems

- [x] Add log emission to `TranscriptionEngine` (start, success, error)
- [x] Add log emission to `MicrophoneCapture` (start, stop, errors)
- [x] Add log emission to `ModelManager` (download progress, load, failure)
- [x] Add log emission to `OverlayController` (show, updateState, dismiss)
- [x] Add log emission to `AppSettings` (setting changes via callback)

## 9. Wire AppLogger into AppCoordinator

- [x] Create `AppLogger` instance in `AppCoordinator`
- [x] Wire `settings.onSettingChange` to `AppLogger.log(category: .settings, message:)`
- [x] Pass logger reference to `SettingsView` for the Logs tab
- [x] Ensure logger is accessible from all subsystems that need it

## 10. Update settings-ui spec

- [x] Add Logs tab requirements to `settings-ui/spec.md`
- [x] Add audio save settings requirements to Dictation tab section in `settings-ui/spec.md`

## 11. Update dictation spec

- [x] Add audio file saving requirement to `dictation/spec.md`
