## 1. Project Setup

- [x] 1.1 Create Package.swift with Whisptator (app) and WhisptatorCore (library) targets, speech-swift dependency
- [x] 1.2 Create directory structure: Sources/Whisptator/, Sources/WhisptatorCore/{Audio,STT,Hotkeys,Paste,TextProcessing,Meeting,Settings}, Sources/WhisptatorTests/
- [x] 1.3 Create WhisptatorApp.swift with @main, MenuBarExtra scene, Settings scene
- [x] 1.4 Verify build compiles with `swift build`

## 2. App Settings

- [x] 2.1 Create AppSettings.swift with UserDefaults wrapper for all settings (shortcuts, paste mode, audio device, language, cleanup rules, meeting config)
- [x] 2.2 Define settings keys and default values for all configuration options
- [x] 2.3 Add shortcut persistence (keyCode + modifier flags for push-to-talk, hands-free, meeting)

## 3. Menu Bar App Shell

- [x] 3.1 Create MenuBarView.swift with status item popover: Start Dictation, Start Meeting, Settings, Quit
- [x] 3.2 Create NSStatusItem setup with app icon
- [x] 3.3 Add "Show in Dock" toggle using NSApp.setActivationPolicy
- [x] 3.4 Add "Launch at login" using SMAppService

## 4. Hotkey System

- [x] 4.1 Create HotkeyMonitor.swift with CGEvent tap on dedicated thread with RunLoop
- [x] 4.2 Implement key-down/key-up event matching against saved shortcuts
- [x] 4.3 Add periodic tap re-enable (every 5 seconds) to prevent macOS from disabling it
- [x] 4.4 Create ShortcutRecorder.swift — NSViewRepresentable shortcut capture control for SwiftUI Settings
- [x] 4.5 Wire shortcut changes from Settings to HotkeyMonitor

## 5. Audio Capture — Microphone

- [x] 5.1 Create AudioDeviceManager.swift — list available audio input devices using AVCaptureDevice
- [x] 5.2 Create MicrophoneCapture.swift — AVFoundation audio capture to in-memory Float32 buffer
- [x] 5.3 Implement start/stop recording, sample rate detection, audio format conversion
- [x] 5.4 Add audio preprocessing: convert captured audio to 16 kHz mono Float32 for WhisperASR

## 6. STT Engine

- [x] 6.1 Create ModelManager.swift — download model via speech-swift's fromPretrained(cacheDir:) to ~/Library/Application Support/Whisptator/Models/
- [x] 6.2 Implement download progress reporting, offline mode, download status tracking
- [x] 6.3 Create TranscriptionEngine.swift — wrap WhisperASRModel, expose async transcribe(audio:sampleRate:language:) API
- [x] 6.4 Add background model preload on app launch

## 7. Paste Engine

- [x] 7.1 Create ClipboardPaster.swift — save pasteboard, set text, simulate Cmd+V, wait 100ms, restore pasteboard
- [x] 7.2 Create TypingPaster.swift — CGEvent character-by-character typing with modifier key handling
- [x] 7.3 Add paste mode selection (clipboard vs typing) wired to AppSettings

## 8. Text Cleanup Pipeline

- [x] 8.1 Create TextCleanupPipeline.swift — ordered pipeline orchestrator: fillers → replacements → snippets → whitespace
- [x] 8.2 Create FillerRemover.swift — remove configured filler words, sentence-start fillers
- [x] 8.3 Create WordReplacer.swift — case-insensitive whole-word replacement with toggle support
- [x] 8.4 Create SnippetExpander.swift — longest-first trigger matching for snippet expansion
- [x] 8.5 Create WhitespaceCleaner.swift — collapse spaces, fix punctuation spacing, capitalize first letter
- [x] 8.6 Add unit tests for each cleanup step and the full pipeline

## 9. Dictation Flow Orchestrator

- [x] 9.1 Wire HotkeyMonitor → MicrophoneCapture start/stop on key down/up (push-to-talk)
- [x] 9.2 Wire HotkeyMonitor → MicrophoneCapture toggle on tap (hands-free)
- [x] 9.3 Wire MicrophoneCapture buffer → TranscriptionEngine → TextCleanupPipeline → PasteEngine
- [x] 9.4 Add error handling: model not loaded, audio capture failed, paste failed
- [x] 9.5 Add dictation status state machine: idle → recording → transcribing → pasting → idle

## 10. Floating HUD

- [x] 10.1 Create FloatingHUD.swift — NSPanel with .floating level, recording indicator, elapsed timer
- [x] 10.2 Wire HUD show/hide to dictation and meeting recording state
- [x] 10.3 Position HUD near top-center of screen
- [x] 10.4 Add 500ms dismiss delay after recording stops

## 11. Meeting Recording

- [x] 11.1 Create SystemAudioCapture.swift — ScreenCaptureKit with capturesAudio, excludesCurrentProcessAudio
- [x] 11.2 Create AudioMixer.swift — mix system audio and microphone streams via AVAudioEngine mixer
- [x] 11.3 Create MeetingRecorder.swift — orchestrate start/stop, accumulate mixed PCM buffer
- [x] 11.4 Create TranscriptSaver.swift — save transcript to ~/Documents/Whisptator/Meetings/ with timestamped filename
- [x] 11.5 Implement audio retention policies: keep, delete after transcription, auto-delete after N days
- [x] 11.6 Wire meeting shortcut from HotkeyMonitor to MeetingRecorder
- [x] 11.7 Add menu bar recording indicator during active meeting

## 12. Settings UI

- [x] 12.1 Create SettingsView.swift — tabbed SwiftUI Settings scene with General, Dictation, Model, Cleanup, Meeting tabs
- [x] 12.2 Build General tab: launch at login, dock visibility, permission status indicators
- [x] 12.3 Build Dictation tab: shortcut recorders, paste mode radio, audio device dropdown, language dropdown
- [x] 12.4 Build Model tab: model list with download status, download button, progress indicator
- [x] 12.5 Build Cleanup tab: mode toggle, filler list with toggles, word replacement table, snippet table
- [x] 12.6 Build Meeting tab: audio source radio, retention radio, shortcut recorder, save location

## 13. Permissions

- [x] 13.1 Create PermissionGate.swift — check AXIsProcessTrusted(), microphone permission, screen recording permission
- [x] 13.2 Create first-launch onboarding dialog explaining permissions with grant buttons
- [x] 13.3 Add permission status indicators in General Settings
- [x] 13.4 Handle permission-not-graced gracefully in dictation and meeting flows

## 14. Integration Testing

- [x] 14.1 End-to-end dictation test: hotkey → record → transcribe → paste in a text editor
- [x] 14.2 Meeting recording test: start → capture system+mic → stop → transcript saved
- [x] 14.3 Text cleanup pipeline test with all steps enabled
- [x] 14.4 Settings persistence test: change settings → relaunch → settings preserved
- [x] 14.5 Permission denial test: revoke accessibility → app shows warning, dictation disabled
