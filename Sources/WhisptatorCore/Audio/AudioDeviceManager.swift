import AVFoundation

public struct AudioDeviceInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let isBuiltIn: Bool

    public init(id: String, name: String, isBuiltIn: Bool) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
    }
}

public final class AudioDeviceManager: @unchecked Sendable {
    public init() {}

    public func availableInputDevices() -> [AudioDeviceInfo] {
        var devices: [AudioDeviceInfo] = []

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )

        for device in discoverySession.devices {
            let info = AudioDeviceInfo(
                id: device.uniqueID,
                name: device.localizedName,
                isBuiltIn: device.deviceType == .microphone
            )
            devices.append(info)
        }

        return devices
    }

    public func device(for deviceID: String) -> AVCaptureDevice? {
        AVCaptureDevice(uniqueID: deviceID)
    }

    public func defaultInputDevice() -> AVCaptureDevice? {
        AVCaptureDevice.default(for: .audio)
    }
}
