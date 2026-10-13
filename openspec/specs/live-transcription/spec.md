# Live Transcription

## Purpose

Segment the live meeting audio stream with voice activity detection, transcribe each chunk with the local Whisper model while recording continues, and append timestamped, fsynced transcript lines in order.

## Requirements

### Requirement: VAD-based audio segmentation
The system SHALL continuously segment the incoming aligned audio stream into speech segments using a voice-activity detector, cutting a segment at a trailing silence of at least 400 ms or at a hard maximum of 30 seconds, discarding detections shorter than 300 ms, and padding each submitted chunk by approximately 0.2 seconds at head and tail where audio is available.

#### Scenario: Cut on trailing silence
- **WHEN** the audio stream contains at least 400 ms of continuous non-speech after a speech run
- **THEN** a transcription chunk is emitted ending at the silence start and including head/tail padding

#### Scenario: Forced cut at maximum duration
- **WHEN** continuous speech exceeds 30 seconds without a qualifying silence gap
- **THEN** a chunk is emitted at the 30-second boundary and segmentation resumes for the continuing speech

#### Scenario: Non-speech discarded
- **WHEN** a detected speech run is shorter than 300 ms
- **THEN** no chunk is emitted for it

### Requirement: Incremental chunk transcription
The system SHALL transcribe each emitted chunk with the loaded Whisper model on a dedicated background worker while recording continues, and SHALL append results in chunk order. Transcription of a chunk SHALL NOT block or throttle audio capture or audio file writing.

#### Scenario: Text lands during recording
- **WHEN** a chunk's transcription completes while the meeting is still recording
- **THEN** the corresponding transcript line is appended to the session transcript file without waiting for recording stop

#### Scenario: Ordered output under variable latency
- **WHEN** chunk N+1's transcription completes before chunk N's
- **THEN** chunk N's line is still written before chunk N+1's line in the transcript file

### Requirement: Timestamped transcript line format
The system SHALL write one line per transcribed chunk to the session transcript file in the format `[HH:MM:SS] text`, where the timestamp is the chunk start position on the recording timeline derived from the audio frame offset (samples since recording start divided by the sample rate), not wall-clock time.

#### Scenario: Timestamp reflects recording position
- **WHEN** a chunk covering recording frames starting at second 725 is transcribed
- **THEN** its line begins with `[00:12:05]`

#### Scenario: Timeline preserved during mic mute
- **WHEN** the microphone is muted for a period and later unmuted
- **THEN** subsequent chunk timestamps continue to reflect position in the audio file (mute zero-fills, it does not pause the timeline)

### Requirement: Durable incremental append
The system SHALL append each transcript line to the file on disk and flush it (fsync) at least per line append, such that an application crash loses at most the transcription of the single chunk in flight.

#### Scenario: App crash during recording
- **WHEN** the application terminates abnormally during a live session
- **THEN** every transcript line already appended is present in the file with intact format when the file is reopened

### Requirement: Transcription backlog bounding and graceful degradation
The system SHALL bound the pending-chunk queue. When the queue is full, the system SHALL drop the oldest untranscribed chunk, record a gap in the log, and continue capturing audio and writing the audio file unaffected.

#### Scenario: Sustained transcription lag
- **WHEN** the transcription worker cannot keep up and the queue reaches its bound
- **THEN** the oldest queued chunk is dropped, the session continues, and the mp3 remains complete and continuous
