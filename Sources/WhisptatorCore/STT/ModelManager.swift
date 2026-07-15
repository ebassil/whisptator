import Foundation
import WhisperASR

public enum ModelDownloadStatus: Sendable {
    case notStarted
    case downloading(progress: Double, message: String)
    case loaded
    case failed(Error)
}

@Observable
public final class ModelManager: @unchecked Sendable {
    private var model: WhisperASRModel?
    private let modelCacheDir: URL
    private let modelId = "aufklarer/Whisper-Large-v3-Turbo-CoreML"

    public var downloadStatus: ModelDownloadStatus = .notStarted
    public var onStatusChange: ((ModelDownloadStatus) -> Void)?

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelCacheDir = appSupport.appendingPathComponent("Whisptator/Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelCacheDir, withIntermediateDirectories: true)
    }

    public func loadModel() async {
        downloadStatus = .downloading(progress: 0, message: "Starting...")
        onStatusChange?(downloadStatus)

        do {
            let loadedModel = try await WhisperASRModel.fromPretrained(
                modelId: modelId,
                cacheDir: modelCacheDir,
                offlineMode: false
            ) { [weak self] progress, message in
                guard let self else { return }
                self.downloadStatus = .downloading(progress: progress, message: message)
                self.onStatusChange?(self.downloadStatus)
            }

            model = loadedModel
            downloadStatus = .loaded
            onStatusChange?(downloadStatus)
        } catch {
            downloadStatus = .failed(error)
            onStatusChange?(downloadStatus)
        }
    }

    public func loadModelOffline() async {
        do {
            let loadedModel = try await WhisperASRModel.fromPretrained(
                modelId: modelId,
                cacheDir: modelCacheDir,
                offlineMode: true
            )
            model = loadedModel
            downloadStatus = .loaded
            onStatusChange?(downloadStatus)
        } catch {
            downloadStatus = .failed(error)
            onStatusChange?(downloadStatus)
        }
    }

    public func transcribe(audio: [Float], sampleRate: Int, language: String? = nil) async throws -> String {
        guard let model else {
            throw ModelError.modelNotLoaded
        }
        return try await model.transcribeAudio(audio, sampleRate: sampleRate, language: language)
    }

    public var isModelLoaded: Bool {
        model != nil
    }
}

public enum ModelError: Error, LocalizedError {
    case modelNotLoaded

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Whisper model is not loaded. Please download the model in Settings."
        }
    }
}
