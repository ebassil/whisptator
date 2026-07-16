@preconcurrency import AVFoundation

public protocol MicrophoneCaptureDelegate: AnyObject {
    func microphoneCapture(_ capture: MicrophoneCapture, didCaptureAudio buffer: AVAudioPCMBuffer)
    func microphoneCaptureDidStart(_ capture: MicrophoneCapture)
    func microphoneCaptureDidStop(_ capture: MicrophoneCapture)
    func microphoneCapture(_ capture: MicrophoneCapture, didFailWithError error: Error)
}

public final class MicrophoneCapture: NSObject, @unchecked Sendable {
    private var captureSession: AVCaptureSession?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var sessionQueue = DispatchQueue(label: "com.whisptator.microphone")
    private var isCapturing = false

    public weak var delegate: MicrophoneCaptureDelegate?

    public let sampleRate: Double = 48000
    public let channels: AVAudioChannelCount = 1

    public override init() {
        super.init()
    }

    public func startCapture(deviceID: String? = nil) {
        sessionQueue.async { [weak self] in
            self?.performStartCapture(deviceID: deviceID)
        }
    }

    public func stopCapture(completion: (@Sendable () -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            self?.performStopCapture()
            if let completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    public var isRecording: Bool { isCapturing }

    private func performStartCapture(deviceID: String?) {
        guard !isCapturing else { return }

        let session = AVCaptureSession()
        session.sessionPreset = .medium

        let device: AVCaptureDevice?
        if let deviceID {
            device = AVCaptureDevice(uniqueID: deviceID)
        } else {
            device = AVCaptureDevice.default(for: .audio)
        }

        guard let device else {
            AppLogger.shared.log(category: .audio, message: "Microphone error: device not found")
            delegate?.microphoneCapture(self, didFailWithError: MicrophoneError.deviceNotFound)
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                AppLogger.shared.log(category: .audio, message: "Microphone error: cannot add input")
                delegate?.microphoneCapture(self, didFailWithError: MicrophoneError.cannotAddInput)
                return
            }

            let output = AVCaptureAudioDataOutput()
            output.audioSettings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 48000
            ]
            output.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                AppLogger.shared.log(category: .audio, message: "Microphone error: cannot add output")
                delegate?.microphoneCapture(self, didFailWithError: MicrophoneError.cannotAddOutput)
                return
            }

            audioOutput = output
            captureSession = session
            session.startRunning()
            guard captureSession?.isRunning == true else {
                AppLogger.shared.log(category: .audio, message: "Microphone error: session failed to start")
                delegate?.microphoneCapture(self, didFailWithError: MicrophoneError.sessionFailedToStart)
                return
            }
            isCapturing = true
            AppLogger.shared.log(category: .audio, message: "Microphone capture started (device: \(device.localizedName))")
            delegate?.microphoneCaptureDidStart(self)
        } catch {
            delegate?.microphoneCapture(self, didFailWithError: error)
        }
    }

    private func performStopCapture() {
        guard isCapturing else { return }
        captureSession?.stopRunning()
        captureSession = nil
        audioOutput = nil
        isCapturing = false
        AppLogger.shared.log(category: .audio, message: "Microphone capture stopped")
        delegate?.microphoneCaptureDidStop(self)
    }

    public static func convertTo16kHzMono(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let inputFormat = buffer.format
        let targetSampleRate: Double = 16000
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )

        guard let targetFormat else { return nil }

        if inputFormat.sampleRate == targetSampleRate && inputFormat.channelCount == 1 {
            return buffer
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            return nil
        }

        let ratio = targetSampleRate / inputFormat.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
            return nil
        }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error else { return nil }
        return outputBuffer
    }
}

extension MicrophoneCapture: AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frameCount > 0 else { return }

        let avFormat: AVAudioFormat
        if let asbd, asbd.mFormatFlags & kAudioFormatFlagIsFloat != 0 {
            guard let fmt = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: asbd.mSampleRate,
                channels: AVAudioChannelCount(asbd.mChannelsPerFrame),
                interleaved: false
            ) else { return }
            avFormat = fmt
        } else {
            guard let fmt = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48000,
                channels: 1,
                interleaved: false
            ) else { return }
            avFormat = fmt
        }

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: avFormat, frameCapacity: frameCount) else { return }
        pcmBuffer.frameLength = frameCount

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var dataLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &dataLength, dataPointerOut: &dataPointer)
        guard let srcPointer = dataPointer, let dstPointer = pcmBuffer.floatChannelData?[0] else { return }

        let expectedBytes = Int(frameCount) * MemoryLayout<Float>.size
        let bytesToCopy = min(dataLength, expectedBytes)
        memcpy(dstPointer, srcPointer, bytesToCopy)

        if bytesToCopy < expectedBytes {
            memset(dstPointer + bytesToCopy, 0, expectedBytes - bytesToCopy)
        }

        delegate?.microphoneCapture(self, didCaptureAudio: pcmBuffer)
    }
}

public enum MicrophoneError: Error, LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case sessionFailedToStart

    public var errorDescription: String? {
        switch self {
        case .deviceNotFound: return "Audio input device not found."
        case .cannotAddInput: return "Cannot add audio input to capture session."
        case .cannotAddOutput: return "Cannot add audio output to capture session."
        case .sessionFailedToStart: return "Audio capture session failed to start."
        }
    }
}
