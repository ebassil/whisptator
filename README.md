# Whisptator

A lightweight, privacy-first dictation and meeting recording app for macOS that runs entirely on-device using open-weight Whisper models.

Whisptator is a native Swift menu bar application that transcribes speech using the local Whisper Large-v3 Turbo CoreML model, pastes text into any app system-wide, and records meetings with system audio + microphone — all without data leaving your Mac.

## Requirements

- **macOS 15+** (Sequoia)
- **Apple Silicon** Mac (M1/M2/M3/M4/M5)
- **Accessibility** permission (for global hotkeys and text pasting)
- **Microphone** permission (for audio recording)
- **Screen Recording** permission (optional, for system audio in meeting mode)

## Getting Started

### Building and Running

The project includes a `Makefile` that wraps `swift build` and bundles the binary into a proper `.app` with an `Info.plist`. This is required for macOS to grant microphone and screen recording permissions — bare executables from `swift run` do not appear in System Settings → Privacy & Security.

```bash
# Clone the repository
git clone <repo-url>
cd whisptator
```

#### Available targets

| Target | Description |
|--------|-------------|
| `make build-debug` | Build debug binary, wrap in `.app` bundle, codesign |
| `make build-release` | Build release binary, wrap in `.app` bundle, codesign |
| `make run-debug` | Build debug and launch the app |
| `make run-release` | Build release and launch the app |
| `make clean` | Remove `.app` bundles and build artifacts |

#### Debug build

```bash
make build-debug    # Build and bundle into .build/debug/Whisptator.app
make run-debug      # Build and launch the app
```

#### Release build

```bash
make build-release  # Build and bundle into .build/release/Whisptator.app
make run-release    # Build and launch the app
```

#### Clean

```bash
make clean          # Remove .app bundles and build artifacts
```

#### What the Makefile does

Each build target performs three steps:

1. **Compiles** the binary via `swift build` (debug or release)
2. **Creates an `.app` bundle** with the binary and an `Info.plist` containing `NSMicrophoneUsageDescription` and `NSScreenCaptureUsageDescription`
3. **Re-signs the `.app`** via `codesign` so the code signing identifier matches `CFBundleIdentifier` — without this, macOS TCC cannot associate the Info.plist permissions with the running process and the app won't appear in the Microphone or Screen Recording privacy lists

#### Code Signing

Debug builds are signed ad-hoc by default (`--sign -`), which is sufficient for local development. To sign with a Developer ID for distribution:

```bash
make build-release CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

You can verify the signing after building:

```bash
codesign -dv .build/debug/Whisptator.app
# Should show: Identifier=com.whisptator.Whisptator
# Should show: Info.plist=bound
```

#### Using Xcode (Alternative)

You can also build and archive directly from Xcode:

```bash
open Package.swift

