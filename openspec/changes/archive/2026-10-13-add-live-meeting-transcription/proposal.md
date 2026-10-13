# Proposal: add-live-meeting-transcription

## Why

Meeting mode today buffers the entire recording in RAM and transcribes it in one batch only after the user stops — meaning no text during the meeting, ~700 MB RAM per hour of audio, total loss on crash, and no speaker attribution. The spec also promises audio retention, but the implementation never saves meeting audio at all. Users need a meeting recorder whose transcript and audio are written live, are crash-durable, and (optionally) identify who spoke.

## What Changes

- **BREAKING — Meeting mode becomes a live pipeline.** The stop-triggered batch transcription is replaced by continuous VAD-chunked transcription running during the recording. The `transcribing` state at stop time goes away (a short final-pass phase remains only when speaker identification is enabled).
- Transcript is **appended line-by-line** to a text file in the user-configurable meeting save directory, with `[HH:MM:SS]` timestamps aligned to the recording timeline.
- Audio is captured as **two discrete channels instead of a mono mixdown** (microphone = left, system = right). `AudioMixer`'s mono downmix is removed from the meeting path.
- **MP3 is streamed to disk live** alongside the transcript (LAME incremental encoding with periodic flush), so a crash loses at most the last flush window of audio and transcript.
- **Mic mute/unmute** during a meeting via a configurable global shortcut and a button in the live UI; muted mic audio is written as silence (timeline preserved).
- **Speaker identification (optional, off by default):** after stop, a local pyannote diarization model runs over the recording; the transcript file is rewritten with speaker labels. "You" is inferred for free from the microphone channel. Pyannote is the engine for this version; the design keeps the diarizer behind an abstraction for future replacement.
- **Live transcript panel:** a new movable, resizable floating panel showing transcript lines as they land (file-watched), with auto-scroll that yields to manual scrolling and resumes when the user returns the view to the bottom.

## Capabilities

### New Capabilities

- `live-transcription`: VAD-based chunking of the incoming audio stream, per-chunk Whisper transcription on a background worker, timestamped transcript line appends, ordering and crash-durability guarantees.
- `speaker-diarization`: optional post-recording, on-device speaker segmentation and labeling (pyannote for this release), microphone-channel self-speaker heuristic, transcript rewrite with speaker tags.
- `live-transcript-panel`: movable/resizable floating panel rendering the live transcript, file-change-driven updates, auto-scroll engagement/disengagement semantics.

### Modified Capabilities

- `meeting-recording`: start/stop flow redefined for the live pipeline (recording now implies transcription in progress); mono-mix requirement replaced by stereo two-channel capture; transcript-saving requirement extended with live append semantics, mp3-alongside saving, configurable directory behavior; mute/unmute shortcut and button added; retention policy now governs the live-encoded .mp3.

## Impact

- **Code:** `MeetingRecorder` (rewritten as orchestrator), `AudioMixer` (retired from meeting path), `MP3Encoder` (batch API → streaming API), `TranscriptSaver` (write-once → append + rewrite for diarized pass), `TranscriptionEngine` (reused per chunk), `HotkeyMonitor`/`AppSettings` (mute shortcut + diarization/panel settings), new components: VAD segmenter, streaming mp3 writer, transcript file watcher, live panel window/view, diarization service.
- **Dependencies:** new on-device diarization model (pyannote speaker-diarization-3.1 weights as ONNX via onnxruntime-swift-package-manager, fetched from the ungated onnx-community exports — segmentation-3.0 MIT, wespeaker embedding CC-BY-4.0 attribution) downloaded alongside the Whisper model.
- **Permissions:** unchanged (Screen Recording, Microphone already required for meeting mode).
- **Settings UI:** Meeting tab gains speaker-ID toggle, mute shortcut recorder; panel settings (position/size persisted).
- **Tests:** segmenter, line format, streaming encoder flush semantics, diarization pipeline integration, panel scroll-state logic.
