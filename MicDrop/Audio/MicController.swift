import Observation

/// Mutes the input devices selected by `target` and undoes exactly what it changed.
@Observable
final class MicController {
    private enum Change {
        case muteFlag
        case volume(previous: Float)
    }

    private(set) var isMuted = false
    private(set) var unsupportedDevices: [AudioDevice] = []
    private(set) var availableDevices: [AudioDevice] = []
    private(set) var target: DeviceTarget

    /// Called when a specific device disappears and the target falls back to the default device.
    @ObservationIgnored var onTargetFallback: ((DeviceTarget) -> Void)?
    /// Called only when `isMuted` actually changes.
    @ObservationIgnored var onMuteStateChanged: ((Bool) -> Void)?

    @ObservationIgnored private let hardware: AudioHardware
    @ObservationIgnored private var changes: [String: Change] = [:]
    @ObservationIgnored private var wantsMuted = false

    init(hardware: AudioHardware, target: DeviceTarget) {
        self.hardware = hardware
        self.target = target
        availableDevices = hardware.inputDevices()
        hardware.setDevicesChangedHandler { [weak self] in self?.handleDevicesChanged() }
    }

    func toggle() {
        setMuted(!isMuted)
    }

    func setMuted(_ muted: Bool) {
        wantsMuted = muted
        reconcile()
    }

    func setTarget(_ newTarget: DeviceTarget) {
        guard newTarget != target else { return }
        target = newTarget
        reconcile()
    }

    func restoreAll() {
        setMuted(false)
    }

    func handleDevicesChanged() {
        if case .specific(let uid) = target, !hardware.inputDevices().contains(where: { $0.uid == uid }) {
            target = .defaultDevice
            onTargetFallback?(.defaultDevice)
        }
        reconcile()
    }

    private func reconcile() {
        let wasMuted = isMuted
        let present = hardware.inputDevices()
        availableDevices = present
        let presentUIDs = Set(present.map(\.uid))
        changes = changes.filter { presentUIDs.contains($0.key) }

        let desired = wantsMuted ? devices(for: target, in: present) : []
        let desiredUIDs = Set(desired.map(\.uid))
        for device in present where changes[device.uid] != nil && !desiredUIDs.contains(device.uid) {
            restore(device)
        }

        var unsupported: [AudioDevice] = []
        for device in desired where changes[device.uid] == nil {
            if !mute(device) { unsupported.append(device) }
        }
        unsupportedDevices = unsupported
        isMuted = wantsMuted && !changes.isEmpty

        if isMuted != wasMuted { onMuteStateChanged?(isMuted) }
    }

    private func devices(for target: DeviceTarget, in present: [AudioDevice]) -> [AudioDevice] {
        switch target {
        case .defaultDevice: hardware.defaultInputDevice().map { [$0] } ?? []
        case .allDevices: present
        case .specific(let uid): present.filter { $0.uid == uid }
        }
    }

    /// Returns false when the device can't be muted.
    private func mute(_ device: AudioDevice) -> Bool {
        do {
            if hardware.canMute(device) {
                try hardware.setMuted(true, on: device)
                changes[device.uid] = .muteFlag
            } else if hardware.canSetVolume(device) {
                let previous = hardware.volume(of: device)
                try hardware.setVolume(0, on: device)
                changes[device.uid] = .volume(previous: previous)
            } else {
                return false
            }
            return true
        } catch {
            return false
        }
    }

    private func restore(_ device: AudioDevice) {
        guard let change = changes.removeValue(forKey: device.uid) else { return }
        switch change {
        case .muteFlag:
            try? hardware.setMuted(false, on: device)
        case .volume(let previous):
            try? hardware.setVolume(previous > 0 ? previous : 1, on: device)
        }
    }
}