# In Xcode: Product → Archive, then Distribute App
```

Xcode automatically wraps the executable in an `.app` bundle with proper permissions support.

### First Launch

1. On first launch, Whisptator shows an onboarding dialog requesting permissions
2. Grant **Accessibility** permission in System Settings when prompted (required for global hotkeys)
3. Grant **Microphone** permission when prompted (required for recording)
4. Optionally grant **Screen Recording** permission (required only for system audio capture in meetings)
5. The Whisper Large-v3 Turbo model (~1.56 GB) downloads automatically on first use

### Model Download

The CoreML model is downloaded from HuggingFace to `~/Library/Application Support/Whisptator/Models/` on first launch. Progress is shown in the Model settings tab. The model is approximately 1.56 GB and requires an internet connection for the initial download. After that, the app works fully offline.

## Usage

### Dictation

Whisptator lives in the menu bar. Click the mic icon to access controls, or use keyboard shortcuts from any app.

**Push-to-talk mode (default):**
- Hold the push-to-talk key to record
- Release to stop, transcribe, and paste the text into the focused app

**Hands-free mode:**
- Tap the hands-free key to start recording
- Tap again to stop and paste

A floating HUD appears near the top of the screen during recording, showing a red dot and elapsed time (MM:SS).

**Default shortcuts:**
- Push-to-talk: Fn key
- Hands-free: Fn key
- Meeting start/stop: Cmd+Opt+N (configurable)
- Mic mute during meeting: Not configured (set in Settings → Meeting)

### Meeting Recording

Meetings are transcribed **live** — text lands in the transcript file while you are still in the call.

1. Trigger the meeting shortcut (or use the menu bar). A floating **Live Transcript panel** opens automatically (configurable).
2. The app captures system audio + microphone as two discrete channels (mic = left, system = right; configurable)
3. Transcript lines (`[HH:MM:SS] text`) are appended to `S.txt` and the `.mp3` grows live in the save folder — a crash loses at most the last flush window (≤ 2 s audio, one chunk of text)
4. Mute your microphone mid-meeting via the shortcut or the panel button; muted stretches are recorded as silence and marked `(mic muted)` in the transcript
5. Trigger the shortcut again to stop. Queue drains, files finalize, and (if speaker identification is enabled) a local diarization pass relabels the transcript with `Speaker N:` / `Me:` prefixes

Transcripts and audio are saved to `~/Documents/Whisptator/Meetings/` by default (configurable).

### Text Cleanup

Transcribed text passes through a deterministic cleanup pipeline (when enabled):

1. **Filler removal** — removes "um", "uh", sentence-start "so", "well", "like"
2. **Word replacement** — case-insensitive whole-word replacement (e.g., "aye pee eye" → "API")
3. **Snippet expansion** — trigger phrases expand to longer text (e.g., "my signature" → "Best regards, Emile")
4. **Whitespace normalization** — collapses spaces, fixes punctuation spacing, capitalizes first letter

The pipeline runs in under 1ms for texts up to 5000 characters.

## Configuration

Open Settings from the menu bar or press Cmd+,.

### General Tab

| Setting | Description |
|---------|-------------|
| Launch at login | Register as a login item via ServiceManagement |
| Show in Dock | Toggle Dock visibility (menu bar only when disabled) |
| Permissions | Shows current status of Accessibility, Microphone, Screen Recording |

### Dictation Tab

| Setting | Description |
|---------|-------------|
| Push-to-talk shortcut | Click "Record Shortcut" then press desired keys |
| Hands-free shortcut | Click "Record Shortcut" then press desired keys |
| Paste mode | **Clipboard** (Cmd+V, default) or **Typing** (character-by-character) |
| Language | Auto-detect, English, French, German, Spanish, Japanese, Chinese |

### Model Tab

| Setting | Description |
|---------|-------------|
| Model info | Shows model name, size, and download status |
| Download | Download the selected ASR model (Whisper Large-v3 Turbo CoreML by default) |
| Diarization models | Optional speaker-diarization-3.1 ONNX weights (segmentation-3.0 MIT + wespeaker embedding CC-BY-4.0) — one-click download, no token needed |

> The diarization models come from the public `onnx-community` ONNX exports of the exact weights referenced by [pyannote/speaker-diarization-3.1](https://huggingface.co/pyannote/speaker-diarization-3.1) — no Hugging Face account required. They are only fetched when you enable **Speaker identification** in the Meeting tab, and everything works without them (transcript stays unlabeled).

### Cleanup Tab

| Setting | Description |
|---------|-------------|
| Mode | **Raw** (no processing) or **Clean** (pipeline enabled) |
| Filler words | Toggle individual fillers, add custom ones |
| Word replacements | Trigger → replacement rules with enable/disable |
| Snippets | Trigger → expansion rules with enable/disable |

### Meeting Tab

| Setting | Description |
|---------|-------------|
| Audio source | System + Microphone, Microphone only, or System only |
| Speaker identification | Optional final pass labeling speakers with a local pyannote model (default off) |
| Live transcript panel | Auto-show the floating panel when a meeting starts (default on) |
| Retention | Keep the `.mp3`, delete after transcription, or auto-delete after N days |
| Start/stop shortcut | Configure the meeting recording shortcut |
| Mute shortcut | Global shortcut to mute/unmute the mic during a meeting |
| Save location | Default: `~/Documents/Whisptator/Meetings/` — transcript `.txt` and audio `.mp3` are written live here |

## Architecture

```
Whisptator/
├── Makefile                              # Build, bundle, and run targets
├── Package.swift                          # SPM package definition
├── Sources/
│   ├── Whisptator/                        # App target
│   │   ├── WhisptatorApp.swift            # @main entry point
│   │   ├── MenuBarView.swift              # Menu bar menu
│   │   ├── SettingsView.swift             # Tabbed settings UI
│   │   └── OnboardingView.swift           # First-launch permissions
│   └── WhisptatorCore/                    # Library target
│       ├── Audio/
│       │   ├── AudioDeviceManager.swift   # AVCaptureDevice enumeration
│       │   ├── MicrophoneCapture.swift    # Audio capture → Float32 buffer
│       │   ├── MP3Encoder.swift           # Streaming + batch LAME encoder
│       │   ├── LameStreamSink.swift       # Live .mp3 file sink with periodic fsync
│       │   └── AudioFileSaver.swift       # Dictation .wav/.mp3 saving
│       ├── STT/
│       │   ├── ModelManager.swift         # Whisper model download/load
│       │   └── TranscriptionEngine.swift  # Async transcription wrapper
│       ├── Hotkeys/
│       │   ├── HotkeyMonitor.swift        # CGEvent tap on dedicated thread
│       │   └── ShortcutRecorder.swift     # SwiftUI shortcut capture control
│       ├── Paste/
│       │   ├── ClipboardPaster.swift      # Cmd+V with pasteboard save/restore
│       │   ├── TypingPaster.swift         # CGEvent character-by-character
│       │   └── PasteEngine.swift          # Mode selector
│       ├── TextProcessing/
│       │   ├── TextCleanupPipeline.swift  # Orchestrator
│       │   ├── FillerRemover.swift        # Filler word removal
│       │   ├── WordReplacer.swift         # Word replacement rules
│       │   ├── SnippetExpander.swift      # Snippet expansion
│       │   └── WhitespaceCleaner.swift    # Whitespace normalization
│       ├── Meeting/
│       │   ├── SystemAudioCapture.swift   # ScreenCaptureKit audio (48 kHz)
│       │   ├── StereoAligner.swift        # Pairs mic/system buffers on one frame timeline
│       │   ├── LiveMeetingPipeline.swift  # Streaming orchestrator (sink + segmenter fan-out)
│       │   ├── EnergyVADSegmenter.swift   # Speech detection & chunking (400 ms cut, 30 s cap)
│       │   ├── ChunkQueue.swift           # Bounded pending-chunk queue (drops oldest)
│       │   ├── ChunkTranscriber.swift     # Single-lane Whisper worker, ordered writes
│       │   ├── TranscriptWriter.swift     # Durable [HH:MM:SS] line appends (fsync per line)
│       │   ├── TranscriptRelabeler.swift  # Speaker relabeling with atomic write-back
│       │   ├── SpeakerDiarizer.swift      # Engine abstraction for diarization
│       │   ├── MeetingRecorder.swift      # Live session orchestration (states, mute, hotkeys)
│       │   └── TranscriptSaver.swift      # Legacy saving + old-file cleanup (.mp3/.wav)
│       ├── Diarization/
│       │   ├── PyannoteDiarizer.swift     # ONNX segmentation + embeddings + clustering
│       │   ├── OrtModel.swift             # ONNX Runtime session wrapper
│       │   ├── LogMelExtractor.swift      # 16 kHz log-mel features (FFT + filterbank)
│       │   ├── WeSpeakerFbank.swift       # Kaldi 80-bin fbank for the embedding model
│       │   ├── AgglomerativeClustering.swift
│       │   └── DiarizationModelStore.swift# Downloads for the diarization ONNX models
│       ├── Panel/
│       │   ├── LiveTranscriptPanel.swift  # Floating panel (NSPanel + SwiftUI) + controller
│       │   ├── TranscriptFileWatcher.swift# DispatchSource tail reads, reload on atomic rename
│       │   └── AutoScrollController.swift # Pinned/free auto-scroll state machine
│       ├── Settings/
│       │   └── AppSettings.swift          # UserDefaults wrapper
│       ├── Permissions/
│       │   └── PermissionGate.swift       # Permission checks
│       ├── DictationOrchestrator.swift    # Dictation flow controller
│       └── FloatingHUD.swift              # Recording indicator panel
└── Sources/WhisptatorTests/
    ├── TextCleanupTests.swift             # Pipeline unit tests
    ├── IntegrationTests.swift             # Integration tests
    ├── EnergyVADSegmenterTests.swift      # Segmentation (silence cut, 30 s cap, padding)
    ├── LiveTranscriptionTests.swift       # Timestamps, ordering, queue overflow
    ├── StreamingMP3Tests.swift            # Live LAME sink (30-min synthetic file)
    ├── LiveSessionIntegrationTests.swift  # Simulated meetings incl. crash durability
    ├── TranscriptRelabelerTests.swift     # Speaker attribution + mel/FFT/clustering
    └── LivePanelTests.swift               # Auto-scroll machine + file watcher
