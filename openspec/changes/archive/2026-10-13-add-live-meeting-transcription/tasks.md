# Tasks: add-live-meeting-transcription

## 1. Streaming audio foundation

- [x] 1.1 Add `StereoAligner` that pairs mic (left) and system (right) `AVAudioPCMBuffer`s on a shared 48 kHz frame timeline, zero-filling missing/muted channels, and passes mono through in single-source modes
- [x] 1.2 Refactor `MP3Encoder` from batch `encode(samples:to:)` to streaming API: `append(interleavedSamples:) -> Data`, `finish() -> Data`, `channels: 2` support via `lame_encode_buffer_interleaved_ieee_float`
- [x] 1.3 Add `LameStreamSink`: opens session `.mp3` FileHandle, encodes appended stereo buffers, writes bytes, fsyncs every ≤2 s; unit test with synthetic 30-min stereo signal verifying playable output and byte monotonicity

## 2. Segmentation

- [x] 2.1 Define `SpeechSegmenter` protocol (accepts aligned PCM chunks, emits `SpeechSegment{startFrame, endFrame}` asynchronously)
- [x] 2.2 Implement `EnergyVADSegmenter`: adaptive noise-floor RMS detection, cut at ≥400 ms trailing silence, 30 s forced cut, discard <300 ms detections, ~0.2 s head/tail padding from stream history
- [x] 2.3 Unit-test segmenter with synthetic speech/silence patterns: silence cut, max cap mid-speech, padding correctness, mute-induced silence handled without crash

## 3. Live transcription core

- [x] 3.1 Add `SessionTimeline` clock (sample offset ↔ `HH:MM:SS`) and `TranscriptWriter`: serial FileHandle append of `[HH:MM:SS] text` lines, fsync per line batch, marker lines `(mic muted)/(mic unmuted)`
- [x] 3.2 Add bounded `ChunkQueue` (cap 60) and `ChunkTranscriber` worker: consumes segments, downsamples to Whisper input, calls `TranscriptionEngine` per chunk, orders results by segment start, drops oldest with logged gap on overflow
- [x] 3.3 Unit-test line format, timestamp-from-frame math (e.g., frame 34_800_000 → `[00:12:05]`), order preservation under shuffled completions, overflow drop policy

## 4. Live session orchestration

- [x] 4.1 Rewrite `MeetingRecorder` as live session: start creates `S.txt`/`S.mp3` (shared stem, save dir snapshot), wires captures → aligner → (sink, segmenter) → queue → transcriber → writer; states `idle → recording → finalizing? → idle`
- [x] 4.2 Implement stop path: stop captures, drain queue with timeout, close/flush sink, run diarization pass if enabled, else idle; delete audio per retention
- [x] 4.3 Add mic mute toggle: `micMuted` flag zero-fills left channel at aligner, appends marker lines, no effect when idle
- [x] 4.4 Add mute global shortcut: `AppSettings.muteShortcut`, `HotkeyMonitor` registration, ShortcutRecorder UI in Meeting settings tab
- [x] 4.5 Remove `AudioMixer` mono-mix usage from the meeting path (keep class until dictation paths confirmed independent, then delete)
- [x] 4.6 Integration test: simulated 10-min synthetic meeting asserts transcript lines, mp3 duration within flush tolerance, crash simulation mid-session leaves both files intact

## 5. Speaker diarization (final pass)

- [x] 5.1 Define `SpeakerDiarizer` protocol: `(mp3URL) async throws → [DiarizedSegment{start,end,speaker}]`, engine behind the abstraction
- [x] 5.2 Add onnxruntime-swift-package-manager dependency; wire `Speaker identification` toggle in Meeting settings (default OFF)
- [x] 5.3 Implement mp3 decode to 16 kHz mono per channel (AVAudioFile) for the diarizer and mic-dominance classifier (energy per channel over the chunk window; system-channel-wins overlap rule)
- [x] 5.4 Integrate pyannote segmentation + wespeaker embedding + agglomerative clustering for the system channel; label mic-dominant lines `Me`; number remote speakers by first appearance
- [x] 5.5 Add diarization model downloads to ModelManager/`HuggingFaceModelDownloader` path with HF token setting in Model tab; gated-repo auth errors surface in Settings and degrade to diarization OFF
- [x] 5.6 Implement relabel write-back: temp file + atomic rename producing `[HH:MM:SS] Speaker N: text` / `[HH:MM:SS] Me: text`; failure leaves live transcript intact with user-visible notification
- [x] 5.7 Unit-test line→segment attribution and overlap rule with synthetic diarization output; smoke-test end-to-end relabel on a stored sample meeting

## 6. Live transcript panel

- [x] 6.1 Create `LiveTranscriptPanel`: resizable, movable, nonactivating `NSPanel` + SwiftUI list of transcript lines; single-instance open/focus from menu bar item "Show Live Transcript"
- [x] 6.2 Add `TranscriptFileWatcher`: DispatchSource on transcript fd, incremental tail reads from saved offset, full reload when file shrinks (atomic rename detection)
- [x] 6.3 Implement auto-scroll state machine: pinned by default; >40 pt from bottom disengages and freezes viewport with "N new · Jump to live" pill; return within 40 pt or pill re-engages and jumps
- [x] 6.4 Persist panel frame (position/size) in `AppSettings`; restore on reopen and launch
- [x] 6.5 Add panel chrome: elapsed timer, mic mute button bound to authoritative state, stop button, finalizing/diarization status line
- [x] 6.6 Auto-show panel on meeting start (setting `panelAutoShow`, default ON); verify closing panel never affects the session

## 7. Settings, menu bar, overlay integration

- [x] 7.1 Meeting tab: speaker-ID toggle, mute shortcut recorder, save-location picker (live semantics label), retention wording updated to `.mp3`
- [x] 7.2 Menu bar: live recording + mute status items, stop item; `AppCoordinator` wiring for session lifecycle events
- [x] 7.3 Overlay: reuse `TranscribingAnimationView` for the finalizing state only; recording overlay unchanged; confirm no lingering "transcribing" state when diarization OFF
- [x] 7.4 Extend `cleanupOldAudioFiles` to match `.mp3` (and legacy `.wav`); implement delete-after-finalization for `.mp3`

## 8. Verification and docs

- [ ] 8.1 Calibration spike: run 3–5 real recorded meetings; tune VAD silence/threshold constants; document final values
- [ ] 8.2 Manual QA checklist: hotkey start/stop, mute via shortcut + panel, tail -f transcript durability across `kill -9`, panel scroll behavior, diarization on/off, retention modes, permission-denied paths
- [x] 8.3 Update README (data flow, Meeting tab table, model section, troubleshooting) and spec Purpose fields
