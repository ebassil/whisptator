# Design: add-live-meeting-transcription

## Context

Meeting mode (`MeetingRecorder`) currently accumulates every `AVAudioPCMBuffer` into an in-memory array and calls `TranscriptionEngine.transcribe(audio:sampleRate:)` once with the full recording after stop. Consequences: zero text during the meeting, ~700 MB RAM/hour (mono 48 kHz Float32), total loss on crash, no timestamps below the whole-file level, and no audio persisted at all despite the retention spec. Infrastructure that helps already exists but is unused by the meeting path: `MP3Encoder` (LAME via `@_silgen_name`, batch API), `AudioFileSaver` (dictation-only), `meetingSaveLocation` (in `AppSettings`, already configurable).

Constraints:
- All models on-device; no cloud APIs (product principle).
- WhisperASR via soniqo/speech-swift, large-v3-turbo CoreML, reused as-is — chunk-level calls only.
- macOS 15+, Apple Silicon. Existing TCC model (Screen Recording for system audio) unchanged.
- Speaker diarization must be replaceable in a future release (decision made: pyannote for this version only).

## Goals / Non-Goals

**Goals:**
- Transcript lines land in the output file within ~2–4 s of speech ending, while recording is still running.
- MP3 (stereo: mic left / system right) grows live on disk; a crash loses at most the last flush interval.
- Optional final-pass speaker labels with global accuracy and zero impact on live latency.
- A floating, movable/resizable transcript panel with tail-following auto-scroll.
- Mic mute/unmute mid-meeting without breaking audio/timeline sync.

**Non-Goals:**
- Live speaker labels (labels arrive in the final pass only).
- Word-level timestamps, translation, summarization, post-meeting editing UX.
- Replacing Whisper or exposing a diarization-model picker in settings.
- Changes to dictation mode or the paste pipeline.
- `.wav` retention for meetings (retention now governs the `.mp3`).

## Decisions

### D1. Streaming topology — single fan-out, two independent sinks

```
 start/stop hotkey ──▶ MeetingRecorder (orchestrator, now "LiveMeetingSession")
        │
   mic (AVAudioEngine) ──┐ 48 kHz PCM buffers
   system (SCKit) ───────┘        │
                    ┌─────────────┴──────────────┐
                    │  Aligner (pair L/R frames, │
                    │  zero-fill missing channel)│
                    └───────┬────────────┬───────┘
                 stereo PCM │            │ stereo PCM
              ┌─────────────▼──┐   ┌─────▼──────────────┐
              │ LameStreamSink │   │ SpeechSegmenter    │
              │ encodeChunk →  │   │ energy VAD on L+R  │
              │ FileHandle .mp3│   │ (mono fold just    │
              │ flush ≤2 s     │   │  for detection)    │
              └────────────────┘   └─────┬──────────────┘
                    │                    │ cut on silence ≥ 400 ms
              (crash: ≤2 s lost)         │ or hard cap 30 s
                                         ▼
                                  ChunkQueue (ordered,
                                         │  bounded 60 chunks)
                                         ▼
                                  Whisper worker (1 lane)
                                         │ [HH:MM:SS] text
                                         ▼
                                  TranscriptWriter (serial
                                  FileHandle append + fsync)
```

Rationale: the mp3 path and transcript path share only the aligned buffer feed. They crash-recover independently, and slow transcription never throttles audio capture. Alternatives rejected: (a) transcribe-from-mp3-decoded-file (adds a decode dependency and latency coupling); (b) one shared ring buffer (needless coordination).

### D2. Timeline clock — frame offsets, not wall clock

`startFrame`/`endFrame` (48 kHz sample indices) are the canonical recording timeline; `[HH:MM:SS]` is derived from `startFrame / 48000`. Muting zero-fills the left channel rather than pausing capture, so frames never stop advancing and mp3 ↔ transcript ↔ diarization segments all align without bookkeeping. Wall-clock timestamps would drift from the audio file under load.

### D3. Segmentation — energy VAD now, pluggable later

