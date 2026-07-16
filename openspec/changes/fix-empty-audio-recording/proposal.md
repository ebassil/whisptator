## Why

Recorded dictation audio files saved to `~/Documents/Whisptator/Audio/` are always 52 bytes regardless of recording duration. A 52-byte file contains only a valid WAV header (44 bytes) with zero audio data — the audio samples are never written. This means the "Save audio files" setting produces unusable files, and users who rely on this feature lose access to their raw recordings.

Root cause: In `DictationOrchestrator.stopRecordingAndTranscribe()`, the `currentState` is set to `.transcribing` before the underlying `AVCaptureSession` has fully stopped and delivered all pending audio buffers. The delegate callback `microphoneCapture(_:didCaptureAudio:)` guards on `currentState == .recording`, so the last ~1-2 audio buffers are silently dropped. The `mergeBuffers` call then reads a nearly-empty `recordedBuffers` array, and `AudioFileSaver` writes a WAV with a 44-byte header and almost no sample data.

The same race condition exists in `MeetingRecorder.stopRecording()` — `currentState` switches to `.transcribing` before pending system and microphone buffers are delivered.

## What Changes

- Fix the state transition ordering in `DictationOrchestrator` so `currentState` transitions to `.transcribing` only after all pending audio from `MicrophoneCapture` has been delivered
- Apply the same fix to `MeetingRecorder` where the identical pattern exists
- Coordinate the stop + buffer-drain sequence on `MicrophoneCapture`'s serial queue to eliminate the data race between `mergeBuffers` (main thread) and pending `captureOutput` callbacks (session queue)

## Capabilities

### Modified Capabilities
- `dictation`: Dictation recording state machine — fix stop-to-transcribe transition ordering
- `meeting-recording`: Meeting recording state machine — fix stop-to-transcribe transition ordering

## Impact

- `Sources/WhisptatorCore/DictationOrchestrator.swift` — Restructure `stopRecordingAndTranscribe()` to defer state change
- `Sources/WhisptatorCore/Meeting/MeetingRecorder.swift` — Restructure `stopRecording()` to defer state change
- `Sources/WhisptatorCore/Audio/MicrophoneCapture.swift` — Add completion callback to `stopCapture()` for coordination
- No new dependencies
- No API or public interface changes
- No settings or user-facing impact beyond fixing the empty file bug
