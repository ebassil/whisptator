# Live Transcription

## Purpose

Segment the live meeting audio stream with voice activity detection, transcribe each chunk with the local Whisper model while recording continues, and append timestamped, fsynced transcript lines in order.

## Requirements

### Requirement: VAD-based audio segmentation
The system SHALL segment the incoming aligned audio stream per source channel with a voice-activity detector — one segmentation stream for the microphone and one for system audio in stereo sessions — cutting a segment at a trailing silence of at least 400 ms or at a hard maximum of 30 seconds, discarding detections shorter than 300 ms, and padding each submitted chunk by approximately 0.2 seconds at head and tail where audio is available. The system SHALL NOT fold the channels together before segmentation, and SHALL emit chunks for transcription in position order on the recording timeline.

#### Scenario: Channels segmented apart
- **WHEN** the microphone and system channels both contain speech in the same span
- **THEN** each channel yields its own chunk and the recognizer is never handed a mix of two speakers at once

#### Scenario: Cut on trailing silence
- **WHEN** a channel's stream contains at least 400 ms of continuous non-speech after a speech run
- **THEN** a transcription chunk is emitted ending at the silence start and including head/tail padding

#### Scenario: Forced cut at maximum duration
- **WHEN** continuous speech on a channel exceeds 30 seconds without a qualifying silence gap
- **THEN** a chunk is emitted at the 30-second boundary and segmentation resumes for the continuing speech

#### Scenario: Non-speech discarded
- **WHEN** a detected speech run is shorter than 300 ms
- **THEN** no chunk is emitted for it

### Requirement: Incremental chunk transcription
The system SHALL transcribe each emitted chunk with the loaded Whisper model on a dedicated background worker while recording continues, and SHALL append results in chunk order. Each appended line SHALL have its source channel and echo measurement recorded in an in-session provenance ledger so the final speaker-identification pass can attribute the line without guessing. Transcription of a chunk SHALL NOT block or throttle audio capture or audio file writing.

#### Scenario: Text lands during recording
- **WHEN** a chunk's transcription completes while the meeting is still recording
- **THEN** the corresponding transcript line is appended to the session transcript file without waiting for recording stop

#### Scenario: Ordered output under variable latency
- **WHEN** chunk N+1's transcription completes before chunk N's
- **THEN** chunk N's line is still written before chunk N+1's line in the transcript file

#### Scenario: Line provenance recorded
- **WHEN** a transcript line is appended
- **THEN** the session ledger records the channel the chunk was segmented from, its time span, and the local-speech share measured by the echo gate when one exists

### Requirement: Chunk leveling and recognition-loop suppression
The system SHALL normalize each chunk's level for recognition by bounded boost only: quiet speech is lifted toward a target level, chunks at or above the target are never attenuated, and chunks indistinguishable from room noise are left untouched. Before a transcribed line is appended, the system SHALL detect a runaway recognizer loop — a repeating cycle of at most six words occurring at least four times — and collapse it to a single occurrence.

#### Scenario: Quiet microphone segment boosted
- **WHEN** a chunk carries speech well below the target level but above the noise floor
- **THEN** it is amplified by a bounded gain that cannot clip before recognition

#### Scenario: Noise-only chunk untouched
- **WHEN** a chunk's level is at or below the noise floor
- **THEN** no gain is applied and the chunk is passed through as captured

#### Scenario: Runaway loop collapsed
- **WHEN** the transcription of a chunk repeats the same short word cycle four or more times
- **THEN** the appended line contains that cycle once instead of drowning the line in repetition

#### Scenario: Natural repetition preserved
- **WHEN** a line repeats a phrase fewer than four times
- **THEN** the text is appended unchanged

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
