## 1. Add SPM dependencies

- [x] 1.1 Add `ParakeetASR`, `ParakeetStreamingASR`, `NemotronStreamingASR`, `OmnilingualASR` to Package.swift dependencies

## 2. Create SupportedModel definitions

- [x] 2.1 Create `ASRModelType` enum and `SupportedModel` struct in `Sources/WhisptatorCore/STT/SupportedModel.swift`
- [x] 2.2 Define all 5 supported models with metadata (id, name, size, type)

## 3. Add HF hub cache scanning

- [x] 3.1 Add `scanHubCache()` static method to `HuggingFaceModelDownloader` that lists cached model directories
- [x] 3.2 Add `isCachedInHub(repoId:)` static method

## 4. Refactor ModelManager for multi-model support

- [x] 4.1 Add `selectedModelType` and `selectedModelId` properties
- [x] 4.2 Add `availableModels` static property returning all supported models
- [x] 4.3 Refactor `loadModel()` to dispatch to the correct `fromPretrained()` based on model type
- [x] 4.4 Add cache migration from old flat structure to per-model subdirectories
- [x] 4.5 Update `ensureModelInCache()` to use universal API-based download (no hardcoded file list)

## 5. Add model selection to AppSettings

- [x] 5.1 Add `selectedModelId: String` property to `AppSettings`
- [x] 5.2 Default to Whisper model ID

## 6. Update ModelSettingsTab UI

- [x] 6.1 Replace single model display with a `List` of all supported models
- [x] 6.2 Show model name, description, size label, and status (not downloaded / cached / loaded)
- [x] 6.3 Add download/select button per model
- [x] 6.4 Show progress during download
- [x] 6.5 Show cache status from HF hub scan

## 7. Verify build

- [x] 7.1 `swift build` succeeds with no errors
