## Context

### Current stop flow (Dictation)

```
Hotkey release → stopRecordingAndTranscribe()
  1. currentState = .transcribing           ← too early, causes buffer drops
  2. microphoneCapture.stopCapture()         ← dispatches async to sessionQueue
  3. mergeBuffers(recordedBuffers)           ← reads recordedBuffers immediately
  4. AudioFileSaver.saveAudioFile(...)       ← writes WAV with near-empty data
```

`AVCaptureAudioDataOutput.setSampleBufferDelegate(_:queue:)` delivers callbacks on a serial `sessionQueue`. `stopCapture()` dispatches `performStopCapture()` to the same queue. The serial queue ensures FIFO ordering: any `captureOutput` call already enqueued will run before `performStopCapture`. However, by the time those pending callbacks execute, `currentState` is already `.transcribing`, so the delegate guard (`guard currentState == .recording`) rejects them.

### Current stop flow (Meeting)

```
meetingRecorder.stopRecording() (async)
  1. currentState = .transcribing           ← same problem
  2. microphoneCapture.stopCapture()         ← dispatches to sessionQueue
  3. await systemAudioCapture.stopCapture()  ← async, different queue
  4. mergeBuffers(mixedBuffers)             ← reads after state change/lost buffers
```

Identical pattern — `currentState` changes before pending buffers arrive.

### Thread safety

`recordedBuffers` in `DictationOrchestrator` is accessed from:
- `sessionQueue` (write, via `microphoneCapture` delegate)
- Main thread (read, via `mergeBuffers` in `stopRecordingAndTranscribe`)

No lock synchronizes these accesses. `MeetingRecorder.mixedBuffers` uses `NSLock` for writes (via `addBuffer(_:)`) but reads in `mergeBuffers` happen without the lock.

## Goals / Non-Goals

**Goals:**
- Dictation audio files contain all recorded samples when "Save audio files" is enabled
- No audio buffers dropped during dictation stop transition
- Same reliability for meeting recording audio
- Thread-safe access to accumulated buffers

**Non-Goals:**
- Changing the audio capture pipeline API
- Adding new user-facing features
- Modifying any existing spec requirements

## Decisions

1. **Completion callback on `MicrophoneCapture.stopCapture`** — Add an optional `completion: @escaping () -> Void` parameter to `stopCapture()`. The callback is invoked on the main queue after `performStopCapture` completes on `sessionQueue`. Because `sessionQueue` is serial and also processes `captureOutput`, this guarantees all pending audio buffers are delivered before the callback fires. Alternative considered: polling `sessionQueue` via `dispatch_barrier_sync`; rejected because it blocks the calling thread.

2. **Defer state change to completion handler** — Move `currentState = .transcribing` and all subsequent processing (merge, save, transcribe) into the completion handler of `stopCapture`. This eliminates the window where pending buffers are rejected by the state guard.

3. **Relax the state guard in delegate** — As a defensive measure, remove `guard currentState == .recording` from `DictationOrchestrator.microphoneCapture(_:didCaptureAudio:)` and only check `isCapturing` on the capture side. This prevents future regressions if state ordering changes again. The array is bounded by `performStopCapture` which runs on the same serial queue.

4. **Same pattern for MeetingRecorder** — Apply Decision 1 and 2 to `MeetingRecorder.stopRecording()`. The `meetingRecorder` already awaits `systemAudioCapture.stopCapture()`; the fix ensures `microphoneCapture.stopCapture` also completes before the state change.

5. **Lock `recordedBuffers` access** — Add an `NSLock` to `DictationOrchestrator` for `recordedBuffers` to guard the data race between the session queue writer and the main thread reader. `MeetingRecorder.mixedBuffers` already has `lock`; ensure `mergeBuffers` acquires it.

## Risks / Trade-offs

- **Completion callback introduces async flow in dictation stop** — The hotkey delegate is already async-tolerant; the overlay controller updates remain on main thread and are unaffected.
- **Minimal latency increase** — The completion callback adds at most one `sessionQueue` serial dispatch cycle (~microseconds) plus the pending buffer delivery time (~1-2 audio callbacks). No perceptible impact on transcription latency.
- **No deadlock risk** — `sessionQueue` is serial and non-reentrant; `performStopCapture` calls `session.stopRunning()` which is asynchronous and does not synchronously invoke callbacks.
