import CoreAudio
import Foundation

struct CoreAudioError: Error {
    let status: OSStatus
}

final class CoreAudioHardware: AudioHardware {
    private var devicesChangedHandler: (() -> Void)?
    private var listenersInstalled = false

    // MARK: Devices

    func inputDevices() -> [AudioDevice] {
        var address = Self.address(kAudioHardwarePropertyDevices, scope: kAudioObjectPropertyScopeGlobal)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.filter { inputChannelCount($0) > 0 }.compactMap(makeDevice)
    }

    func defaultInputDevice() -> AudioDevice? {
        var address = Self.address(kAudioHardwarePropertyDefaultInputDevice, scope: kAudioObjectPropertyScopeGlobal)
        var id = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id) == noErr,
              id != 0 else { return nil }
        return makeDevice(id)
    }

    // MARK: Mute

    func canMute(_ device: AudioDevice) -> Bool {
        !settableElements(kAudioDevicePropertyMute, device.id).isEmpty
    }

    func isMuted(_ device: AudioDevice) -> Bool {
        guard let element = settableElements(kAudioDevicePropertyMute, device.id).first else { return false }
        var address = Self.address(kAudioDevicePropertyMute, scope: kAudioObjectPropertyScopeInput, element: element)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(device.id, &address, 0, nil, &size, &value) == noErr && value != 0
    }

    func setMuted(_ muted: Bool, on device: AudioDevice) throws {
        for element in settableElements(kAudioDevicePropertyMute, device.id) {
            var address = Self.address(kAudioDevicePropertyMute, scope: kAudioObjectPropertyScopeInput, element: element)
            var value: UInt32 = muted ? 1 : 0
            let status = AudioObjectSetPropertyData(device.id, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
            guard status == noErr else { throw CoreAudioError(status: status) }
        }
    }

    // MARK: Volume

    func canSetVolume(_ device: AudioDevice) -> Bool {
        !settableElements(kAudioDevicePropertyVolumeScalar, device.id).isEmpty
    }

    func volume(of device: AudioDevice) -> Float {
        guard let element = settableElements(kAudioDevicePropertyVolumeScalar, device.id).first else { return 0 }
        var address = Self.address(kAudioDevicePropertyVolumeScalar, scope: kAudioObjectPropertyScopeInput, element: element)
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        return AudioObjectGetPropertyData(device.id, &address, 0, nil, &size, &value) == noErr ? value : 0
    }

    func setVolume(_ volume: Float, on device: AudioDevice) throws {
        for element in settableElements(kAudioDevicePropertyVolumeScalar, device.id) {
            var address = Self.address(kAudioDevicePropertyVolumeScalar, scope: kAudioObjectPropertyScopeInput, element: element)
            var value = Float32(volume)
            let status = AudioObjectSetPropertyData(device.id, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
            guard status == noErr else { throw CoreAudioError(status: status) }
        }
    }

    // MARK: Change notifications

    func setDevicesChangedHandler(_ handler: @escaping () -> Void) {
        devicesChangedHandler = handler
        guard !listenersInstalled else { return }
        listenersInstalled = true
        for selector in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice] {
            var address = Self.address(selector, scope: kAudioObjectPropertyScopeGlobal)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.devicesChangedHandler?() }
            }
        }
    }

    // MARK: Helpers

    private static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }

    private func makeDevice(_ id: AudioObjectID) -> AudioDevice? {
        guard let uid = stringProperty(id, kAudioDevicePropertyDeviceUID) else { return nil }
        let name = stringProperty(id, kAudioObjectPropertyName) ?? uid
        return AudioDevice(id: id, uid: uid, name: name)
    }

    private func stringProperty(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = Self.address(selector, scope: kAudioObjectPropertyScopeGlobal)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    private func inputChannelCount(_ id: AudioObjectID) -> Int {
        var address = Self.address(kAudioDevicePropertyStreamConfiguration, scope: kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, raw) == noErr else { return 0 }
        let buffers = UnsafeMutableAudioBufferListPointer(raw.assumingMemoryBound(to: AudioBufferList.self))
        return buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    /// The main element if it is settable, otherwise every settable per-channel element.
    private func settableElements(_ selector: AudioObjectPropertySelector, _ id: AudioObjectID) -> [AudioObjectPropertyElement] {
        if isSettable(selector, id, element: kAudioObjectPropertyElementMain) {
            return [kAudioObjectPropertyElementMain]
        }
        let channels = inputChannelCount(id)
        guard channels > 0 else { return [] }
        return (1...UInt32(channels)).filter { isSettable(selector, id, element: $0) }
    }

    private func isSettable(_ selector: AudioObjectPropertySelector, _ id: AudioObjectID, element: AudioObjectPropertyElement) -> Bool {
        var address = Self.address(selector, scope: kAudioObjectPropertyScopeInput, element: element)
        guard AudioObjectHasProperty(id, &address) else { return false }
        var settable: DarwinBoolean = false
        return AudioObjectIsPropertySettable(id, &address, &settable) == noErr && settable.boolValue
    }
}
