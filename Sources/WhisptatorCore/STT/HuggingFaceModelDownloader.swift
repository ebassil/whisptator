import Foundation

enum ModelDownloadError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case fileNotFound(String)
    case symlinkFailed(URL, URL)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from HuggingFace API"
        case .httpError(let code): return "HTTP \(code) from HuggingFace API"
        case .fileNotFound(let path): return "File not found: \(path)"
        case .symlinkFailed(let from, let to): return "Symlink failed: \(from.path) -> \(to.path)"
        }
    }
}

public struct RepoFile: Sendable, Equatable {
    public let path: String
    public let size: Int
}

private struct HuggingFaceModelResponse: Decodable {
    struct Sibling: Decodable {
        let rfilename: String
        let size: Int?
    }
    let siblings: [Sibling]
}

public actor HuggingFaceModelDownloader {
    public let repoId: String
    public let cacheDir: URL
    public let hubCacheDir: URL

    private let session: URLSession
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    private static let skipFiles: Set<String> = [".gitattributes", "README.md"]

    public init(repoId: String, cacheDir: URL) {
        self.repoId = repoId
        self.cacheDir = cacheDir
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.fileManager = FileManager.default

        let home = fileManager.homeDirectoryForCurrentUser
        self.hubCacheDir = home
            .appendingPathComponent(".cache/huggingface/hub")
            .appendingPathComponent("models--\(repoId.replacingOccurrences(of: "/", with: "--"))")
    }

    public func listRepoFiles() async throws -> [RepoFile] {
        let url = URL(string: "https://huggingface.co/api/models/\(repoId)")!
        AppLogger.shared.log(category: .model, message: "listRepoFiles: fetching \(url.absoluteString)")
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.shared.log(category: .model, message: "listRepoFiles: no HTTP response")
            throw ModelDownloadError.invalidResponse
        }
        AppLogger.shared.log(category: .model, message: "listRepoFiles: HTTP \(httpResponse.statusCode), \(data.count) bytes")
        guard httpResponse.statusCode == 200 else {
            AppLogger.shared.log(category: .model, message: "listRepoFiles: unexpected status \(httpResponse.statusCode)")
            throw ModelDownloadError.httpError(httpResponse.statusCode)
        }
        let decoded = try decoder.decode(HuggingFaceModelResponse.self, from: data)
        let files = decoded.siblings
            .filter { !Self.skipFiles.contains($0.rfilename) }
            .map { RepoFile(path: $0.rfilename, size: $0.size ?? 0) }
        let totalSize = files.reduce(0) { $0 + $1.size }
        AppLogger.shared.log(category: .model, message: "listRepoFiles: found \(files.count) files, total \(ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)) (\(files.map(\.path).joined(separator: ", ")))")
        return files
    }

    public func downloadFile(path: String, to destination: URL) async throws {
        let downloadURL = URL(string: "https://huggingface.co/\(repoId)/resolve/main/\(path)")!
        AppLogger.shared.log(category: .model, message: "downloadFile: starting \(path) -> \(destination.path)")
        let (localURL, response) = try await session.download(from: downloadURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.shared.log(category: .model, message: "downloadFile: no HTTP response for \(path)")
            throw ModelDownloadError.invalidResponse
        }
        AppLogger.shared.log(category: .model, message: "downloadFile: \(path) HTTP \(httpResponse.statusCode), temp at \(localURL.path)")
        guard httpResponse.statusCode == 200 else {
            throw ModelDownloadError.httpError(httpResponse.statusCode)
        }
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: localURL, to: destination)
        if fileManager.fileExists(atPath: destination.path),
           let attrs = try? fileManager.attributesOfItem(atPath: destination.path),
           let size = attrs[.size] as? Int64 {
            AppLogger.shared.log(category: .model, message: "downloadFile: \(path) saved (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))")
        } else {
            AppLogger.shared.log(category: .model, message: "downloadFile: \(path) saved (size unknown or missing after move)")
        }
    }

    public static func hubCacheRoot() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/huggingface/hub")
    }

    public static func scanHubCache() -> [String] {
        let root = hubCacheRoot()
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: root.path) else {
            return []
        }
        return contents
            .filter { $0.hasPrefix("models--") }
            .compactMap { name -> String? in
                let repo = name.replacingOccurrences(of: "models--", with: "")
                    .replacingOccurrences(of: "--", with: "/")
                let parts = repo.split(separator: "/")
                guard parts.count == 2 else { return nil }
                return "\(parts[0])/\(parts[1])"
            }
    }

    public static func isCachedInHub(repoId: String) -> Bool {
        let dirName = "models--\(repoId.replacingOccurrences(of: "/", with: "--"))"
        let path = hubCacheRoot().appendingPathComponent(dirName)
        return FileManager.default.fileExists(atPath: path.path)
    }

    public func hubCacheSnapshotPath() -> URL? {
        let refsMain = hubCacheDir.appendingPathComponent("refs/main")
        AppLogger.shared.log(category: .model, message: "hubCacheSnapshotPath: checking \(refsMain.path)")
        guard let commitHash = try? String(contentsOf: refsMain, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              !commitHash.isEmpty else {
            AppLogger.shared.log(category: .model, message: "hubCacheSnapshotPath: no refs/main or empty commit hash")
            return nil
        }
        AppLogger.shared.log(category: .model, message: "hubCacheSnapshotPath: commit hash = \(commitHash)")
        let snapshotPath = hubCacheDir.appendingPathComponent("snapshots/\(commitHash)")
        guard fileManager.fileExists(atPath: snapshotPath.path) else {
            AppLogger.shared.log(category: .model, message: "hubCacheSnapshotPath: snapshot dir not found at \(snapshotPath.path)")
            return nil
        }
        if let contents = try? fileManager.contentsOfDirectory(atPath: snapshotPath.path) {
            AppLogger.shared.log(category: .model, message: "hubCacheSnapshotPath: snapshot dir contents (\(contents.count)): \(contents.joined(separator: ", "))")
        }
        return snapshotPath
    }

    public func symlinkOrCopy(from source: URL, to destination: URL) throws {
        AppLogger.shared.log(category: .model, message: "symlinkOrCopy: \(source.path) -> \(destination.path)")
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) {
            AppLogger.shared.log(category: .model, message: "symlinkOrCopy: destination exists, removing")
            try fileManager.removeItem(at: destination)
        }
        do {
            try fileManager.createSymbolicLink(at: destination, withDestinationURL: source)
            AppLogger.shared.log(category: .model, message: "symlinkOrCopy: symlink created")
        } catch {
            AppLogger.shared.log(category: .model, message: "symlinkOrCopy: symlink failed (\(error.localizedDescription)), falling back to copy")
            try fileManager.copyItem(at: source, to: destination)
            AppLogger.shared.log(category: .model, message: "symlinkOrCopy: copy completed")
        }
    }

    private func filePaths(for files: [RepoFile]) -> [String] {
        files.map(\.path)
    }

    /// Returns just the .mlmodelc directory paths that must exist for CoreML loading.
    /// These are macOS package directories, each containing ~6 sub-files.
    public static func requiredMLModelCFiles() -> [String] {
        [
            "MelSpectrogram.mlmodelc",
            "AudioEncoder.mlmodelc",
            "TextDecoder.mlmodelc",
            "TextDecoderContextPrefill.mlmodelc",
        ]
    }

    public static func requiredModelFiles() -> [String] {
        [
            "MelSpectrogram.mlmodelc/coremldata.bin",
            "MelSpectrogram.mlmodelc/analytics/coremldata.bin",
            "MelSpectrogram.mlmodelc/metadata.json",
            "MelSpectrogram.mlmodelc/model.mil",
            "MelSpectrogram.mlmodelc/model.mlmodel",
            "MelSpectrogram.mlmodelc/weights/weight.bin",
            "AudioEncoder.mlmodelc/coremldata.bin",
            "AudioEncoder.mlmodelc/analytics/coremldata.bin",
            "AudioEncoder.mlmodelc/metadata.json",
            "AudioEncoder.mlmodelc/model.mil",
            "AudioEncoder.mlmodelc/model.mlmodel",
            "AudioEncoder.mlmodelc/weights/weight.bin",
            "TextDecoder.mlmodelc/coremldata.bin",
            "TextDecoder.mlmodelc/analytics/coremldata.bin",
            "TextDecoder.mlmodelc/metadata.json",
            "TextDecoder.mlmodelc/model.mil",
            "TextDecoder.mlmodelc/model.mlmodel",
            "TextDecoder.mlmodelc/weights/weight.bin",
            "TextDecoderContextPrefill.mlmodelc/coremldata.bin",
            "TextDecoderContextPrefill.mlmodelc/analytics/coremldata.bin",
            "TextDecoderContextPrefill.mlmodelc/metadata.json",
            "TextDecoderContextPrefill.mlmodelc/model.mil",
            "TextDecoderContextPrefill.mlmodelc/model.mlmodel",
            "TextDecoderContextPrefill.mlmodelc/weights/weight.bin",
            "config.json",
            "generation_config.json",
            "manifest.json",
            "tokenizer_config.json",
            "tokenizer.json",
        ]
    }

    public func linkToHubCache(from sourceDir: URL) async throws {
        guard let snapshotPath = hubCacheSnapshotPath() else { return }
        let files = try await listRepoFiles()
        for file in files {
            let source = sourceDir.appendingPathComponent(file.path)
            let dest = snapshotPath.appendingPathComponent(file.path)
            if fileManager.fileExists(atPath: source.path) {
                try symlinkOrCopy(from: source, to: dest)
            }
        }
    }

    public func ensureModelInCache(progress: @escaping @Sendable (Double, String) -> Void) async throws {
        AppLogger.shared.log(category: .model, message: "HFDownloader: ensureModelInCache start. repoId=\(repoId), cacheDir=\(cacheDir.path)")

        let files = try await listRepoFiles()
        let required = Self.requiredModelFiles()
        AppLogger.shared.log(category: .model, message: "HFDownloader: \(files.count) files from API, \(required.count) required by app")
        let filePaths = Set(files.map(\.path))
        let missingFromApi = required.filter { !filePaths.contains($0) }
        if !missingFromApi.isEmpty {
            AppLogger.shared.log(category: .model, message: "HFDownloader: WARNING - required files missing from API: \(missingFromApi.joined(separator: ", "))")
        }
        let totalBytes = files.reduce(0) { $0 + $1.size }
        var downloadedBytes = 0

        let fileCount = max(files.count, 1)
        var completedFiles = 0
        func computeProgress() -> Double {
            if totalBytes > 0 {
                return min(Double(downloadedBytes) / Double(totalBytes), 1.0)
            }
            return min(Double(completedFiles) / Double(fileCount), 1.0)
        }

        if let snapshotPath = hubCacheSnapshotPath() {
            AppLogger.shared.log(category: .model, message: "HFDownloader: HF hub cache found at \(snapshotPath.path)")
            progress(0, "Checking HuggingFace hub cache...")
            var pendingFiles: [RepoFile] = []
            for file in files {
                let source = snapshotPath.appendingPathComponent(file.path)
                let destination = cacheDir.appendingPathComponent(file.path)
                if fileManager.fileExists(atPath: source.path) {
                    AppLogger.shared.log(category: .model, message: "HFDownloader: linking \(file.path) from hub cache")
                    try symlinkOrCopy(from: source, to: destination)
                    downloadedBytes += file.size
                    completedFiles += 1
                    progress(computeProgress(), "Linked \(file.path) from hub cache")
                } else {
                    AppLogger.shared.log(category: .model, message: "HFDownloader: \(file.path) not in hub cache snapshot, will download")
                    pendingFiles.append(file)
                }
            }
            if pendingFiles.isEmpty {
                AppLogger.shared.log(category: .model, message: "HFDownloader: all files linked from hub cache")
                progress(1.0, "All files linked from hub cache")
                return
            }
            AppLogger.shared.log(category: .model, message: "HFDownloader: \(pendingFiles.count) files to download after hub cache reuse")
            for file in pendingFiles {
                let destination = cacheDir.appendingPathComponent(file.path)
                try await downloadFile(path: file.path, to: destination)
                downloadedBytes += file.size
                completedFiles += 1
                progress(computeProgress(), "Downloaded \(file.path)")
            }
        } else {
            AppLogger.shared.log(category: .model, message: "HFDownloader: no HF hub cache found, downloading all \(files.count) files")
            for file in files {
                let destination = cacheDir.appendingPathComponent(file.path)
                try await downloadFile(path: file.path, to: destination)
                downloadedBytes += file.size
                completedFiles += 1
                progress(computeProgress(), "Downloaded \(file.path)")
            }
        }
        AppLogger.shared.log(category: .model, message: "HFDownloader: all files ready (\(ByteCountFormatter.string(fromByteCount: Int64(downloadedBytes), countStyle: .file)) downloaded)")
        progress(1.0, "Model files ready")
    }
}
