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

@_silgen_name("lame_encode_flush")
func _lame_encode_flush(
    _: OpaquePointer?,
    _: UnsafeMutablePointer<UInt8>?,
    _: Int32
) -> Int32

final class MP3Encoder {
    private let lame: OpaquePointer

    init?(sampleRate: Int, channels: Int = 1, bitrate: Int = 256, quality: Int = 2) {
        guard let l = _lame_init() else { return nil }
        self.lame = l
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

    func encode(samples: [Float], to url: URL) -> Bool {
        let mp3BufferSize = Int32(samples.count * 2 + 7200)
        var mp3Buffer = [UInt8](repeating: 0, count: Int(mp3BufferSize))
        var allData = Data()
        let chunkSize = 8192
        var offset = 0

        while offset < samples.count {
            let remaining = samples.count - offset
            let frameLen = min(chunkSize, remaining)
            let written = samples.withUnsafeBufferPointer { srcBuf in
                let src = UnsafeMutablePointer(mutating: srcBuf.baseAddress!)
                return _lame_encode_buffer_ieee_float(
                    lame,
                    src.advanced(by: offset),
                    nil,
                    Int32(frameLen),
                    &mp3Buffer,
                    mp3BufferSize
                )
            }
            if written > 0 {
                allData.append(&mp3Buffer, count: Int(written))
            }
            offset += frameLen
        }

        let flushWritten = _lame_encode_flush(lame, &mp3Buffer, mp3BufferSize)
        if flushWritten > 0 {
            allData.append(&mp3Buffer, count: Int(flushWritten))
        }

        guard !allData.isEmpty else { return false }
        do {
            try allData.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
