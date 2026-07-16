## Context

Whisptator currently supports only `aufklarer/Whisper-Large-v3-Turbo-CoreML` via the speech-swift library. The library supports 5 CoreML ASR model families:

| Model Family | HuggingFace ID | Params | Format | Languages |
|---|---|---|---|---|
| Whisper Large-v3 Turbo | aufklarer/Whisper-Large-v3-Turbo-CoreML | ~1.5B | CoreML ANE | Multilingual |
| Parakeet TDT v3 | aufklarer/Parakeet-TDT-v3-CoreML-INT8-30s | 600M | CoreML ANE | 25 European |
| Parakeet EOU | aufklarer/Parakeet-EOU-120M-CoreML-INT8 | 120M | CoreML ANE | 25 European |
| Nemotron Streaming | aufklarer/Nemotron-3.5-ASR-Streaming-0.6B-CoreML-INT8 | 600M | CoreML ANE | 76 lang-locales |
| Omnilingual ASR | aufklarer/Omnilingual-ASR-CTC-300M-CoreML-INT8-10s | 300M | CoreML ANE | 1,672 |

Each has its own SPM module and `fromPretrained()` entry point in speech-swift.

## Goals / Non-Goals

**Goals:**
- Show all supported aufklarer CoreML ASR models in a browsable list
- Detect which models are already cached in `~/.cache/huggingface/hub/`
- Allow user to select which model to use
- Persist model selection across app launches
- Download selected model if not cached
- Load and transcribe with the selected model

**Non-Goals:**
- Support non-aufklarer models (would need different format adapters)
- Support MLX-based models (different loading path, future consideration)
- Streaming transcription UI (existing batch transcription is fine for now)
- Dynamic model switching while transcribing (must be idle to switch)

## Architecture

### Model Type Enum

```swift
public enum ASRModelType: String, CaseIterable, Sendable {
    case whisper
    case parakeet
    case parakeetStreaming
    case nemotron
    case omnilingual
}
```

### SupportedModel Struct

```swift
public struct SupportedModel: Identifiable, Sendable {
    public let id: String       // HuggingFace repo ID
    public let type: ASRModelType
    public let name: String     // Display name
    public let description: String
    public let sizeLabel: String // e.g., "600M params"
    public let modelSize: Int64  // Approximate bytes
}
```

### HuggingFaceModelDownloader Extension

Add a static method `scanHubCache() -> [String]` that lists all `models--*` directories in the HF hub cache and converts them back to repo IDs.

### ModelManager Refactoring

ModelManager stores the selected model's repo ID and type. Loading dispatches to the appropriate `fromPretrained()` based on type. Transcription uses the `SpeechRecognitionModel` protocol from AudioCommon (all 5 models conform).

### AppSettings

Add `selectedModelId: String` (defaults to the Whisper model ID). This is persisted and used by ModelManager on next load.

## Decisions

### D1: Per-model cache directories

Each model's files are stored in `~/Library/Application Support/Whisptator/Models/{repo-name}/` to avoid name collisions. The Whisper model will need migration from the old flat cache dir.

**Choice:** Use subdirectories per model: `Models/Whisper-Large-v3-Turbo-CoreML/`, `Models/Parakeet-TDT-v3-CoreML-INT8-30s/`, etc.

**Migration:** On first launch with the new code, check if old flat cache dir has files and move them to the appropriate subdirectory.

### D2: Model type abstraction

Rather than a generic wrapper protocol (which is complex), use an enum dispatch in ModelManager:

```swift
private func loadModelInstance() async throws -> SpeechRecognitionModel {
    switch selectedModelType {
    case .whisper:
        return try await WhisperASRModel.fromPretrained(...)
    case .parakeet:
        return try await ParakeetASRModel.fromPretrained(...)
    ...
    }
}
```

### D3: HF cache scanning

Scan `~/.cache/huggingface/hub/` for directories matching `models--{author}--{repo}`, extract repo IDs, and match against the supported models list. Show a "Cached" indicator for matched models.

### D4: Download per model

The HuggingFaceModelDownloader already supports downloading from any repo ID. Each model type needs its own `requiredModelFiles()` list or we can use the generic API-based download (list repo files via API then download each).

Switch to the universal approach: always use the HuggingFace API to list files, then download them all. This eliminates the hardcoded file list.

## Risks

- **[Large dependency count]** Adding 4 new SPM modules increases build time. Mitigation: Each module is lazily loaded at runtime, no compile-time impact beyond first build.
- **[API differences]** Each model type has slightly different `fromPretrained()` and transcribe signatures. Mitigation: Use the `SpeechRecognitionModel` protocol for transcription, custom dispatch for loading.
- **[Migration]** Old cache format (`Models/` flat dir) needs migration to subdirectory. Mitigation: Simple one-time file move in the first launch path.
