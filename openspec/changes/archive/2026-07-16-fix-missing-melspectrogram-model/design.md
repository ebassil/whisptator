## Context

Whisptator loads Whisper Large-v3 Turbo CoreML via `WhisperASRModel.fromPretrained()`. The model consists of 4 `.mlmodelc` directories that must exist in the `cacheDir` passed to `fromPretrained()`:

```
~/Library/Application Support/Whisptator/Models/
├── MelSpectrogram.mlmodelc/    (6 files: coremldata.bin, metadata.json, model.mil, model.mlmodel, weights/weight.bin, analytics/coremldata.bin)
├── AudioEncoder.mlmodelc/      (same 6 files)
├── TextDecoderContextPrefill.mlmodelc/  (same 6 files)
├── TextDecoder.mlmodelc/       (same 6 files)
├── config.json
├── generation_config.json
├── manifest.json
├── tokenizer_config.json
└── tokenizer.json
```

The current code uses `HubApi.snapshot()` from swift-transformers, which downloads files to the HuggingFace hub cache at `~/.cache/huggingface/hub/models--{author}--{repo}/snapshots/{hash}/` and creates a `.cache` subdirectory in the repo cache. These files are **never copied or symlinked** to the `cacheDir` that `fromPretrained()` expects. This is the root cause of "Missing MelSpectrogram.mlmodelc".

The model IS already downloaded (1.5 GB in cache). The fix is to replace `HubApi.snapshot()` with a direct downloader that places files exactly where `fromPretrained()` expects them.

## Goals / Non-Goals

**Goals:**
- Reliably download all 4 `.mlmodelc` directories to the `cacheDir` path
- Reuse already-downloaded files from the HF hub cache when available
- Delegate actual CoreML model loading to `WhisperASRModel.fromPretrained()` once files are in place
- Keep existing cache validation, integrity checks, and reset logic

**Non-Goals:**
- Replacing the CoreML inference pipeline (stays the same)
- Adding new STT engines (future consideration)
- Modifying speech-swift source code

## HuggingFace API

The HuggingFace model repo `aufklarer/Whisper-Large-v3-Turbo-CoreML` exposes:

- **File listing:** `GET https://huggingface.co/api/models/aufklarer/Whisper-Large-v3-Turbo-CoreML` returns JSON with a `siblings` array containing every file path in the repo (including files inside `.mlmodelc` directories)
- **File download:** `GET https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML/resolve/main/{filepath}` returns the raw file content

The repo has 27 files total. Each `.mlmodelc` directory contains 6 files:
- `coremldata.bin` (compiled CoreML weights)
- `analytics/coremldata.bin`
- `metadata.json`
- `model.mil` (MIL intermediate representation)
- `model.mlmodel` (CoreML model specification)
- `weights/weight.bin` (model weights)

Non-model files: `config.json`, `generation_config.json`, `manifest.json`, `tokenizer_config.json`, `tokenizer.json`, `.gitattributes`, `README.md`

## Decisions

### D1: Replace HubApi.snapshot() with direct HTTPS downloader

**Choice:** Implement `HuggingFaceModelDownloader` that enumerates repo files via the API, checks local cache, and downloads each file individually via URLSession.

**Rationale:** The `HubApi.snapshot()` API has a bug with directory glob patterns for `.mlmodelc` bundles. By downloading each file individually via HTTPS, we control exactly where each file lands and avoid the glob resolution entirely.

**Implementation:**

```swift
actor HuggingFaceModelDownloader {
    let repoId: String          // "aufklarer/Whisper-Large-v3-Turbo-CoreML"
    let cacheDir: URL           // target directory
    let hubCacheDir: URL        // ~/.cache/huggingface/hub/

    func resolveModelFiles() async throws -> [RepoFile]
    func downloadFile(_ file: RepoFile, progress: (Double) -> Void) async throws
    func ensureModelInCache() async throws  // main entry point
}
```

### D2: Reuse HuggingFace hub cache

**Choice:** Before downloading anything, check `~/.cache/huggingface/hub/models--{author}--{repo}/snapshots/{hash}/` for existing files. If present, symlink them to `cacheDir` instead of re-downloading.

**Rationale:** Users who already launched the app have 1.5 GB of model files in the HF hub cache. Re-downloading would waste bandwidth and time. Symlinking is instant and uses zero additional disk space.

**Algorithm:**
1. Check `~/.cache/huggingface/hub/models--aufklarer--Whisper-Large-v3-Turbo-CoreML/refs/main` for the commit hash
2. Construct snapshot path: `.../snapshots/{hash}/`
3. For each required file in the repo:
   - If it exists in snapshot path → symlink to `cacheDir` (recreate directory structure)
   - If it doesn't exist → add to download queue
