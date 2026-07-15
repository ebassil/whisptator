# Design: Logs Section and Audio Save Settings

## Context

Whisptator is a macOS menu bar app (Swift/SwiftUI, macOS 15+, Apple Silicon) using MVVM with an `AppCoordinator` hub. Settings are in `AppSettings` (`@Observable`, UserDefaults-backed). The settings UI is a `TabView` in `SettingsView.swift` with 6 tabs. There is currently no logging infrastructure.

## Goals

- Provide users with real-time visibility into app operations via a Logs tab
- Give users control over dictation audio file persistence
- Add minimal overhead to existing code paths

## Non-Goals

- Persistent log storage across app restarts
- Log levels or filtering
- Remote logging or telemetry

## Design Decisions

### D1: Centralized `AppLogger` with `@Observable` log store

A new `AppLogger` class in `WhisptatorCore/Settings/AppLogger.swift` will hold an `@Observable` array of `LogEntry` structs. Each entry has a timestamp, category, and message string. The logger is a singleton shared across the app via `AppCoordinator`. The Settings Logs tab binds directly to this observable array.

**Rationale**: `@Observable` gives the SwiftUI view automatic updates when new log entries are appended. A singleton avoids threading issues and keeps the API simple.

**Alternatives considered**: OSLog — great for system-level debugging but not visible in-app. File-based logging — adds I/O overhead and complexity for a feature that doesn't need persistence.

### D2: Log categories

Log entries are tagged with a `LogCategory` enum:
- `shortcut` — HotkeyMonitor events
- `dictation` — DictationOrchestrator state machine
- `meeting` — MeetingRecorder state machine
- `model` — ModelManager download/load events
- `transcription` — TranscriptionEngine events
- `audio` — MicrophoneCapture events
- `settings` — AppSettings value changes
- `overlay` — OverlayController state changes
- `system` — AppCoordinator and general events

### D3: Audio save settings in AppSettings

Two new properties in `AppSettings`:
- `saveAudioFiles: Bool` (default: false) — UserDefaults key `saveAudioFiles`
- `audioSaveLocation: String` (default: `~/Documents/Whisptator/Audio`) — UserDefaults key `audioSaveLocation`

When `saveAudioFiles` is true, `DictationOrchestrator` writes the recorded audio buffer to a WAV file at the specified location after recording stops (before transcription). The filename includes a timestamp.

### D4: Logs tab UI

A new `LogsSettingsTab` view added to the `SettingsView` TabView. It contains a scrollable `List` or `ScrollView` of log entries, newest first. Each entry shows:
- Timestamp (HH:MM:SS)
- Category badge (colored pill)
- Message text

The list auto-scrolls to the newest entry. A "Clear" button clears all entries. The view uses `onReceive` or a timer to poll for updates (or binds directly to the `@Observable` log store).

### D5: Audio file saving in DictationOrchestrator

When `settings.saveAudioFiles` is true, after `stopRecordingAndTranscribe()` stops the microphone, the recorded audio buffer is written to a WAV file at `settings.audioSaveLocation` before transcription begins. The filename includes a timestamp: `dictation_YYYY-MM-DD_HH-mm-ss.wav`.

A new `AudioFileSaver` utility class handles WAV file writing (PCM 16-bit mono WAV format).

## Risks and Trade-offs

- In-memory log store grows unboundedly — mitigated by a cap of 1000 entries (oldest auto-evicted)
- WAV file writing adds I/O latency to the dictation flow — mitigated by writing on a background queue; the user won't notice since transcription is async anyway
- The singleton logger pattern makes testing slightly harder — mitigated by making the logger injectable via protocol

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Log storage | In-memory `@Observable` array | Simple, no persistence needed, auto-updates UI |
| Log format | `LogEntry` struct with timestamp, category, message | Structured, easy to display and filter |
| Audio file format | WAV (16-bit PCM, 16kHz mono) | Matches transcription format, universally playable |
| Audio save timing | After mic stop, before transcription | Non-blocking for the user; transcription is async |
| Settings UI | New tab for Logs; inline controls in Dictation tab | Follows existing SettingsView pattern |