```

### Data Flow

```
Dictation:
  Hotkey (CGEvent) → MicrophoneCapture → [Float32 buffer]
  → TranscriptionEngine (WhisperASR) → raw text
  → TextCleanupPipeline → cleaned text
  → PasteEngine (Clipboard/Typing) → frontmost app

Meeting (live pipeline):
  Meeting shortcut → MeetingRecorder starts captures
  MicrophoneCapture (48 kHz) ─┐
  SystemAudioCapture (48 kHz) ┴→ StereoAligner (mic=L / system=R, mute = zero-fill)
        ├→ LameStreamSink        → S.mp3 grows on disk (encoder flush + fsync ≤ 2 s)
        └→ EnergyVADSegmenter    → speech chunks (cut on 400 ms silence, 30 s cap, 0.2 s pad)
              → ChunkQueue (bounded 60; overflow drops oldest, audio unaffected)
              → ChunkTranscriber (one lane, Whisper per chunk, 16 kHz)
              → TranscriptWriter → S.txt appends `[HH:MM:SS] text` + fsync
  Live panel tails S.txt (file watcher, auto-scroll with manual override)
  Stop → drain queue → (optional) PyannoteDiarizer on S.mp3 system channel
         → TranscriptRelabeler rewrites S.txt with `Speaker N:` / `Me:` (atomic rename)
