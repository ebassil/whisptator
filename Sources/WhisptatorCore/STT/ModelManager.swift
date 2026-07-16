import Foundation
import AudioCommon
import WhisperASR
import ParakeetASR
import ParakeetStreamingASR
import NemotronStreamingASR
import OmnilingualASR

public enum ModelDownloadStatus: Sendable {
    case notStarted
    case downloading(progress: Double, message: String)
    case loaded
    case failed(Error)
}

@Observable
public final class ModelManager: @unchecked Sendable {
    private var model: SpeechRecognitionModel?
    private let modelsRootDir: URL
    private var downloader: HuggingFaceModelDownloader?

    public var downloadStatus: ModelDownloadStatus = .notStarted
    public var selectedModelId: String
    public var onStatusChange: ((ModelDownloadStatus) -> Void)?

    public var selectedModel: SupportedModel? {
        SupportedModel.model(for: selectedModelId)
    }

    private var modelType: ASRModelType {
        selectedModel?.type ?? .whisper
    }

    private var modelCacheDir: URL {
        let dirName = selectedModelId
            .replacingOccurrences(of: "/", with: "--")
            .replacingOccurrences(of: ".", with: "_")
        return modelsRootDir.appendingPathComponent(dirName, isDirectory: true)
    }

    public init(selectedModelId: String = SupportedModel.default.id) {
        self.selectedModelId = selectedModelId
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelsRootDir = appSupport.appendingPathComponent("Whisptator/Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsRootDir, withIntermediateDirectories: true)
        migrateOldCacheIfNeeded()
    }

    public func loadModel() async {
        downloadStatus = .downloading(progress: 0, message: "Starting...")
        onStatusChange?(downloadStatus)
        AppLogger.shared.log(category: .model, message: "Model download started: \(selectedModelId)")

        do {
            try await ensureModelInCache { [weak self] progress, message in
                guard let self else { return }
                self.downloadStatus = .downloading(progress: progress, message: message)
                self.onStatusChange?(self.downloadStatus)
            }
            logCacheContents()
            AppLogger.shared.log(category: .model, message: "Model files ready, loading...")

            let loadedModel = try await loadModelInstance(offline: false)
            model = loadedModel
            downloadStatus = .loaded
            onStatusChange?(downloadStatus)
            logHubCacheLocation()
            AppLogger.shared.log(category: .model, message: "Model loaded successfully")
        } catch {
            downloadStatus = .failed(error)
            onStatusChange?(downloadStatus)
            AppLogger.shared.log(category: .model, message: "Model load failed: \(error)")
        }
    }

    public func loadModelOffline() async {
        do {
            let loadedModel = try await loadModelInstance(offline: true)
            model = loadedModel
            downloadStatus = .loaded
            onStatusChange?(downloadStatus)
            logHubCacheLocation()
            AppLogger.shared.log(category: .model, message: "Model loaded from cache")
        } catch {
            downloadStatus = .failed(error)
            onStatusChange?(downloadStatus)
            AppLogger.shared.log(category: .model, message: "Model load failed: \(error)")
        }
    }

    public func transcribe(audio: [Float], sampleRate: Int, language: String? = nil) async throws -> String {
        guard let model else {
            throw ModelError.modelNotLoaded
        }
        return await Task.detached {
            model.transcribe(audio: audio, sampleRate: sampleRate, language: language)
        }.value
    }

    public var isModelLoaded: Bool {
        model != nil
    }

    public var availableModels: [SupportedModel] {
        SupportedModel.all
    }

    public func hubCacheStatus(for modelId: String) -> Bool {
        HuggingFaceModelDownloader.isCachedInHub(repoId: modelId)
    }

    public func isSelected(_ modelId: String) -> Bool {
        selectedModelId == modelId
    }

    public func selectModel(_ modelId: String) {
        guard selectedModelId != modelId else { return }
        model = nil
        selectedModelId = modelId
        downloadStatus = .notStarted
        onStatusChange?(downloadStatus)
        AppLogger.shared.log(category: .model, message: "Model selected: \(modelId)")
    }
}

extension ModelManager {
    private func loadModelInstance(offline: Bool = false) async throws -> SpeechRecognitionModel {
        switch modelType {
        case .whisper:
            return try await WhisperASRModel.fromPretrained(
                modelId: selectedModelId,
                cacheDir: modelCacheDir,
                offlineMode: offline
            ) { [weak self] progress, message in
                guard let self else { return }
                self.downloadStatus = .downloading(progress: progress, message: message)
                self.onStatusChange?(self.downloadStatus)
            }

        case .parakeet:
            return try await ParakeetASRModel.fromPretrained(
                modelId: selectedModelId,
                cacheDir: modelCacheDir,
                offlineMode: offline,
                progressHandler: { [weak self] progress, message in
                    guard let self else { return }
                    self.downloadStatus = .downloading(progress: progress, message: message)
                    self.onStatusChange?(self.downloadStatus)
                }
            )

        case .parakeetStreaming:
            if let d = downloader {
                try await d.linkToHubCache(from: modelCacheDir)
            }
            return try await ParakeetStreamingASRModel.fromPretrained(
                modelId: selectedModelId,
                progressHandler: { [weak self] progress, message in
                    guard let self else { return }
                    self.downloadStatus = .downloading(progress: progress, message: message)
                    self.onStatusChange?(self.downloadStatus)
                }
            )

        case .nemotron:
            if let d = downloader {
                try await d.linkToHubCache(from: modelCacheDir)
            }
            return try await NemotronStreamingASRModel.fromPretrained(
                modelId: selectedModelId,
                progressHandler: { [weak self] progress, message in
                    guard let self else { return }
                    self.downloadStatus = .downloading(progress: progress, message: message)
                    self.onStatusChange?(self.downloadStatus)
                }
            )

        case .omnilingual:
            return try await OmnilingualASRModel.fromPretrained(
                modelId: selectedModelId,
                cacheDir: modelCacheDir,
                offlineMode: offline,
                progressHandler: { [weak self] progress, message in
                    guard let self else { return }
                    self.downloadStatus = .downloading(progress: progress, message: message)
                    self.onStatusChange?(self.downloadStatus)
                }
            )
        }
    }
}

extension ModelManager {
    public func ensureModelInCache(progress: @escaping @Sendable (Double, String) -> Void) async throws {
        let downloader = HuggingFaceModelDownloader(repoId: selectedModelId, cacheDir: modelCacheDir)
        self.downloader = downloader

        AppLogger.shared.log(category: .model, message: "ensureModelInCache: cacheDir=\(modelCacheDir.path)")

        if cacheIsComplete() {
            progress(1.0, "Model already cached")
            AppLogger.shared.log(category: .model, message: "ensureModelInCache: cache is complete, skipping download")
            return
        }

        AppLogger.shared.log(category: .model, message: "ensureModelInCache: cache incomplete, checking HF hub cache...")
        let hubAvailable = HuggingFaceModelDownloader.isCachedInHub(repoId: selectedModelId)
        AppLogger.shared.log(category: .model, message: "ensureModelInCache: HF hub cache available=\(hubAvailable)")

        let existingFiles = listCacheFiles()
        AppLogger.shared.log(category: .model, message: "ensureModelInCache: existing cache files (\(existingFiles.count)): \(existingFiles.prefix(20).joined(separator: ", "))")

        try await downloader.ensureModelInCache { p, msg in
            progress(p, msg)
        }

        if !cacheIsComplete() {
            let afterFiles = listCacheFiles()
            AppLogger.shared.log(category: .model, message: "ensureModelInCache: cache still incomplete after download. Files after (\(afterFiles.count)): \(afterFiles.prefix(20).joined(separator: ", "))")
            throw ModelError.cacheIncomplete
        }

        AppLogger.shared.log(category: .model, message: "ensureModelInCache: cache now complete")
    }