`SpeechSegmenter` protocol with an RMS/energy implementation first: silence threshold adaptive to a noise floor estimate, cut at ≥ 400 ms silence or forced cut at 30 s, discard segments < 300 ms (no speech), 0.2 s head/tail padding (decoded from the same aligned stream) to avoid clipped words. Silero VAD (small ONNX, Apache-2.0) is the planned upgrade if energy VAD mis-cuts on music/keyboard backgrounds; the protocol keeps that swap local. Whisper's 30-s window and Turbo's speed (≈ 20× real-time on M-series) make one-lane, order-preserving queueing safe: steady state keeps up trivially; bounded queue (60 chunks ≈ 30 min of audio ≈ 350 MB worst case) prevents pathological growth; overflow drops oldest *transcription* work (never audio) with a logged warning — the transcript lags but the mp3 stays complete.

### D4. Stereo channels replace the mono downmix; `AudioMixer` retires

The meeting path feeds both streams through an Aligner that produces interleaved 2-channel buffers (mic = L, system = R; "mic only" records mono; "system only" records mono — no fake stereo). `AudioMixer`'s `/2` mono mix is removed from meeting use (its averaging also halved levels and made diarization of remote voices much harder). This is what makes "Me" free in D7 and keeps LAME's `lame_encode_buffer_interleaved` applicable.

### D5. MP3Encoder becomes a streaming API

Refactor to: `init(sampleRate:channels:bitrate:)`, `append(interleavedSamples) -> Data` (encoded bytes so far), `finish() -> Data` (flush remainder). LAME itself is streaming-capable; the batch file-writing loop in `encode(samples:to:)` is what's wrong, not the codec. The sink writes bytes to a `FileHandle` opened at session start; `scheduleFlush(every: 2 s)` performs `synchronise()` (fsync). Survives app crash (OS has the bytes); a full power loss loses ≤ 2 s. Same pattern for the transcript writer: append + fsync per line batch.

### D6. Transcript format and the two-file convention

- Audio: `meeting_<yyyy-MM-dd_HH-mm>/` session stem `S`; files `S.txt` and `S.mp3` share the stem so downstream tools (and the diarizer) can pair them.
- Live line: `[HH:MM:SS] text` (one line per chunk, cleaned by `TextCleanupPipeline` per line when Clean mode is on).
- Diarized line (final pass): `[HH:MM:SS] <Speaker>: text`.
- Session settings (save dir) snapshot at start; mid-meeting settings changes apply next session.

### D7. Diarization = final-pass, pyannote, mic-channel shortcut

On stop with diarization ON: after the chunk queue drains, decode `S.mp3` (AVAudioFile → PCM), split channels at 16 kHz mono. Left channel (mic, non-silent portions) → label **"Me"** without a model — the user's identity is known. Right channel → pyannote pipeline: segmentation model (multi-label speech activity) → per-speaker embedding (wespeaker pyannote-community) → agglomerative clustering → merged segments with speaker IDs. Speaker N numbered by first appearance across the meeting. For each transcript line, the diarization segment overlapping its `[start, start+approx duration)` on the system channel supplies the label; lines whose time window is mic-dominant get "Me". The rewrite is temp-file + atomic rename (crash-safe; either the live transcript or the diarized transcript is always fully present). Pluggability: `SpeakerDiarizer` protocol + `PyannoteDiarizer` implementation so a future macOS-26 `SpeechSeparator`-based or CoreML-native swap is a one-class change.

Alternatives rejected: live per-chunk labeling (identity instability, per-chunk compute, worse accuracy than global clustering); running pyannote on the mono mix (would now be impossible — good side effect of D4).

### D8. Model sourcing and licensing

Diarization weights are the pyannote speaker-diarization-3.1 pipeline components — segmentation-3.0 (MIT) and wespeaker-voxceleb-resnet34-LM (CC-BY-4.0) — fetched from their ungated `onnx-community` ONNX exports, so no Hugging Face account or token is required. Download manager reuses the `HuggingFaceModelDownloader` pattern (an optional token in the Model tab covers gated repos should sources move). Failure to download degrades to diarization OFF with a visible setting error, never blocks meeting recording.

### D9. Live panel — file-driven, one instance, pinned-to-bottom semantics

`NSPanel` (`.nonactivatingPanel`, `.hud`-like but resizable), backed by SwiftUI, top-level like `OverlayWindow` but interactive. Reads: `DispatchSource` on the transcript fd (plus 1 s timer fallback for network volumes), incremental tail read via saved offset; on file size < offset (atomic rename from D7 rewrite) → reload from 0. Auto-scroll state machine:

