import Foundation

/// Downloads and locates the ONNX artifacts for the pyannote-based diarizer.
/// The pipeline is pyannote/speaker-diarization-3.1, whose config references
/// exactly these two models; we use the ungated `onnx-community` ONNX exports
/// of the same weights (MIT / CC-BY-4.0), so no Hugging Face token is required.
/// Failure to obtain them degrades speaker identification to OFF — never
/// blocks recording.
public actor DiarizationModelStore {
    public struct Repos: Sendable {
        public var segmentation: String
        public var embedding: String

        public init(segmentation: String, embedding: String) {
            self.segmentation = segmentation
            self.embedding = embedding
        }

        /// ONNX exports of the weights referenced by
        /// huggingface.co/pyannote/speaker-diarization-3.1 (segmentation-3.0
        /// + wespeaker-voxceleb-resnet34-LM). If upstream moves these repos,
        /// update the two ids here; download failures surface in Settings and
        /// diarization degrades gracefully.
        public static let standard = Repos(
            segmentation: "onnx-community/pyannote-segmentation-3.0",
            embedding: "onnx-community/wespeaker-voxceleb-resnet34-LM"
        )
    }

    public let repos: Repos
    public let modelsRoot: URL

    public init(repos: Repos = .standard) {
        self.repos = repos
        self.modelsRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Whisptator/Diarization")
    }

    private func dir(for repoId: String) -> URL {
        modelsRoot.appendingPathComponent(repoId.replacingOccurrences(of: "/", with: "--"))
    }

    public func localONNXURL(for repoId: String) -> URL? {
        let base = dir(for: repoId)
        guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: [.fileSizeKey]) else { return nil }
        for case let url as URL in enumerator where url.pathExtension == "onnx" {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 {
                return url
            }
        }
        return nil
    }

    public var isReady: Bool {
        localONNXURL(for: repos.segmentation) != nil && localONNXURL(for: repos.embedding) != nil
    }

    /// Downloads the fp32 `.onnx` graph from both repos (skipping the
    /// quantized variants). Throws `ModelDownloadError` with an actionable
    /// message for gated/missing repos.
    public func ensureDownloaded(token: String?, progress: @escaping @Sendable (Double, String) -> Void) async throws {
        for (index, repoId) in [repos.segmentation, repos.embedding].enumerated() {
            let downloader = HuggingFaceModelDownloader(repoId: repoId, cacheDir: dir(for: repoId), token: token)
            let baseProgress = Double(index) * 0.5
            try await downloader.ensureFiles(
                matching: { $0.path == "onnx/model.onnx" },
                progress: { p, message in progress(baseProgress + p * 0.5, message) }
            )
        }
    }
}

/// Observable wrapper so the Settings UI can show download state and errors.
@Observable
public final class DiarizationModelController: @unchecked Sendable {
    public enum Status: Equatable {
        case unknown
        case notDownloaded
        case downloading(Double, String)
        case ready
        case failed(String)
    }

    public private(set) var status: Status = .unknown
    public private(set) var isBusy = false

    public var failureMessage: String? {
        if case .failed(let message) = status { return message }
        return nil
    }

    public let store: DiarizationModelStore
    private let settings: AppSettings

    public init(settings: AppSettings, store: DiarizationModelStore = DiarizationModelStore()) {
        self.settings = settings
        self.store = store
    }

    public func refresh() async {
        let ready = await store.isReady
        if ready {
            status = .ready
        } else if case .failed = status {
            // keep the actionable error visible until a retry succeeds
        } else {
            status = .notDownloaded
        }
    }

    /// Downloads (or verifies) the diarization models. Returns false and sets
    /// `status = .failed(...)` on any error — the app keeps working without.
    @discardableResult
    public func ensureModels() async -> Bool {
        guard !isBusy else { return status == .ready }
        isBusy = true
        defer { isBusy = false }
        do {
            try await store.ensureDownloaded(token: settings.huggingFaceToken) { progress, message in
                Task { @MainActor in
                    self.status = .downloading(progress, message)
                }
            }
            status = .ready
            AppLogger.shared.log(category: .model, message: "Diarization models ready")
            return true
        } catch {
            status = .failed(error.localizedDescription)
            AppLogger.shared.log(category: .model, message: "Diarization model download failed: \(error.localizedDescription)")
            return false
        }
    }

    public func makeDiarizer() async -> PyannoteDiarizer? {
        guard await store.isReady else { return nil }
        let seg = await store.localONNXURL(for: store.repos.segmentation)
        let emb = await store.localONNXURL(for: store.repos.embedding)
        guard let seg, let emb else { return nil }
        return PyannoteDiarizer(segmentationModelURL: seg, embeddingModelURL: emb)
    }
}
