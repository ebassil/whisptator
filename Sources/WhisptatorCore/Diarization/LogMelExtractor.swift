import Foundation

/// Sliding-window log-mel filterbank features for the pyannote segmentation
/// model. Parameters mirror pyannote-audio's `LogMel` frontend at 16 kHz:
/// 400-sample (25 ms) Hann window, 160-sample (10 ms) hop, 512-point FFT,
/// 128 mel bins between 20 Hz and 7600 Hz, `log(power + eps)` with an
/// optional per-call mean subtraction (AAC-style normalization).
public struct LogMelExtractor: Sendable {
    public let sampleRate: Double
    public let windowSize: Int
    public let hopSize: Int
    public let fftSize: Int
    public let melCount: Int
    public let fMin: Double
    public let fMax: Double
    public let logEpsilon: Double
    public let normalizeMean: Bool

    public init(
        sampleRate: Double = 16_000,
        windowSize: Int = 400,
        hopSize: Int = 160,
        fftSize: Int = 512,
        melCount: Int = 128,
        fMin: Double = 20,
        fMax: Double = 7_600,
        logEpsilon: Double = 1e-10,
        normalizeMean: Bool = true
    ) {
        precondition(fftSize >= windowSize && fftSize & (fftSize - 1) == 0)
        self.sampleRate = sampleRate
        self.windowSize = windowSize
        self.hopSize = hopSize
        self.fftSize = fftSize
        self.melCount = melCount
        self.fMin = fMin
        self.fMax = fMax
        self.logEpsilon = logEpsilon
        self.normalizeMean = normalizeMean
    }

    /// Returns frames x melCount row-major.
    public func extract(from samples: [Float]) -> [[Double]] {
        guard samples.count >= windowSize else { return [] }
        let window = hannWindow(windowSize)
        let filters = melFilterBank()
        let binCount = fftSize / 2 + 1

        let frameCount = (samples.count - windowSize) / hopSize + 1
        var out = [[Double]](repeating: [Double](repeating: 0, count: melCount), count: frameCount)

        var padded = [Double](repeating: 0, count: fftSize)
        for f in 0..<frameCount {
            let start = f * hopSize
            for i in 0..<fftSize {
                if i < windowSize && start + i < samples.count {
                    padded[i] = Double(samples[start + i]) * window[i]
                } else {
                    padded[i] = 0
                }
            }
            var real = padded
            var imag = [Double](repeating: 0, count: fftSize)
            FFT.realImaginaryTransform(real: &real, imag: &imag, inverse: false)

            var melValues = [Double](repeating: 0, count: melCount)
            for m in 0..<melCount {
                var acc = 0.0
                let filter = filters[m]
                for k in 0..<binCount {
                    let weight = filter[k]
                    if weight == 0 { continue }
                    let power = real[k] * real[k] + imag[k] * imag[k]
                    acc += weight * power / Double(fftSize * fftSize)
                }
                melValues[m] = Foundation.log(max(acc, 0) + logEpsilon)
            }
            out[f] = melValues
        }

        if normalizeMean, !out.isEmpty {
            let total = Double(out.count * melCount)
            var mean = 0.0
            for frame in out { for v in frame { mean += v } }
            mean /= total
            for f in 0..<out.count {
                for m in 0..<melCount { out[f][m] -= mean }
            }
        }
        return out
    }

    private func hannWindow(_ n: Int) -> [Double] {
        (0..<n).map { -0.5 * cos(2 * Double.pi * Double($0) / Double(n)) + 0.5 }
    }

    private func melFilterBank() -> [[Double]] {
        let binCount = fftSize / 2 + 1
        func hzToMel(_ hz: Double) -> Double { 2595.0 * log10(1.0 + hz / 700.0) }
        func melToHz(_ mel: Double) -> Double { 700.0 * (pow(10.0, mel / 2595.0) - 1.0) }
        let melLow = hzToMel(fMin)
        let melHigh = hzToMel(fMax)
        let points = (0...(melCount + 2)).map { mel in
            melLow + Double(mel) * (melHigh - melLow) / Double(melCount + 2)
        }
        let hzPoints = points.map(melToHz)
        let binPoints = hzPoints.map { ($0 / (sampleRate / 2)) * Double(binCount - 1) }

        var filters = [[Double]](repeating: [Double](repeating: 0, count: binCount), count: melCount)
        for m in 0..<melCount {
            let left = binPoints[m]
            let center = binPoints[m + 1]
            let right = binPoints[m + 2]
            for k in 0..<binCount {
                let kf = Double(k)
                if kf > left && kf < center && center > left {
                    filters[m][k] = (kf - left) / (center - left)
                } else if kf >= center && kf < right && right > center {
                    filters[m][k] = (right - kf) / (right - center)
                }
            }
        }
        return filters
    }
}

/// In-place iterative radix-2 FFT (Cooley-Tukey).
enum FFT {
    static func realImaginaryTransform(real: inout [Double], imag: inout [Double], inverse: Bool) {
        let n = real.count
        precondition(n > 0 && n & (n - 1) == 0, "FFT length must be a power of two")

        var j = 0
        for i in 1..<n {
            var bit = n >> 1
            while j & bit != 0 {
                j ^= bit
                bit >>= 1
            }
            j |= bit
            if i < j {
                real.swapAt(i, j)
                imag.swapAt(i, j)
            }
        }

        var len = 2
        while len <= n {
            let ang = -2 * Double.pi / Double(len) * (inverse ? -1 : 1)
            let wpr = cos(ang)
            let wpi = sin(ang)
            var i = 0
            while i < n {
                var wr = 1.0
                var wi = 0.0
                let half = len / 2
                for k in 0..<half {
                    let a = i + k
                    let b = a + half
                    let tr = wr * real[b] - wi * imag[b]
                    let ti = wr * imag[b] + wi * real[b]
                    real[b] = real[a] - tr
                    imag[b] = imag[a] - ti
                    real[a] += tr
                    imag[a] += ti
                    let nwr = wr * wpr - wi * wpi
                    wi = wr * wpi + wi * wpr
                    wr = nwr
                }
                i += len
            }
            len <<= 1
        }

        if inverse {
            let scale = 1.0 / Double(n)
            for i in 0..<n {
                real[i] *= scale
                imag[i] *= scale
            }
        }
    }

    /// Naive O(n^2) DFT for test reference.
    static func referenceDFT(real: [Double], imag: [Double]) -> [(re: Double, im: Double)] {
        let n = real.count
        return (0..<n).map { k in
            var sr = 0.0
            var si = 0.0
            for t in 0..<n {
                let angle = -2 * Double.pi * Double(k * t) / Double(n)
                let c = cos(angle)
                let s = sin(angle)
                sr += real[t] * c - imag[t] * s
                si += real[t] * s + imag[t] * c
            }
            return (sr, si)
        }
    }
}
