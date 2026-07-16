## Why

The app crashes at model load with: `Failed to load model 'aufklarer/Whisper-Large-v3-Turbo-CoreML': Failed to initialize native Whisper runtime (Failed to load model 'Models': Missing MelSpectrogram.mlmodelc)`.

**Root cause:** `HubApi.snapshot()` from swift-transformers downloads `.mlmodelc` files to the HuggingFace hub cache at `~/.cache/huggingface/hub/models--aufklarer--Whisper-Large-v3-Turbo-CoreML/snapshots/<hash>/`, but the `WhisperASRModel.fromPretrained(cacheDir:)` looks for them in the provided `cacheDir` (`~/Library/Application Support/Whisptator/Models/`). The model files are never copied/symlinked between these locations.

**Evidence:** The model IS already fully downloaded (1.5 GB in the HF hub cache + Whisptator app cache), but the `cacheDir` only has `tokenizer_config.json` and `tokenizer.json` — the 4 `.mlmodelc` directories never made it there.

**Solution:** Replace `HubApi.snapshot()` with a direct HuggingFace downloader that:
1. Checks the HF hub cache first — reuse already-downloaded files (zero re-download!)
2. Downloads any missing files via HuggingFace's raw HTTPS API (`huggingface.co/{repo}/resolve/main/{file}`)
3. Reconstructs `.mlmodelc` directory structure in `modelCacheDir` (these are macOS packages — directories with sub-files)
4. Falls back to calling `WhisperASRModel.fromPretrained()` which then finds all files in `cacheDir`

This keeps the CoreML/ANE pipeline intact, fixes only the download layer, and reuses 1.5 GB of already-downloaded data.

## What Changes

- **ModelManager.swift** — Add `HuggingFaceModelDownloader` that replaces `HubApi.snapshot()` with direct URLSession downloads
- **ModelManager.swift** — Add HuggingFace hub cache detection — check if files exist in `~/.cache/huggingface/hub/` and symlink them to `modelCacheDir`
- **ModelManager.swift** — Add per-file download from `huggingface.co/{repo}/resolve/main/{file}` using HuggingFace API to enumerate model files
- **ModelManager.swift** — Reconstruct `.mlmodelc` directory structure in `modelCacheDir` after download
- **ModelManager.swift** — Keep existing cache validation, repair, and reset logic

## Capabilities

### New Capabilities

- `hf-direct-downloader`: Downloads HuggingFace model files directly via HTTPS, bypassing HubApi.snapshot() glob bugs
- `hf-cache-reuse`: Detects and reuses already-downloaded files from `~/.cache/huggingface/hub/`

### Modified Capabilities

- `whisper-stt`: Updated download pipeline for reliable `.mlmodelc` directory download
- `model-cache-validation`: Continues to work; now backed by reliable download

## Impact

- **ModelManager.swift** — Add direct download logic, keep existing validation
- **No new dependencies** — Uses Foundation URLSession and FileManager
- **No spec changes needed** — whisper-stt spec already requires model download; this fixes the implementation