4. Download files in queue from HuggingFace raw API

### D3: HuggingFace API file enumeration

**Choice:** Use the HuggingFace models API to enumerate files instead of hardcoding the file list.

**Rationale:** The model repo could change (new files, renamed directories). The API always returns the current file list. This also makes the code reusable for other HuggingFace models.

**Implementation:**

```swift
struct RepoFile: Sendable {
    let path: String
    let size: Int
}

func listRepoFiles(repoId: String) async throws -> [RepoFile] {
    let url = URL(string: "https://huggingface.co/api/models/\(repoId)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(HuggingFaceModelResponse.self, from: data)
    return response.siblings.map { RepoFile(path: $0.rfilename, size: $0.size) }
}
```

### D4: Per-file download with progress

**Choice:** Download each `.mlmodelc` file individually via URLSession download task, then move it to the target path. Report overall progress based on bytes downloaded / total bytes.

**Rationale:** Individual file downloads give us granular progress and the ability to retry specific files on failure. URLSession download tasks handle large files efficiently with streaming.

**Implementation:**

```swift
func downloadFile(path: String, to destination: URL, totalBytes: Int64, progress: @escaping (Double) -> Void) async throws {
    let url = URL(string: "https://huggingface.co/\(repoId)/resolve/main/\(path)")!
    let (localURL, response) = try await URLSession.shared.download(from: url)
    try FileManager.default.moveItem(at: localURL, to: destination)
}
```

### D5: Filter irrelevant files

**Choice:** Skip `.gitattributes` and `README.md` during download. These are not needed for model loading.

**Rationale:** These files are metadata for the Git repository, not the CoreML model. Skipping them saves bandwidth and avoids clutter in `cacheDir`.

**Implementation:**

```swift
let skipFiles: Set<String> = [".gitattributes", "README.md"]
```

### D6: Keep existing cache validation

**Choice:** Keep `validateCacheIntegrity()`, `deleteCache()`, and `resetCache()` from the previous implementation. These remain valuable for detecting partial downloads and enabling manual recovery.

**Rationale:** Even with reliable downloads, cache corruption can occur from disk errors, macOS cache cleanup, or manual deletion. Validation before each load catches these cases.

## HuggingFace Hub Cache Structure

```
~/.cache/huggingface/hub/
├── models--aufklarer--Whisper-Large-v3-Turbo-CoreML/
│   ├── blobs/                          # Content-addressable file storage
│   │   ├── {sha256hash}               # Binary blobs (each file stored once)
│   │   └── ...
│   ├── refs/
│   │   └── main                        # Contains commit hash: a8e93b2084b...
│   └── snapshots/
│       └── a8e93b2084b3d0a09765b2e3a5602a3d2b8f8d25/
│           ├── MelSpectrogram.mlmodelc/
│           │   ├── coremldata.bin      # Symlink → ../../blobs/{hash}
│           │   ├── metadata.json       # Symlink → ../../blobs/{hash}
│           │   └── ...
│           ├── AudioEncoder.mlmodelc/
│           ├── TextDecoder.mlmodelc/
│           ├── TextDecoderContextPrefill.mlmodelc/
│           ├── config.json
│           └── ...
```

## Download Flow

```
loadModel() called
       │
       ▼
Check if all 4 .mlmodelc dirs exist in cacheDir ──YES──→ Call fromPretrained() ──→ Done
       │
       NO
       │
       ▼
Detect HF hub cache at ~/.cache/huggingface/hub/
       │
       ├── Found & complete ──→ Symlink files to cacheDir ──→ Call fromPretrained() ──→ Done
       │
       └── Missing or not found
               │
               ▼
       List repo files via huggingface.co/api/models/{repo}
               │
               ▼
       Download each file via huggingface.co/{repo}/resolve/main/{path}
       Reconstruct directory structure (create .mlmodelc dirs as needed)
               │
               ▼
       Validate cache integrity
               │
               ├── Pass ──→ Call fromPretrained() ──→ Done
               │
               └── Fail ──→ Delete cache, retry once, or surface error
```

## Risks / Trade-offs

- **[HF API rate limiting]** → The models API is unauthenticated and generous, but at scale we could hit limits. Mitigation: Cache the API response locally and prefer hub cache reuse.
- **[Concurrent downloads]** → Downloading 24+ files serially is slow. Mitigation: Download `.mlmodelc` files concurrently (each is independent), use an `actor` to coordinate state safely.
- **[Symlink portability]** → Symlinks work on macOS but may break if cache is on a different volume. Mitigation: Copy instead of symlink when `FileManager.default.createSymbolicLink()` fails.
- **[Old cache format]** → The HuggingFace hub cache format could change. Mitigation: If hub cache detection fails, fall through to direct download.
