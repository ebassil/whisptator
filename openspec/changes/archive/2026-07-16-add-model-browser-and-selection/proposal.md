## Why

The Model settings page shows a single hardcoded model (Whisper Large-v3 Turbo CoreML), but users expect to browse and select from all available aufklarer CoreML ASR models. Users also want to see which models are already cached in the HuggingFace hub cache (`~/.cache/huggingface/hub/`) to avoid redundant downloads.

speech-swift supports 5 ASR model families — Whisper, Parakeet (batch + streaming), Nemotron Streaming, and Omnilingual — all as aufklarer CoreML models. Each has different size/speed/language trade-offs.

## What Changes

- **Package.swift** — Add dependencies for `ParakeetASR`, `ParakeetStreamingASR`, `NemotronStreamingASR`, `OmnilingualASR`
- **SupportedModel.swift** (new) — Define available models with metadata (id, name, size, description, model type)
- **HuggingFaceModelDownloader.swift** — Add HF hub cache scanning to detect cached models
- **ModelManager.swift** — Refactor to support model selection, abstract model loading via SpeechRecognitionModel protocol
- **AppSettings.swift** — Add `selectedModelId` and `modelDownloadStates` dictionary
- **SettingsView.swift** — Replace single-model display with a list of models, selection, and per-model download/status

## Capabilities

### New Capabilities
- `model-browser`: Shows a list of supported CoreML ASR models with metadata (name, size, description)
- `hf-cache-detection`: Scans `~/.cache/huggingface/hub/` for all cached aufklarer models and shows their status
- `model-selection`: User can select which ASR model to use; selection is persisted in settings

### Modified Capabilities
- `whisper-stt`: Expanded to support all aufklarer CoreML ASR models
- `model-cache-validation`: Now operates on the selected model's cache directory
- `model-download`: Per-model downloads with per-file progress

## Impact

- **Package.swift** — 4 new product dependencies
- **New file:** `SupportedModel.swift` — ~50 lines
- **Modified:** `HuggingFaceModelDownloader.swift` — add cache scanning (~20 lines)
- **Modified:** `ModelManager.swift` — major refactor (~200 lines)
- **Modified:** `AppSettings.swift` — add 1 property (~5 lines)
- **Modified:** `SettingsView.swift` — ModelSettingsTab rewrite (~100 lines)
- **AppCoordinator.swift** — minor update for selectedModelId passthrough
