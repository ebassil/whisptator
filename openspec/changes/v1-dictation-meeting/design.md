## Context

Whisptator is a greenfield macOS menu bar application for on-device speech-to-text dictation and meeting recording. The app targets Apple Silicon Macs running macOS 15+ (Sequoia) and uses the Whisper Large-v3 Turbo model via CoreML for speech recognition.

The core technology stack is:
- **Swift 6** with SwiftUI for the application layer
- **speech-swift** (`WhisperASR` module) for on-device STT inference
- **CoreML** (via speech-swift) for Neural Engine accelerated Whisper inference
- **ScreenCaptureKit** for system audio capture in meeting mode
- **AVFoundation** for microphone capture and audio device management
- **CGEvent** taps for global keyboard shortcut monitoring and text insertion

The aufklarer/Whisper-Large-v3-Turbo-CoreML bundle on HuggingFace provides pre-converted CoreML models (MelSpectrogram, AudioEncoder, TextDecoderContextPrefill, TextDecoder) that speech-swift's WhisperASR runtime loads directly. Performance: 1.40% WER on LibriSpeech test-clean, 0.089 RTF (11× realtime), 6.1s model load, 384 MB peak RSS on M5 Pro.

## Goals / Non-Goals

**Goals:**
- System-wide dictation that works in any macOS application
- On-device transcription with no network dependency after model download
- Simple, non-intrusive menu bar interface
- Meeting recording with system audio + microphone mixing
- Deterministic text cleanup pipeline (no LLM)
- Configurable paste mechanism (clipboard or typing)
- Configurable global keyboard shortcuts

**Non-Goals:**
- Live streaming partial transcripts during recording (V2 feature)
- File/URL transcription (V2 feature)
- AI-powered summaries, chat, or text transforms (V2 feature)
- CLI tool or automation surface (V2 feature)
- Meeting calendar integration (V2 feature)
- Speaker diarization (V2 feature)
- Multiple model support beyond Whisper Large-v3 Turbo (V2 feature)
- App Store distribution (direct DMG distribution)

## Decisions

### D1: speech-swift WhisperASR over DIY CoreML inference

**Choice:** Use speech-swift's `WhisperASR` SPM product as the STT engine.

**Rationale:** speech-swift provides a proven, benchmarked CoreML Whisper runtime that handles mel spectrogram computation, encoder/decoder orchestration, token decoding, language detection, and 30-second chunking. Building this from scratch would take 2-3 weeks and yield no meaningful advantage for V1. The `WhisperASR` module is self-contained — importing it does not pull in MLX or other speech-swift models.

**Alternatives considered:**
- *DIY CoreML pipeline:* Load the 4 .mlmodelc bundles directly via CoreML framework. More control, but significant implementation effort for mel spectrogram preprocessing, KV-cache management, token decoding, and language detection. Deferred to V2 if custom inference behavior is needed.
- *WhisperKit (Argmax OSS):* Proven but heavier dependency (swift-transformers, larger download). speech-swift's WhisperASR is lighter and already benchmarks better (6.1s load vs 100.2s for WhisperKit on same hardware).

### D2: Menu bar app via MenuBarExtra

**Choice:** Use SwiftUI `MenuBarExtra` (macOS 13+) for the app shell.

**Rationale:** Menu bar placement is non-intrusive and matches the "always available but never in the way" UX. `MenuBarExtra` is the modern SwiftUI API for this. The app can optionally show in Dock via a setting.

**Alternatives considered:**
- *NSStatusItem with NSMenu:* More control but more boilerplate. `MenuBarExtra` is sufficient for V1.
- *Full window app:* Too heavyweight for a dictation tool that should be invisible until triggered.

### D3: CGEvent tap for global hotkeys

**Choice:** Use a CGEvent tap on a dedicated thread with its own RunLoop for global keyboard shortcut monitoring.

**Rationale:** This is the proven pattern used by macparakeet and other macOS dictation tools. CGEvent taps receive all keyboard events system-wide, can match complex modifier+key combinations, and work regardless of which app has focus. The tap must be re-enabled periodically because macOS disables taps that are too slow (macparakeet pattern).

**Alternatives considered:**
- *NSEvent.addGlobalMonitorForEvents:* Simpler API but cannot suppress or modify events, and has limitations with certain key combinations. Less reliable for push-to-talk where we need key-up detection.
- *Third-party hotkey libraries:* Unnecessary dependency for well-understood CGEvent patterns.

### D4: Dual paste mechanism (clipboard + typing)

**Choice:** Implement both clipboard (Cmd+V) and CGEvent character-by-character typing, configurable in Settings, defaulting to clipboard.

