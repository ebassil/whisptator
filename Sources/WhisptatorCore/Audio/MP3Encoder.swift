import Foundation

@_silgen_name("lame_init")
func _lame_init() -> OpaquePointer?

@_silgen_name("lame_close")
func _lame_close(_: OpaquePointer?)

@_silgen_name("lame_set_in_samplerate")
func _lame_set_in_samplerate(_: OpaquePointer?, _: Int32) -> Int32

@_silgen_name("lame_set_out_samplerate")
func _lame_set_out_samplerate(_: OpaquePointer?, _: Int32) -> Int32

@_silgen_name("lame_set_num_channels")
func _lame_set_num_channels(_: OpaquePointer?, _: Int32) -> Int32

@_silgen_name("lame_set_brate")
func _lame_set_brate(_: OpaquePointer?, _: Int32) -> Int32

@_silgen_name("lame_set_quality")
func _lame_set_quality(_: OpaquePointer?, _: Int32) -> Int32

@_silgen_name("lame_init_params")
func _lame_init_params(_: OpaquePointer?) -> Int32

@_silgen_name("lame_encode_buffer_ieee_float")
func _lame_encode_buffer_ieee_float(
    _: OpaquePointer?,
    _: UnsafePointer<Float>?,
    _: UnsafePointer<Float>?,
    _: Int32,
    _: UnsafeMutablePointer<UInt8>?,
    _: Int32
) -> Int32

@_silgen_name("lame_encode_buffer_interleaved_ieee_float")
func _lame_encode_buffer_interleaved_ieee_float(
    _: OpaquePointer?,
    _: UnsafePointer<Float>?,
    _: Int32,
    _: UnsafeMutablePointer<UInt8>?,
    _: Int32
) -> Int32

@_silgen_name("lame_encode_flush")
func _lame_encode_flush(
    _: OpaquePointer?,
    _: UnsafeMutablePointer<UInt8>?,
    _: Int32
) -> Int32

@_silgen_name("lame_encode_flush_nogap")
func _lame_encode_flush_nogap(
    _: OpaquePointer?,
    _: UnsafeMutablePointer<UInt8>?,
    _: Int32
) -> Int32

/// Streaming-capable LAME wrapper.
///
/// Not thread-safe: callers must serialize access (live sessions encode on a
/// dedicated serial queue). `append`/`finish` are the streaming API; the legacy
/// batch `encode(samples:to:)` is retained for dictation and is implemented on
/// top of the streaming path.
final class MP3Encoder {
    private let lame: OpaquePointer
    let sampleRate: Int
    let channels: Int
    private var finished = false

    init?(sampleRate: Int, channels: Int = 1, bitrate: Int = 256, quality: Int = 2) {
        guard let l = _lame_init() else { return nil }
        self.lame = l
        self.sampleRate = sampleRate
        self.channels = channels
        _lame_set_in_samplerate(l, Int32(sampleRate))
        _lame_set_out_samplerate(l, Int32(sampleRate))
        _lame_set_num_channels(l, Int32(channels))
        _lame_set_brate(l, Int32(bitrate))
        _lame_set_quality(l, Int32(quality))
        guard _lame_init_params(l) >= 0 else {
            _lame_close(l)
            return nil
        }
    }

    deinit {
        _lame_close(lame)
    }

    /// Append interleaved PCM (scaled +/- 1.0 full scale). Returns encoded MP3
    /// bytes produced so far from this input (may be empty until frame boundaries fill).
    func append(interleavedSamples samples: [Float]) -> Data {
        guard !finished, !samples.isEmpty else { return Data() }
        let frames = channels > 1 ? samples.count / channels : samples.count
        let outputCapacity = Int32(frames * 2 + 7200)
        var outputBuffer = [UInt8](repeating: 0, count: Int(outputCapacity))
        var written = 0
        samples.withUnsafeBufferPointer { src in
            guard let base = src.baseAddress else { return }
            if channels > 1 {
                written = Int(_lame_encode_buffer_interleaved_ieee_float(
                    lame,
                    base,
                    Int32(frames),
                    &outputBuffer,
                    outputCapacity
                ))
            } else {
                written = Int(_lame_encode_buffer_ieee_float(
                    lame,
                    base,
                    nil,
                    Int32(frames),
                    &outputBuffer,
                    outputCapacity
                ))
            }
        }
        guard written > 0 else { return Data() }
        return Data(outputBuffer[0..<min(written, Int(outputCapacity))])
    }

    /// Flush pending encoder frames mid-stream (no gap/info header). Stream stays valid.
    func flushGap() -> Data {
        guard !finished else { return Data() }
        var outputBuffer = [UInt8](repeating: 0, count: 7200)
        let written = _lame_encode_flush_nogap(lame, &outputBuffer, 7200)
        guard written > 0 else { return Data() }
        return Data(outputBuffer[0..<Int(written)])
    }

    /// Flush the encoder tail. After this, the encoder must not be used again.
    func finish() -> Data {
        guard !finished else { return Data() }
        finished = true
        var outputBuffer = [UInt8](repeating: 0, count: 7200)
        let written = _lame_encode_flush(lame, &outputBuffer, 7200)
        guard written > 0 else { return Data() }
        return Data(outputBuffer[0..<Int(written)])
    }

    /// Legacy one-shot API kept for the dictation path.
    func encode(samples: [Float], to url: URL) -> Bool {
        var allData = Data()
        let chunkSize = 8192
        var offset = 0
        while offset < samples.count {
            let slice = Array(samples[offset..<min(offset + chunkSize, samples.count)])
            allData.append(append(interleavedSamples: slice))
            offset += chunkSize
        }
        allData.append(finish())
        guard !allData.isEmpty else { return false }
        do {
            try allData.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
