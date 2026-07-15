import Foundation
import AVFoundation

public final class AudioFileSaver: @unchecked Sendable {
    public init() {}

    @discardableResult
    public func saveAudioFile(samples: [Float], sampleRate: Int, to directory: String) -> String? {
        let fileManager = FileManager.default
        let dirURL = URL(fileURLWithPath: directory)

        if !fileManager.fileExists(atPath: directory) {
            try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "dictation_\(timestamp).wav"
        let fileURL = dirURL.appendingPathComponent(filename)

        guard writeWAV(samples: samples, sampleRate: sampleRate, to: fileURL) else { return nil }
        return fileURL.path
    }

    private func writeWAV(samples: [Float], sampleRate: Int, to url: URL) -> Bool {
        let sampleRateInt32 = Int32(sampleRate)
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let bytesPerSample = bitsPerSample / 8
        let numSamples = samples.count
        let dataSize = numSamples * Int(bytesPerSample)
        let headerSize = 44
        let totalSize = headerSize + dataSize

        var header = Data()
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // RIFF
        header.append(contentsOf: withUnsafeBytes(of: Int32(totalSize - 8)) { Data($0) })
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // WAVE
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // fmt 
        header.append(contentsOf: withUnsafeBytes(of: Int32(16)) { Data($0) }) // chunk size
        header.append(contentsOf: withUnsafeBytes(of: Int16(1)) { Data($0) }) // PCM format
        header.append(contentsOf: withUnsafeBytes(of: Int16(1)) { Data($0) }) // mono
        header.append(contentsOf: withUnsafeBytes(of: Int32(sampleRateInt32)) { Data($0) }) // sample rate
        let byteRate = sampleRateInt32 * Int32(bitsPerSample / 8) * Int32(numChannels)
        header.append(contentsOf: withUnsafeBytes(of: Int32(byteRate)) { Data($0) })
        let blockAlign = Int16(bitsPerSample / 8) * numChannels
        header.append(contentsOf: withUnsafeBytes(of: Int16(blockAlign)) { Data($0) })
        header.append(contentsOf: withUnsafeBytes(of: Int16(bitsPerSample)) { Data($0) })
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // data
        header.append(contentsOf: withUnsafeBytes(of: Int32(dataSize)) { Data($0) })

        var wavData = header
        var int16Samples = [Int16](repeating: 0, count: samples.count)
        for (i, sample) in samples.enumerated() {
            let clamped = max(-1.0, min(1.0, sample))
            int16Samples[i] = Int16(clamped * Float(Int16.max))
        }
        wavData.append(contentsOf: withUnsafeBytes(of: &int16Samples) { Data($0) })

        do {
            try wavData.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}