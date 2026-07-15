## Why

There is no lightweight, privacy-first dictation and meeting recording app for macOS that runs entirely on-device using open-weight Whisper models. Existing solutions either depend on cloud APIs (privacy risk), use proprietary engines, or are heavyweight Electron apps. Whisptator fills this gap: a native Swift menu bar app that transcribes speech using the user's local Whisper Large-v3 Turbo CoreML model, pastes text into any app system-wide, and records meetings with system audio + microphone — all without data leaving the Mac.

## What Changes

- **New macOS menu bar application** — native Swift/SwiftUI, non-intrusive, always-available status item
- **System-wide dictation** — global hotkey triggers recording, transcribed text is pasted into the frontmost app via clipboard (Cmd+V) or typing simulation (CGEvent), configurable per user preference
- **Push-to-talk and hands-free modes** — hold a key for short dictation, or tap a toggle for longer sessions; both shortcuts configurable in Settings
- **On-device speech-to-text** — uses speech-swift's WhisperASR module with the aufklarer Whisper Large-v3 Turbo CoreML bundle (1.56 GB, 1.40% WER, 11× realtime on M5 Pro)
- **Model management** — fixed catalog of known Whisper models, downloaded on first launch to ~/Library/Application Support/Whisptator/Models/, with download status indicators in Settings
- **Meeting recording** — System audio (ScreenCaptureKit) + microphone (AVFoundation) captured simultaneously, mixed, transcribed, and saved as text files; audio retention configurable (keep, auto-delete, delete immediately)
- **Deterministic text cleanup pipeline** — filler word removal, custom word replacements, snippet expansion, whitespace normalization; runs in <1ms, no LLM required
- **Settings window** — SwiftUI tabbed interface for General, Dictation, Model, Cleanup, and Meeting configuration
- **Permission management** — guided onboarding for Accessibility, Microphone, and Screen Recording permissions

## Capabilities

### New Capabilities

- `dictation`: System-wide speech-to-text dictation with global hotkeys, push-to-talk and hands-free modes, text pasting into the frontmost application
- `whisper-stt`: On-device speech-to-text engine using speech-swift WhisperASR with CoreML Whisper Large-v3 Turbo model, model download and caching
- `meeting-recording`: Audio recording combining system audio (ScreenCaptureKit) and microphone (AVFoundation), transcription, and file saving
- `text-cleanup`: Deterministic post-transcription text processing pipeline — filler removal, word replacement, snippet expansion, whitespace normalization
- `menu-bar-app`: macOS menu bar application shell with status item, popover UI, floating recording HUD, and settings window
- `hotkey-system`: Global keyboard shortcut monitoring via CGEvent tap, push-to-talk (hold) and hands-free (toggle) modes, shortcut recording and persistence
- `paste-engine`: Text insertion into frontmost app via clipboard (Cmd+V) or CGEvent character-by-character typing, with pasteboard preservation
- `settings-ui`: Tabbed SwiftUI settings window for General, Dictation, Model, Cleanup, and Meeting configuration
- `permissions`: Accessibility, Microphone, and Screen Recording permission checking, onboarding flow, and grant guidance

### Modified Capabilities

None — this is a greenfield project with no existing specs.

## Impact

- **New Swift package** — Package.swift with two targets: `Whisptator` (app) and `WhisptatorCore` (library)
- **External dependency** — speech-swift (branch: main) for WhisperASR and AudioCommon modules
- **System frameworks** — AVFoundation, ScreenCaptureKit, CoreGraphics, CoreML, SwiftUI, AppKit, ServiceManagement
- **User data** — Model cache at ~/Library/Application Support/Whisptator/Models/, meeting transcripts at ~/Documents/Whisptator/Meetings/
- **Permissions required** — Accessibility (global hotkeys + text pasting), Microphone (audio capture), Screen Recording (system audio in meeting mode)
- **Platform** — macOS 15+ (Sequoia), Apple Silicon only (M1/M2/M3/M4)
