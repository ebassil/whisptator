## 1. Fix audio format conversion in MicrophoneCapture.captureOutput

- [x] 1.1 Set `output.audioSettings` to request Float32 PCM from AVFoundation (fixes raw-byte misinterpretation of Int16 data as Float32)
- [x] 1.2 Zero-fill remaining buffer when source data is shorter than expected (prevents uninitialized memory)
- [x] 1.3 Check `session.startRunning()` return value with `captureSession?.isRunning`
- [x] 1.4 Add completion callback `@Sendable () -> Void?` to `stopCapture()`, invoked on main queue after session fully stops

## 2. Fix DictationOrchestrator stop-to-transcribe ordering

- [x] 2.1 Add `NSLock` property for `recordedBuffers` thread safety
- [x] 2.2 Remove `guard currentState == .recording` from `microphoneCapture(_:didCaptureAudio:)` — always collect buffers while capture is active
- [x] 2.3 Restructure `stopRecordingAndTranscribe()` to call `microphoneCapture.stopCapture(completion:)` and defer state change + processing to the completion handler
- [x] 2.4 Move the audio save and transcription logic into the completion handler, keeping `currentState = .transcribing` inside it
- [x] 2.5 Acquire `recordedBuffers` lock in `startRecording()` when clearing the array

## 3. Fix MeetingRecorder stop-to-transcribe ordering

- [x] 3.1 Remove `guard currentState == .recording` from `addBuffer()` and delegate callbacks
- [x] 3.2 Restructure `stopRecording()` to await `microphoneCapture.stopCapture(completion:)` via `withCheckedContinuation` before transitioning state
- [x] 3.3 Ensure `mergeBuffers` is called only after both microphone and system captures fully stopped

## 4. Build & Verify

- [x] 4.1 Build the project with `swift build` (debug) and `swift build -c release` — no compilation errors
- [x] 4.2 Start dictation, speak for 5+ seconds, stop recording
- [x] 4.3 Verify the saved audio file in `~/Documents/Whisptator/Audio/` is larger than 52 bytes and plays back correctly
- [x] 4.4 Start a meeting recording, let it run for 5+ seconds, stop
- [x] 4.5 Verify the meeting audio is captured and transcribed correctly
- [x] 4.6 Test push-to-talk mode specifically (since it has a rapid hold-release cycle)
