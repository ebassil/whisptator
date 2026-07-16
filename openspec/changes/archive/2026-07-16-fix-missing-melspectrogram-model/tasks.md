## 1. Add HuggingFace API client

- [x] 1.1 Create `HuggingFaceModelDownloader` actor in `Sources/WhisptatorCore/STT/HuggingFaceModelDownloader.swift`
- [x] 1.2 Implement `listRepoFiles(repoId:)` that calls `GET https://huggingface.co/api/models/{repo}` and parses the `siblings` array for file paths and sizes
- [x] 1.3 Define `RepoFile` struct with `path: String`, `size: Int` — skip `.gitattributes` and `README.md`
- [x] 1.4 Add `downloadFile(path:to:)` method using `URLSession.shared.download(from:)` with the HuggingFace raw URL `https://huggingface.co/{repo}/resolve/main/{path}`

## 2. Add HF hub cache reuse

- [x] 2.1 Implement `hubCachePath(for:)` that constructs the HuggingFace hub cache path from `repoId`: `~/.cache/huggingface/hub/models--{author}--{repo}/`
- [x] 2.2 Read the commit hash from `refs/main` file in hub cache directory
- [x] 2.3 Construct snapshot path: `snapshots/{hash}/` and check for each required file
- [x] 2.4 For each existing file in snapshot, symlink to `modelCacheDir` with proper directory structure (create `.mlmodelc` dirs as needed)
- [x] 2.5 If symlink fails (different volume), fall back to copy

## 3. Integrate downloader into ModelManager.loadModel()

- [x] 3.1 Replace the progress closure passed to `WhisperASRModel.fromPretrained()` with a custom download phase first
- [x] 3.2 Add `ensureModelInCache()` method that: (a) checks cacheDir for completeness, (b) tries HF hub cache reuse, (c) falls back to direct download
- [x] 3.3 Update download progress reporting to show per-file progress and overall progress
- [x] 3.4 Move tokenizer files to cacheDir if they aren't already there (they come from HF hub cache too)

## 4. Update download progress reporting

- [x] 4.1 Track total bytes across all files (from `siblings` API response)
- [x] 4.2 Report progress per-file as individual downloads complete
- [x] 4.3 Report overall progress as `bytesDownloaded / totalBytes`
- [x] 4.4 Keep speed and ETA computation from previous implementation

## 5. Integrate with existing cache validation

- [x] 5.1 Use existing `validateCacheIntegrity()` after download completes
- [x] 5.2 Keep `deleteCache()` and `resetCache()` as-is
- [x] 5.3 Ensure `resetCache()` deletes cacheDir AND calls `ensureModelInCache()` + `fromPretrained()`

## 6. Verify the fix

- [x] 6.1 Build with `swift build` — no errors
- [x] 6.2 Delete `~/Library/Application Support/Whisptator/Models/` to simulate fresh state
- [x] 6.3 Launch app — verify detection of existing HF hub cache and symlink creation
- [x] 6.4 Verify all 4 `.mlmodelc` directories exist in `~/Library/Application Support/Whisptator/Models/`
- [x] 6.5 Verify `WhisperASRModel.fromPretrained()` loads successfully
- [ ] 6.6 Test dictation — verify transcription works end-to-end
- [x] 6.7 Delete HF hub cache AND app cache — test clean download from scratch
- [x] 6.8 Test offline mode — delete app cache, re-download, go offline, verify offline load
- [x] 6.9 Test cache repair — manually delete `MelSpectrogram.mlmodelc`, verify detection and re-download
- [x] 6.10 Test Reset button — verify confirmation dialog and re-download