**Rationale:** Clipboard paste is universal, fast, and works with rich text fields. CGEvent typing simulates keyboard input character-by-character, which is slower but appears as real typing (useful for apps that reject pasted content). Users choose what works for their workflow.

**Alternatives considered:**
- *Clipboard only:* Simpler but doesn't work with all input methods/apps.
- *Typing only:* Too slow for long text, breaks with some Unicode characters.
- *AXUIElement setStringValue:* Only works with specific text field types, not universal.

### D5: ScreenCaptureKit for system audio capture

**Choice:** Use ScreenCaptureKit with `capturesAudio: true` for system audio capture in meeting mode, mixed with AVFoundation microphone capture via AVAudioEngine.

**Rationale:** ScreenCaptureKit is Apple's supported API for system audio capture on macOS 12+. No kernel extensions or virtual audio drivers needed. The `excludesCurrentProcessAudio` flag prevents capturing the app's own sounds. Mixing with microphone audio uses AVAudioEngine's mixer node.

**Alternatives considered:**
- *BlackHole/Soundflower virtual audio devices:* Requires kernel extension installation, fragile across OS updates, admin access needed.
- *CATap API (macOS 13+):* Better synchronization and drift correction, but more complex API. Consider for V2 if sync issues arise.

### D6: Deterministic text cleanup pipeline

**Choice:** Build a deterministic, ordered pipeline: filler removal → word replacement → snippet expansion → whitespace normalization. No LLM involved.

**Rationale:** The pipeline runs in <1ms, is fully predictable, and requires no network or model inference. Each step is independently testable. The user configures which steps are active and their rules via Settings.

**Alternatives considered:**
- *LLM-based cleanup:* Overkill for deterministic transformations, adds latency and network dependency.
- *Apple NaturalLanguage framework:* Useful for sentence boundary detection but not for the specific transformations needed.

### D7: Model download to ~/Library/Application Support/

**Choice:** Download the CoreML model bundle to `~/Library/Application Support/Whisptator/Models/` on first launch, using speech-swift's `fromPretrained(cacheDir:)` API.

**Rationale:** Keeps model files out of the app bundle (which would be 1.6+ GB), follows macOS conventions for application support data, and matches macparakeet's pattern. The `cacheDir:` parameter on `WhisperASRModel.fromPretrained()` allows specifying a custom download location.

**Alternatives considered:**
- *Bundled in app:* Makes the app bundle 1.6+ GB, complicates updates.
- *System-level cache:* Overly aggressive cleanup by macOS could delete models.

### D8: Floating HUD panel during recording

**Choice:** Show a small `NSPanel` with `.floating` window level during active recording, displaying a timer and recording status.

**Rationale:** Gives the user visual feedback that recording is active without requiring them to look at the menu bar. The panel is dismissed when recording stops. For V1, shows only a timer (no partial transcripts).

**Alternatives considered:**
- *Menu bar text update:* Too small to notice.
- *Notification:* Only shows after recording, not during.

## Risks / Trade-offs

- **[CGEvent tap reliability]** → macOS can disable slow CGEvent taps. Mitigation: Re-enable the tap periodically (every 5 seconds) and check `AXIsProcessTrusted()` on each activation. Show warning in Settings if Accessibility permission is not granted.

- **[ScreenCaptureKit sync issues]** → System audio and microphone streams can drift out of sync. Mitigation: For V1, accept minor drift. For V2, evaluate CATap API for synchronized capture with drift correction.

- **[Model download failure]** → Network issues during 1.56 GB download. Mitigation: Show download progress, allow retry, handle partial downloads gracefully. speech-swift's HuggingFace downloader handles resume.

- **[WhisperASR 6-second model load]** → First transcription after launch has a delay. Mitigation: Preload the model in background on app launch so it's ready when the user first triggers dictation.

- **[Meeting audio memory usage]** → Long meetings accumulate large PCM buffers in memory. Mitigation: Stream audio chunks to temp files on disk, transcribe in chunks, concatenate transcripts. Not in V1 — V1 keeps full buffer in memory for simplicity.

- **[macOS 15 minimum]** → speech-swift requires macOS 15+ (Sequoia) for the MLState API. Users on macOS 14 cannot run the app. Mitigation: Document requirement clearly. macOS 15 has been available since September 2024.

- **[Clipboard clobbering]** → Clipboard paste mode briefly overwrites the user's pasteboard. Mitigation: Save original pasteboard contents before paste, restore immediately after (100ms delay). This is the standard pattern used by all clipboard-manipulating tools.
