# Whisper STT

## Purpose

TBD

## Requirements

### Requirement: WhisperASR integration
The system SHALL use speech-swift's WhisperASR module for on-device speech-to-text inference. The system SHALL load the aufklarer/Whisper-Large-v3-Turbo-CoreML bundle via `WhisperASRModel.fromPretrained()`.

#### Scenario: Model loaded from custom cache directory
- **WHEN** the application launches
- **THEN** the WhisperASR model is loaded from ~/Library/Application Support/Whisptator/Models/ using `cacheDir:` parameter

#### Scenario: Model preload on launch
- **WHEN** the application launches
- **THEN** the model is loaded in a background task so it is ready before the user first triggers dictation

### Requirement: Transcription API
The system SHALL expose a `TranscriptionEngine` that wraps WhisperASR and provides a simple async transcription interface accepting audio samples and returning text.

#### Scenario: Transcribe audio buffer
- **WHEN** the system calls `TranscriptionEngine.transcribe(audio:sampleRate:language:)` with a Float32 audio buffer
- **THEN** the system returns the transcribed text as a String

#### Scenario: Language auto-detection
- **WHEN** transcription is requested without a language hint
- **THEN** WhisperASR auto-detects the language from the audio

#### Scenario: Language hint
- **WHEN** transcription is requested with a specific language code (e.g., "en", "fr")
- **THEN** WhisperASR uses the specified language for decoding

### Requirement: Model download management
The system SHALL provide a `ModelManager` that handles downloading, caching, and status tracking of the Whisper CoreML model bundle.

#### Scenario: First launch download
- **WHEN** the application launches for the first time and the model is not cached
- **THEN** the system initiates a download of the CoreML bundle from HuggingFace to ~/Library/Application Support/Whisptator/Models/

#### Scenario: Download progress reporting
- **WHEN** a model download is in progress
- **THEN** the system reports download progress (bytes downloaded / total bytes) to the Settings UI

#### Scenario: Offline mode
- **WHEN** the model is already cached and the device is offline
- **THEN** the system loads the model from the local cache using `offlineMode: true`

### Requirement: Audio preprocessing
The system SHALL convert captured audio to 16 kHz mono Float32 format before passing it to WhisperASR, as required by the model.

#### Scenario: Sample rate conversion
- **WHEN** audio is captured at 44.1 kHz or 48 kHz (typical microphone sample rates)
- **THEN** the system resamples to 16 kHz mono Float32 before transcription
