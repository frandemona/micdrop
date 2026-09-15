@testable import MicDrop

final class FakeAudioHardware: AudioHardware {
    struct FakeDevice {
        var device: AudioDevice
        var supportsMute: Bool
        var supportsVolume: Bool
        var failsWrites: Bool
        var muted = false
        var volume: Float = 0.8
    }

    enum FakeError: Error { case writeFailed }

    private(set) var devices: [FakeDevice] = []
    var defaultUID: String?
    private var handler: (() -> Void)?
    private var nextID: UInt32 = 100

    @discardableResult
    func add(_ name: String, mute: Bool = true, volume: Bool = true, failsWrites: Bool = false) -> AudioDevice {
        nextID += 1
        let device = AudioDevice(id: nextID, uid: "uid-\(name)", name: name)
        devices.append(FakeDevice(device: device, supportsMute: mute, supportsVolume: volume, failsWrites: failsWrites))
        if defaultUID == nil { defaultUID = device.uid }
        return device
    }

    func remove(_ device: AudioDevice) {
        devices.removeAll { $0.device.uid == device.uid }
        if defaultUID == device.uid { defaultUID = devices.first?.device.uid }
    }

    func state(_ device: AudioDevice) -> FakeDevice? {
        devices.first { $0.device.uid == device.uid }
    }

    func setUserVolume(_ volume: Float, for device: AudioDevice) {
        guard let index = devices.firstIndex(where: { $0.device.uid == device.uid }) else { return }
        devices[index].volume = volume
    }

    func setFailsWrites(_ fails: Bool, for device: AudioDevice) {
        guard let index = devices.firstIndex(where: { $0.device.uid == device.uid }) else { return }
        devices[index].failsWrites = fails
    }

    func simulateDevicesChanged() { handler?() }

    // MARK: AudioHardware

    func inputDevices() -> [AudioDevice] { devices.map(\.device) }
    func defaultInputDevice() -> AudioDevice? { devices.first { $0.device.uid == defaultUID }?.device }
    func canMute(_ device: AudioDevice) -> Bool { state(device)?.supportsMute ?? false }
    func isMuted(_ device: AudioDevice) -> Bool { state(device)?.muted ?? false }
    func setMuted(_ muted: Bool, on device: AudioDevice) throws { try mutate(device) { $0.muted = muted } }
    func canSetVolume(_ device: AudioDevice) -> Bool { state(device)?.supportsVolume ?? false }
    func volume(of device: AudioDevice) -> Float { state(device)?.volume ?? 0 }
    func setVolume(_ volume: Float, on device: AudioDevice) throws { try mutate(device) { $0.volume = volume } }
    func setDevicesChangedHandler(_ handler: @escaping () -> Void) { self.handler = handler }

    private func mutate(_ device: AudioDevice, _ change: (inout FakeDevice) -> Void) throws {
        guard let index = devices.firstIndex(where: { $0.device.uid == device.uid }),
              !devices[index].failsWrites else { throw FakeError.writeFailed }
        change(&devices[index])
    }
}
