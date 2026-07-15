import ScreenCaptureKit
import AVFoundation

public protocol SystemAudioCaptureDelegate: AnyObject {
    func systemAudioCapture(_ capture: SystemAudioCapture, didCaptureAudio buffer: AVAudioPCMBuffer)
    func systemAudioCaptureDidStart(_ capture: SystemAudioCapture)
    func systemAudioCaptureDidStop(_ capture: SystemAudioCapture)
    func systemAudioCapture(_ capture: SystemAudioCapture, didFailWithError error: Error)
}

public final class SystemAudioCapture: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var isCapturing = false

    public weak var delegate: SystemAudioCaptureDelegate?

    public override init() {
        super.init()
    }

    public func startCapture() async throws {
        guard !isCapturing else { return }

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let display = content.displays.first else {
            throw SystemAudioError.noDisplayAvailable
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = 48000
        config.channelCount = 1

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "com.whisptator.systemaudio"))
        try await stream.startCapture()

        self.stream = stream
        isCapturing = true
        delegate?.systemAudioCaptureDidStart(self)
    }

    public func stopCapture() async {
        guard isCapturing else { return }
        try? await stream?.stopCapture()
        stream = nil
        isCapturing = false
        delegate?.systemAudioCaptureDidStop(self)
    }
}

extension SystemAudioCapture: SCStreamOutput {
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }

        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        let audioFormat = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee

        guard let avFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: audioFormat?.mSampleRate ?? 48000,
            channels: AVAudioChannelCount(audioFormat?.mChannelsPerFrame ?? 1),
            interleaved: false
        ) else { return }

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: avFormat, frameCapacity: frameCount) else { return }
        pcmBuffer.frameLength = frameCount

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var dataLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &dataLength, dataPointerOut: &dataPointer)

        if let srcPointer = dataPointer, let dstPointer = pcmBuffer.floatChannelData?[0] {
            let byteCount = min(dataLength, Int(frameCount) * MemoryLayout<Float>.size)
            memcpy(dstPointer, srcPointer, byteCount)
        }

        delegate?.systemAudioCapture(self, didCaptureAudio: pcmBuffer)
    }
}

public enum SystemAudioError: Error, LocalizedError {
    case noDisplayAvailable

    public var errorDescription: String? {
        switch self {
        case .noDisplayAvailable: return "No display available for system audio capture."
        }
    }
}
