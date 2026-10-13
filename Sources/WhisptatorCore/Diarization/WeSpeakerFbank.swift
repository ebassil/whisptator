import Foundation

/// Kaldi-style 80-bin log-mel fbank features for the wespeaker embedding model
/// (`onnx-community/wespeaker-voxceleb-resnet34-LM`). Ported to match the
/// reference `WeSpeakerFeatureExtractor` exactly (transformers.js):
/// int16 rescale, per-frame DC removal, HTK pre-emphasis, symmetric Hamming
/// window, snip edges, 512-point unnormalized FFT, power spectrum, triangular
/// filters constructed in mel space (20 Hz – 8000 Hz, 80 bins), floor
/// 1.1920928955078125e-7 (2^-23), natural log, then per-bin cepstral mean
/// subtraction (`fbank_centering_span: null`).
///
/// Calibration note: filter-area normalization (`norm_filters`) and pre-emphasis
/// continued across frame boundaries were both tried against ground-truth
/// multi-speaker audio and moved same/different-speaker distances by under 0.01.
/// The per-bin mean subtraction below cancels any constant per-bin offset, so
/// those reference variants are deliberately not reproduced.
struct WeSpeakerFbank: Sendable {
    let sampleRate: Int
    let frameLength: Int
    let hopLength: Int
    let fftSize: Int
    let melBins: Int
    let lowFreq: Double
    let preemphasis: Double
    let melFloor: Double
    let int16Scale: Double
    let minNumFrames: Int

    init(
        sampleRate: Int = 16_000,
        frameLength: Int = 400,
        hopLength: Int = 160,
        fftSize: Int = 512,
        melBins: Int = 80,
        lowFreq: Double = 20,
        preemphasis: Double = 0.97,
        melFloor: Double = 1.1920928955078125e-7,
        int16Scale: Double = 32_768,
        minNumFrames: Int = 9
    ) {
        self.sampleRate = sampleRate
        self.frameLength = frameLength
        self.hopLength = hopLength
        self.fftSize = fftSize
        self.melBins = melBins
        self.lowFreq = lowFreq
        self.preemphasis = preemphasis
        self.melFloor = melFloor
        self.int16Scale = int16Scale
        self.minNumFrames = minNumFrames
    }

    /// Returns numFrames x melBins row-major.
    func extract(from samples: [Float]) -> [[Double]] {
        let numFrequencyBins = fftSize / 2 + 1
        let waveform = samples.map { Double($0) * int16Scale }
        let computed = waveform.isEmpty ? 1 : (waveform.count - frameLength) / hopLength + 1
        let numFrames = max(minNumFrames, computed)

        let window = hammingWindow(frameLength)
        let filters = melFilterBank(binCount: numFrequencyBins)

        var magnitudes = [[Double]](repeating: [Double](repeating: 0, count: numFrequencyBins), count: numFrames)
        var real = [Double](repeating: 0, count: fftSize)
        var imag = [Double](repeating: 0, count: fftSize)

        for frame in 0..<numFrames {
            let offset = frame * hopLength
            let bufferSize = max(0, min(waveform.count - offset, frameLength))
            for i in 0..<fftSize {
                real[i] = 0
                imag[i] = 0
            }
            if bufferSize > 0 {
                var buffer = Array(waveform[offset..<(offset + bufferSize)])
                let mean = buffer.reduce(0, +) / Double(bufferSize)
                for j in 0..<bufferSize { buffer[j] -= mean }
                for j in stride(from: bufferSize - 1, through: 1, by: -1) {
                    buffer[j] -= preemphasis * buffer[j - 1]
                }
                buffer[0] *= 1 - preemphasis
                for j in 0..<bufferSize { buffer[j] *= window[j] }
                for j in 0..<bufferSize { real[j] = buffer[j] }
            }
            FFT.realImaginaryTransform(real: &real, imag: &imag, inverse: false)
            for k in 0..<numFrequencyBins {
                magnitudes[frame][k] = real[k] * real[k] + imag[k] * imag[k]
            }
        }

        var frames = [[Double]](repeating: [Double](repeating: 0, count: melBins), count: numFrames)
        for frame in 0..<numFrames {
            let mag = magnitudes[frame]
            for m in 0..<melBins {
                var acc = 0.0
                let filter = filters[m]
                for k in 0..<numFrequencyBins where filter[k] != 0 {
                    acc += filter[k] * mag[k]
                }
                frames[frame][m] = Foundation.log(max(acc, melFloor))
            }
        }

        // Cepstral mean subtraction per mel bin (fbank_centering_span: null).
        for m in 0..<melBins {
            let binMean = frames.reduce(0) { $0 + $1[m] } / Double(numFrames)
            for frame in 0..<numFrames {
                frames[frame][m] -= binMean
            }
        }
        return frames
    }

    private func hammingWindow(_ n: Int) -> [Double] {
        (0..<n).map { 0.54 - 0.46 * cos(2 * Double.pi * Double($0) / Double(n - 1)) }
    }

    /// Triangular filters built in mel space (kaldi scale), matching
    /// `mel_filter_bank(..., mel_scale: 'kaldi', triangularize_in_mel_space: true)`.
    private func melFilterBank(binCount: Int) -> [[Double]] {
        func hertzToMel(_ hz: Double) -> Double { 2595.0 * log10(1.0 + hz / 700.0) }
        let highFreq = Double(sampleRate / 2)
        let melLow = hertzToMel(lowFreq)
        let melHigh = hertzToMel(highFreq)
        let pointCount = melBins + 2
        let melPoints = (0..<pointCount).map { melLow + Double($0) * (melHigh - melLow) / Double(pointCount - 1) }
        let fftBinWidth = Double(sampleRate) / Double((binCount - 1) * 2)
        let fftMels = (0..<binCount).map { hertzToMel(Double($0) * fftBinWidth) }

        var filters = [[Double]](repeating: [Double](repeating: 0, count: binCount), count: melBins)
        for m in 0..<melBins {
            let left = melPoints[m]
            let center = melPoints[m + 1]
            let right = melPoints[m + 2]
            for k in 0..<binCount {
                let f = fftMels[k]
                let down = (f - left) / (center - left)
                let up = (right - f) / (right - center)
                filters[m][k] = max(0, min(down, up))
            }
        }
        return filters
    }
}
