import Foundation
import AVFoundation

public final class TranscriptionEngine: @unchecked Sendable {
    private let modelManager: ModelManager

    public init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    public func transcribe(audio: [Float], sampleRate: Int, language: String? = nil) async throws -> String {
        guard modelManager.isModelLoaded else {
            throw ModelError.modelNotLoaded
        }
        AppLogger.shared.log(category: .transcription, message: "Transcription started (samples: \(audio.count), sampleRate: \(sampleRate))")
        do {
            let result = try await modelManager.transcribe(audio: audio, sampleRate: sampleRate, language: language)
            AppLogger.shared.log(category: .transcription, message: "Transcription completed (text length: \(result.count))")
            return result
        } catch {
            AppLogger.shared.log(category: .transcription, message: "Transcription error: \(error.localizedDescription)")
            throw error
        }
    }

    public func transcribeBuffer(_ buffer: AVAudioPCMBuffer, language: String? = nil) async throws -> String {
        guard let channelData = buffer.floatChannelData?[0] else {
            throw TranscriptionError.noAudioData
        }

        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

        let sampleRate = Int(buffer.format.sampleRate)
        return try await transcribe(audio: samples, sampleRate: sampleRate, language: language)
    }
}

public enum TranscriptionError: Error, LocalizedError {
    case noAudioData

    public var errorDescription: String? {
        switch self {
        case .noAudioData: return "No audio data available in buffer."
        }
    }
}
