import Foundation

public enum ASRModelType: String, Sendable, CaseIterable {
    case whisper
    case parakeet
    case parakeetStreaming
    case nemotron
    case omnilingual
}

public struct SupportedModel: Identifiable, Sendable, Equatable {
    public let id: String
    public let type: ASRModelType
    public let name: String
    public let description: String
    public let sizeLabel: String
    public let modelSize: Int64

    public init(id: String, type: ASRModelType, name: String, description: String, sizeLabel: String, modelSize: Int64) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.sizeLabel = sizeLabel
        self.modelSize = modelSize
    }
}

extension SupportedModel {
    public static let all: [SupportedModel] = [
        SupportedModel(
            id: "aufklarer/Whisper-Large-v3-Turbo-CoreML",
            type: .whisper,
            name: "Whisper Large-v3 Turbo",
            description: "Whisper large-v3 turbo via native CoreML runtime on ANE. Multilingual, best accuracy.",
            sizeLabel: "~1.5B params",
            modelSize: 2_500_000_000
        ),
        SupportedModel(
            id: "aufklarer/Parakeet-TDT-v3-CoreML-INT8-30s",
            type: .parakeet,
            name: "Parakeet TDT v3",
            description: "NVIDIA FastConformer + TDT decoder on CoreML ANE. 25 European languages, 32× realtime.",
            sizeLabel: "~600M params",
            modelSize: 900_000_000
        ),
        SupportedModel(
            id: "aufklarer/Parakeet-EOU-120M-CoreML-INT8",
            type: .parakeetStreaming,
            name: "Parakeet EOU",
            description: "Streaming dictation with end-of-utterance detection. 120M params, 25 European languages.",
            sizeLabel: "~120M params",
            modelSize: 180_000_000
        ),
        SupportedModel(
            id: "aufklarer/Nemotron-3.5-ASR-Streaming-0.6B-CoreML-INT8",
            type: .nemotron,
            name: "Nemotron Streaming",
            description: "NVIDIA Nemotron-3.5 streaming ASR with native punctuation. 0.6B params, 76 language-locales.",
            sizeLabel: "~600M params",
            modelSize: 900_000_000
        ),
        SupportedModel(
            id: "aufklarer/Omnilingual-ASR-CTC-300M-CoreML-INT8-10s",
            type: .omnilingual,
            name: "Omnilingual ASR",
            description: "Meta wav2vec2 + CTC on CoreML ANE. 300M params, 1,672 languages across 32 scripts.",
            sizeLabel: "~300M params",
            modelSize: 450_000_000
        ),
    ]

    public static func model(for id: String) -> SupportedModel? {
        all.first { $0.id == id }
    }

    public static var `default`: SupportedModel {
        all.first { $0.type == .whisper }!
    }
}
