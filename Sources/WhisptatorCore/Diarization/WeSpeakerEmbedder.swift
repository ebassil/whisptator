import Foundation

/// Produces 256-dimensional speaker embeddings for windows of 16 kHz mono audio
/// using the ONNX export of `wespeaker-voxceleb-resnet34-LM`.
///
/// Kept separate from the diarization pipeline so calibration experiments can
/// run the exact production frontend + model against ground-truth audio without
/// reimplementing either.
struct WeSpeakerEmbedder: Sendable {
    let model: OrtModel
    let fbank: WeSpeakerFbank

    init(model: OrtModel, fbank: WeSpeakerFbank = WeSpeakerFbank()) {
        self.model = model
        self.fbank = fbank
    }

    /// L2-normalized embedding for one window, or nil when the model or the
    /// feature extraction produced nothing usable.
    func embed(_ samples: [Float]) -> [Double]? {
        guard samples.count >= 1600 else { return nil }
        let features = fbank.extract(from: samples)
        guard !features.isEmpty, let melCount = features.first?.count else { return nil }
        var flat = [Float](repeating: 0, count: features.count * melCount)
        for (f, frame) in features.enumerated() {
            for m in 0..<melCount {
                flat[f * melCount + m] = Float(frame[m])
            }
        }
        do {
            // Input layout: (1, num_frames, 80) log-mel fbank.
            let (data, dims) = try model.run(input: flat, shape: [1, features.count, melCount])
            let embedding = EmbeddingMath.l2Normalize(averageOverTime(data: data, dims: dims))
            return embedding.isEmpty ? nil : embedding
        } catch {
            AppLogger.shared.log(category: .model, message: "Embedding inference failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Output may be (1, D) or (1, T, D); average over time if 3-D.
    private func averageOverTime(data: [Float], dims: [Int]) -> [Double] {
        guard let last = dims.last, last > 0 else { return [] }
        let frames = dims.count >= 3 ? max(1, data.count / last) : 1
        var sums = [Double](repeating: 0, count: last)
        for f in 0..<frames {
            for d in 0..<last {
                let index = f * last + d
                if index < data.count { sums[d] += Double(data[index]) }
            }
        }
        return sums.map { $0 / Double(frames) }
    }
}