    private func listCacheFiles() -> [String] {
        guard let enumerator = FileManager.default.enumerator(at: modelCacheDir, includingPropertiesForKeys: nil) else {
            return []
        }
        return enumerator.compactMap { ($0 as? URL)?.path.replacingOccurrences(of: modelCacheDir.path + "/", with: "") }.sorted()
    }

    public func cacheIsComplete() -> Bool {
        let required: [String]
        switch modelType {
        case .whisper, .parakeet, .omnilingual:
            required = HuggingFaceModelDownloader.requiredMLModelCFiles()
        case .parakeetStreaming, .nemotron:
            required = [] // streaming models loaded via HubApi directly
        }

        guard !required.isEmpty else { return false }

        for relativePath in required {
            let fullPath = modelCacheDir.appendingPathComponent(relativePath)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDir),
                  isDir.boolValue else {
                AppLogger.shared.log(category: .model, message: "cacheIsComplete: missing required directory \(relativePath)")
                return false
            }
            // Verify the directory has contents (not empty)
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: fullPath.path),
                  !contents.isEmpty else {
                AppLogger.shared.log(category: .model, message: "cacheIsComplete: \(relativePath) is empty")
                return false
            }
        }
        return true
    }

    public func validateCacheIntegrity() -> Bool {
        cacheIsComplete()
    }

    public func deleteCache() throws {
        if FileManager.default.fileExists(atPath: modelCacheDir.path) {
            try FileManager.default.removeItem(at: modelCacheDir)
        }
        try FileManager.default.createDirectory(at: modelCacheDir, withIntermediateDirectories: true)
        downloadStatus = .notStarted
        onStatusChange?(downloadStatus)
        AppLogger.shared.log(category: .model, message: "Model cache deleted for \(selectedModelId)")
    }

    public func resetCache() async {
        do {
            try deleteCache()
            AppLogger.shared.log(category: .model, message: "Cache reset, re-downloading...")
            await loadModel()
        } catch {
            downloadStatus = .failed(error)
            onStatusChange?(downloadStatus)
            AppLogger.shared.log(category: .model, message: "Cache reset failed: \(error)")
        }
    }

    private func logCacheContents() {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: modelCacheDir, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]) else {
            AppLogger.shared.log(category: .model, message: "Cache directory not found at \(modelCacheDir.path)")
            return
        }
        var fileList: [String] = []
        for url in contents {
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: url.path, isDirectory: &isDir)
            let isLink = (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true
            if exists && isDir.boolValue {
                if let sub = try? fm.contentsOfDirectory(atPath: url.path) {
                    let subSize = sub.reduce(Int64(0)) { total, name in
                        let subPath = url.appendingPathComponent(name)
                        let attrs = try? fm.attributesOfItem(atPath: subPath.path)
                        return total + ((attrs?[.size] as? Int64) ?? 0)
                    }
                    let linkMarker = isLink ? " → symlink" : ""
                    fileList.append("\(url.lastPathComponent)/\(linkMarker) (\(sub.count) items, \(ByteCountFormatter.string(fromByteCount: subSize, countStyle: .file)))")
                } else {
                    fileList.append("\(url.lastPathComponent)/ (unreadable)")
                }
            } else if exists {
                if let attrs = try? fm.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    let linkMarker = isLink ? " → symlink" : ""
                    fileList.append("\(url.lastPathComponent)\(linkMarker) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))")
                } else {
                    fileList.append(url.lastPathComponent)
                }
            }
        }
        AppLogger.shared.log(category: .model, message: "Cache contents (\(fileList.count) entries): \(fileList.joined(separator: ", "))")
    }

    private func migrateOldCacheIfNeeded() {
        let legacyWhisperId = "aufklarer/Whisper-Large-v3-Turbo-CoreML"
        let legacyDir = modelsRootDir
        let newDir = modelCacheDir(for: legacyWhisperId)

        guard legacyDir != newDir,
              FileManager.default.fileExists(atPath: legacyDir.path),
              let legacyContents = try? FileManager.default.contentsOfDirectory(atPath: legacyDir.path),
              !legacyContents.isEmpty else { return }

        let isAlreadyMigrated = legacyContents.allSatisfy { entry in
            let entryURL = legacyDir.appendingPathComponent(entry)
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: entryURL.path, isDirectory: &isDir)
            return isDir.boolValue && SupportedModel.all.contains(where: { $0.id.replacingOccurrences(of: "/", with: "--").replacingOccurrences(of: ".", with: "_") == entry })
        }

        if isAlreadyMigrated { return }

        do {
            try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
            for entry in legacyContents {
                guard !entry.hasPrefix(".") else { continue }
                let source = legacyDir.appendingPathComponent(entry)
                let dest = newDir.appendingPathComponent(entry)
                if FileManager.default.fileExists(atPath: dest.path) { continue }
                try FileManager.default.moveItem(at: source, to: dest)
            }
            AppLogger.shared.log(category: .model, message: "Migrated old cache to subdirectory")
        } catch {
            AppLogger.shared.log(category: .model, message: "Cache migration failed: \(error.localizedDescription)")
        }
    }

    private func modelCacheDir(for repoId: String) -> URL {
        let dirName = repoId
            .replacingOccurrences(of: "/", with: "--")
            .replacingOccurrences(of: ".", with: "_")
        return modelsRootDir.appendingPathComponent(dirName, isDirectory: true)
    }

    private func logHubCacheLocation() {
        let fm = FileManager.default
        let cachePath = modelCacheDir.path
        let totalSize = recursiveDirectorySize(fm, at: modelCacheDir)
        let sizeStr = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        AppLogger.shared.log(category: .model, message: "Model disk usage: \(sizeStr) at \(cachePath)")
        let hubDir = fm.homeDirectoryForCurrentUser.appendingPathComponent(".cache/huggingface/hub")
        if fm.fileExists(atPath: hubDir.path) {
            let hubSize = recursiveDirectorySize(fm, at: hubDir)
            let hubStr = ByteCountFormatter.string(fromByteCount: hubSize, countStyle: .file)
            AppLogger.shared.log(category: .model, message: "HF hub cache total size: \(hubStr)")
        }
    }

    private func recursiveDirectorySize(_ fm: FileManager, at url: URL) -> Int64 {
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let attrs = try? fm.attributesOfItem(atPath: fileURL.path) else { continue }
            let fileType = attrs[.type] as? FileAttributeType
            if fileType == .typeDirectory { continue }
            total += (attrs[.size] as? Int64) ?? 0
        }
        return total
    }
}

public enum ModelError: Error, LocalizedError {
    case modelNotLoaded
    case cacheIncomplete

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "ASR model is not loaded. Please download a model in Settings."
        case .cacheIncomplete: return "Model cache is incomplete after download."
        }
    }
}