```

## Debugging

### Console Logs

Whisptator logs to the system console. Use Console.app to view logs:

```bash
# Filter for Whisptator logs
log stream --predicate 'process == "Whisptator"'
```

### Common Issues

**App doesn't appear in Microphone / Screen Recording permissions**
- SwiftPM signs binaries with an auto-generated identifier that doesn't match the Info.plist `CFBundleIdentifier`, so macOS TCC can't associate the permissions
- The Makefile re-signs the `.app` bundle with the correct identifier — always use `make run-debug` or `make run-release` instead of `swift run`
- Verify signing with `codesign -dv .build/debug/Whisptator.app` — you should see `Info.plist=bound`
- Remove a stale TCC entry (reset permission):  
  - `tccutil reset Accessibility com.whisptator.Whisptator` 
  - `tccutil reset Microphone com.whisptator.Whisptator`  
  - `tccutil reset ScreenCapture com.whisptator.Whisptator`

**"Accessibility permission is required"**
- Go to System Settings → Privacy & Security → Accessibility
- Add Whisptator and enable it

**"Audio input device not found"**
- Check that the selected microphone is connected
- Try switching to a different device in Dictation settings

**Model download fails**
- Check internet connection
- The model is ~1.56 GB; ensure sufficient disk space
- Retry from the Model settings tab
- Model files are cached at `~/Library/Application Support/Whisptator/Models/`

**Hotkeys stop working**
- macOS disables slow CGEvent taps; Whisptator re-enables them every 5 seconds
- If persistent, revoke and re-grant Accessibility permission
- Check that no other app is capturing the same key combination

**Paste doesn't appear in target app**
- Ensure Accessibility permission is granted
- Try switching paste mode between Clipboard and Typing
- Some apps block programmatic paste; Typing mode may work better

**Meeting recording has no system audio**
- Screen Recording permission is required for system audio
- Microphone-only mode works without Screen Recording permission
- Check System Settings → Privacy & Security → Screen Recording

**Meeting transcript lags or has gaps**
- Transcript lines land ~2–4 s after the sentence ends; that is normal pipeline latency
- Long pauses in the transcript mean the chunk queue overflowed (Whisper worker lagging, e.g. dictation using the model concurrently). Check the Logs tab for "Chunk queue full" — the `.mp3` stays complete, so the tail can be recovered manually later
- VAD cuts words in noisy rooms? The segmentation constants (`EnergyVADSegmenter.Parameters`) are tunable and are calibrated per room profile

**Speaker labels were not applied**
- Speaker identification is opt-in (Settings → Meeting) and downloads the pyannote speaker-diarization-3.1 ONNX weights once
- Trigger the download from Settings → Model ("Diarization models"); status and any errors are shown there (no token required for the public exports)
- A failed/missing model never blocks recording; the live transcript is kept unlabeled
- Labels are written only in the final pass (after stop); lines whose audio is mic-only are labeled `Me`

**Live transcript panel**
- "Show Live Transcript" in the menu bar opens/focuses the single panel instance; closing it never affects recording
- Auto-scroll follows new lines until you scroll up; returning to within 40 pt of the bottom (or the "N new · Jump to live" pill) resumes following
- Panel position/size are remembered between sessions

### Resetting Settings

```bash
defaults delete com.whisptator.Whisptator
```

### Clearing Model Cache

```bash
rm -rf ~/Library/Application\ Support/Whisptator/Models/
```

### Clearing Meeting Transcripts

```bash
rm -rf ~/Documents/Whisptator/Meetings/
```

## Development

### Project Structure

The project is a Swift Package with two targets:
- **Whisptator** — executable target (app entry point, UI)
- **WhisptatorCore** — library target (all business logic, frameworks)

### Dependencies

- [speech-swift](https://github.com/soniqo/speech-swift) — WhisperASR module for on-device STT
- System frameworks: AVFoundation, ScreenCaptureKit, CoreGraphics, CoreML, SwiftUI, AppKit, ServiceManagement

### Building

```bash
make build-debug              # Build debug .app bundle
make build-release            # Build release .app bundle
make run-debug                # Build and launch debug
make run-release              # Build and launch release
make clean                    # Remove build artifacts
swift test                    # Run tests
```

Override the signing identity for release builds:

```bash
make build-release CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

### Testing

Unit tests cover the text cleanup pipeline and integration points. Run with:

```bash
swift test
```

Tests require Xcode's XCTest framework. The CLI `swift test` may not work without Xcode installed.

## Privacy

Whisptator is designed with privacy as a core principle:

- **100% on-device** — all transcription happens locally using CoreML
- **No network required** — after model download, the app works fully offline
- **No data collection** — no telemetry, analytics, or remote services
- **No cloud APIs** — audio never leaves your Mac
- **Open source** — inspect the code yourself

## License

See LICENSE file for details.

## Acknowledgments

- [speech-swift](https://github.com/soniqo/speech-swift) by soniqo — WhisperASR runtime
- [aufklarer/Whisper-Large-v3-Turbo-CoreML](https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML) — pre-converted CoreML model bundle
- Apple's ScreenCaptureKit, AVFoundation, and CoreML frameworks
