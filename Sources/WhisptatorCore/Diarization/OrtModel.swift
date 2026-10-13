import Foundation
@preconcurrency import OnnxRuntimeBindings

/// Minimal wrapper around the ONNX Runtime Objective-C bindings: load a float
/// model, run it with a single float input tensor, read the first output as a
/// float array with its dimensions.
final class OrtModel: @unchecked Sendable {
    enum OrtModelError: Error, LocalizedError {
        case loadFailed(String)
        case shapeMismatch(String)
        var errorDescription: String? {
            switch self {
            case .loadFailed(let m): return "ONNX model load failed: \(m)"
            case .shapeMismatch(let m): return "ONNX tensor shape error: \(m)"
            }
        }
    }

    nonisolated(unsafe) private static let env: ORTEnv = {
        do {
            return try ORTEnv(loggingLevel: .warning)
        } catch {
            fatalError("Could not create ORTEnv: \(error)")
        }
    }()

    let url: URL
    private let session: ORTSession
    let inputName: String
    let outputName: String

    init(url: URL, intraOpThreads: Int = 2) throws {
        self.url = url
        let options = try ORTSessionOptions()
        try options.setIntraOpNumThreads(Int32(intraOpThreads))
        do {
            self.session = try ORTSession(env: Self.env, modelPath: url.path, sessionOptions: options)
        } catch {
            throw OrtModelError.loadFailed("\(url.lastPathComponent): \(error.localizedDescription)")
        }
        let inputs = try session.inputNames()
        guard let first = inputs.first else {
            throw OrtModelError.loadFailed("\(url.lastPathComponent): model has no inputs")
        }
        let outputs = try session.outputNames()
        guard let out = outputs.first else {
            throw OrtModelError.loadFailed("\(url.lastPathComponent): model has no outputs")
        }
        self.inputName = first
        self.outputName = out
    }

    func run(input: [Float], shape: [Int]) throws -> (data: [Float], dimensions: [Int]) {
        var mutableInput = input
        let data = Data(bytes: &mutableInput, count: input.count * MemoryLayout<Float>.size)
        let value: ORTValue
        do {
            value = try ORTValue(
                tensorData: NSMutableData(data: data),
                elementType: .float,
                shape: shape.map { NSNumber(value: $0) }
            )
        } catch {
            throw OrtModelError.shapeMismatch("input shape \(shape): \(error.localizedDescription)")
        }
        let outputs = try session.run(withInputs: [inputName: value], outputNames: Set([outputName]), runOptions: nil)
        guard let outputValue = outputs[outputName] else {
            throw OrtModelError.shapeMismatch("missing output tensor \(outputName)")
        }
        let outData = try outputValue.tensorData()
        let info = try outputValue.tensorTypeAndShapeInfo()
        let dims = info.shape.map { $0.intValue }
        var floats = [Float](repeating: 0, count: outData.count / MemoryLayout<Float>.size)
        floats.withUnsafeMutableBytes { dst in
            outData.copyBytes(to: dst, count: min(dst.count, outData.count))
        }
        return (floats, dims)
    }
}
