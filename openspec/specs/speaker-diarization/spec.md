# Speaker Diarization

## Purpose

After a recording stops, optionally run a fully local pyannote-based diarization pass over the system channel, infer the user's own speech from the microphone channel, and relabel the transcript with stable speaker IDs — atomically, and never at the expense of the live transcript.

## Requirements

### Requirement: Opt-in speaker identification
The system SHALL provide a "Identify speakers" setting for meeting recording, defaulting to OFF. When OFF, the transcript is left exactly as produced by live transcription and no diarization model is loaded or run. When ON, speaker labeling runs as a final pass after recording stops.

#### Scenario: Disabled by default
- **WHEN** a meeting ends and speaker identification is OFF
- **THEN** the transcript file keeps its live `[HH:MM:SS] text` lines and the session returns to idle immediately after the queue drains

#### Scenario: Enabled triggers final pass
- **WHEN** a meeting ends and speaker identification is ON
- **THEN** the session enters a finalizing state, speaker labels are computed on-device, and the transcript is relabeled

### Requirement: On-device diarization engine
The system SHALL perform speaker diarization entirely on-device using a local pyannote-based pipeline (speech segmentation, per-speaker embeddings, clustering) for this release, executed via a replaceable engine abstraction so the implementation can be swapped in future releases without affecting transcript output format.

#### Scenario: No network during diarization
- **WHEN** the diarization final pass runs with the model already downloaded
- **THEN** no network requests are made and processing completes locally

### Requirement: Microphone channel identifies the local user
The system SHALL attribute each transcript line using the channel its audio was segmented from, recorded during the session, and SHALL label microphone lines as spoken by `Me` without invoking the diarization model. A microphone line the echo path analysis reports as predominantly remote audio SHALL be dropped when the same words are already present on a system-channel line, otherwise attributed to the system-channel speaker covering that span when one exists and the system channel was active; when neither applies, the line keeps its `Me` attribution. Where no per-line provenance exists (sessions recorded before this pass, or a transcript that could not be matched), the system SHALL fall back to per-channel energy dominance, with the system channel winning overlapping speech.

#### Scenario: User speaks into microphone
- **WHEN** a transcript chunk was segmented from the microphone channel
- **THEN** its relabeled line attributes the speech to `Me`

#### Scenario: Meeting participants on speakers
- **WHEN** a transcript chunk was segmented from the system channel
- **THEN** its relabeled line carries the speaker ID assigned by the diarization pipeline

#### Scenario: Echo reaches the recognizer before the gate locks on
- **WHEN** a microphone line repeats the words of a system-channel line within the same span
- **THEN** the duplicate microphone line is removed instead of being shown twice under two names

### Requirement: Stable speaker numbering
The system SHALL number distinct system-channel speakers as `Speaker 1`, `Speaker 2`, ... in order of first appearance within the session, and SHALL use these same labels consistently across the entire relabeled transcript. The system SHALL cluster pooled per-turn embeddings rather than each embedding window in isolation, SHALL cap the number of speakers it will claim for a session, and SHALL absorb clusters supported by too little speech into the nearest speaker, so that one continuous voice is never reported as dozens of speakers.

#### Scenario: Recurring participant
- **WHEN** the same remote voice appears at minutes 3 and 47 of a meeting
- **THEN** both are labeled with the identical speaker ID

#### Scenario: One remote voice for a whole meeting
- **WHEN** diarization runs on a session whose system channel holds a single voice
- **THEN** the pass reports one speaker, not one per embedding window

#### Scenario: A single odd window
- **WHEN** one embedding window matches no speaker well
- **THEN** it joins the nearest speaker instead of starting a new one

### Requirement: Transcript relabel write-back
The system SHALL relabel by rewriting the session transcript file so every line becomes `[HH:MM:SS] <Speaker>: text`, using a temp-file-plus-atomic-rename so that at every instant the transcript file contains either the complete live transcript or the complete relabeled transcript.

#### Scenario: Rewrite is atomic
- **WHEN** the relabel write-back executes
- **THEN** the transcript file is never empty, truncated mid-line, or a mix of labeled and unlabeled lines

#### Scenario: Diarization failure preserves live transcript
- **WHEN** the diarization pass fails or times out
- **THEN** the live transcript file remains intact, the user is notified that speaker labels were not applied, and the session ends in idle

### Requirement: Diarization model download and graceful degradation
The system SHALL download the diarization models on demand from the public HuggingFace ONNX exports of the pyannote speaker-diarization-3.1 weights (segmentation-3.0, MIT; wespeaker-voxceleb-resnet34-LM, CC-BY-4.0) into the app's model directory, showing status in Settings. An optional user-provided access token SHALL be supported for repositories that require authentication. A missing or undownloadable model SHALL disable speaker identification with a visible error in Settings and SHALL never prevent meeting recording or live transcription from running.

#### Scenario: Repository unavailable or unauthorized
- **WHEN** the user enables speaker identification and the model download fails (network, missing, or gated repository)
- **THEN** the download shows an actionable error in Settings and meeting recording continues to work without labels