```
        ┌──────────┐  new line & pinned   ┌────────────┐
        │ PINNED   │─────────────────────▶│ render,    │
        │ (follow) │                      │ scrollToEnd│
        └──────────┘                      └────────────┘
            ▲  ▲                               │
 scroll     │  │ user scrolls to               │ user scrolls up/
 within     │  │ within 40pt of bottom         │ drags anywhere
 40pt gap ──┘  └───────────────────────────────┘
        ┌──────────┐
        │ FREE     │  new lines do NOT move the viewport
        │ (viewing)│  (a "N new · Jump to live ▾" pill appears)
        └──────────┘
```

Position/size persisted via `NSStringFromRect` in `AppSettings`; opened from menu bar ("Show Live Transcript") and auto-shown on meeting start (setting). Contains: transcript list, mic-mute button + state, elapsed timer, stop button, diarization status line. Mute is also available in the menu bar and via the configurable global shortcut (pattern identical to `meetingShortcut`).

### D10. Mute semantics

Global shortcut and panel button toggle `micMuted` for the current session. While muted the Aligner zero-fills the left channel; the mic capture keeps running (no AVAudioEngine restart glitches); muted duration appears in the panel and a `[HH:MM:SS] (mic muted)` marker line is appended on each toggle so transcript readers can interpret silence.

### D11. State machine and overlay reuse

`MeetingState` becomes `idle → recording → finalizing(only if diarization ON) → idle` — the old `transcribing` state disappears (transcription is continuous). During `recording`, chunk transcriptions land asynchronously; the overlay keeps its recording animation, `TranscribingAnimationView` is reused for `finalizing`. Menu bar shows "LIVE ●" while recording and a diarize spinner while finalizing.

## Risks / Trade-offs

- [Energy VAD cuts mid-sentence on noisy rooms / music] → head/tail padding + max-30 s safety; segmenter protocol allows Silero upgrade without touching callers.
- [Whisper worker stalls (huge backlog, e.g., 3-hour call with dictation hogging the model)] → bounded queue with audio-safe drop policy (mp3 remains complete, transcript lags and can be re-run from mp3 later is NOT supported this release — documented gap); model-sharing arbitration: dictation gets priority lane, meeting worker pauses if dictation request in flight.
- [HF export repos disappear or change] → diarization is opt-in; repo ids isolated in `DiarizationModelStore.Repos`; clear error + graceful degrade to unlabeled transcript.
- [LAME interleave/thread-safety] → encode only on the session's serial audio-queue context; FileHandle writes on the same lane; unit test with synthetic 30-min stereo run.
- [Diarized rewrite races a still-open panel / editor] → atomic rename; panel detects truncation and reloads; document that external editors should reopen after finalize.
- ["Me" mislabels when user speaks on speakerphone (mic hears remote voices)] → accepted v1 limitation; diarizer still sees system channel, so remote audio is also in left channel — mitigation: right channel wins when both active (overlap rule in D7), noted as known issue.
- [License] segmentation-3.0 export is MIT, wespeaker embedding export is CC-BY-4.0 (attribution required); abstraction + design note keep replacement cheap if either source changes.

## Migration Plan

No data migration. Settings additions default sensibly (diarization OFF, panel auto-show ON, mute shortcut unset). Old `mixedBuffers` batch path is deleted in the `MeetingRecorder` rewrite — rollback = revert commit. `cleanupOldAudioFiles` extends its filter from `.wav` to `.wav`+`.mp3` (keeps cleaning any legacy files). Specs: `meeting-recording` updated at archive; new capabilities added to `openspec/specs/`.

## Open Questions

- VAD thresholds: initial numbers here (400 ms silence, −45 dBFS-ish adaptive floor, 30 s cap) need a real-meeting calibration pass during implementation (spike: 5 recorded Teams meetings).
- Should `systemAndMicrophone` mode optionally record mono when the user never enables diarization? (Decision pending: default stays stereo — cheap and future-proof.)
- Panel line wrapping / session header block — decided during UI implementation; spec keeps it minimal.
