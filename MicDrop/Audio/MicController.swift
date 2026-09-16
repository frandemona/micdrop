import Foundation
import Observation

/// Mutes the input devices selected by `target` and undoes exactly what it changed.
@Observable
final class MicController {
    nonisolated private enum Change: Codable, Sendable {
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

    private static let recordsKey = "micChangeRecords"

    @ObservationIgnored private let hardware: AudioHardware
    @ObservationIgnored private let defaults: UserDefaults
    /// What MicDrop changed, keyed by device UID. Persisted on every mutation so a crash or
    /// force-quit doesn't leave mics muted: the next launch restores them.
    @ObservationIgnored private var changes: [String: Change] = [:] {
        didSet { persistChanges() }
    }
    @ObservationIgnored private var wantsMuted = false
    /// Re-checks queued after a device-list change, for devices that need a moment to settle.
    @ObservationIgnored private var settleTask: Task<Void, Never>?

    init(hardware: AudioHardware, target: DeviceTarget, defaults: UserDefaults = .standard) {
        self.hardware = hardware
        self.target = target
        self.defaults = defaults
        let present = hardware.inputDevices()
        availableDevices = present
        hardware.setDevicesChangedHandler { [weak self] in self?.handleDevicesChanged() }

        // Records left by a previous run that didn't restore (crash, force-quit): undo them now.
        // wantsMuted is false, so present devices are restored and absent ones stay recorded.
        // isMuted stays false throughout, so onMuteStateChanged never fires here.
        if let data = defaults.data(forKey: Self.recordsKey),
           let persisted = try? JSONDecoder().decode([String: Change].self, from: data),
           !persisted.isEmpty {
            changes = persisted
            reconcile()
        }
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
        scheduleSettleChecks()
    }

    /// A device that has just appeared can accept a write and then discard it while it finishes
    /// initialising, and the device list doesn't change again — so re-check for a few seconds.
    private func scheduleSettleChecks() {
        settleTask?.cancel()
        guard wantsMuted else { return }
        settleTask = Task { [weak self] in
            for delay in [0.5, 1.5, 3.0] {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, let self, self.wantsMuted else { return }
                self.reconcile()
            }
        }
    }

    private func reconcile() {
        let wasMuted = isMuted
        let present = hardware.inputDevices()
        availableDevices = present
        // Records for absent devices are kept: macOS remembers a device's mute/volume by UID,
        // so a device unplugged while muted comes back muted and must still be restorable.
        let presentUIDs = Set(present.map(\.uid))

        let desired = wantsMuted ? devices(for: target, in: present) : []
        let desiredUIDs = Set(desired.map(\.uid))
        for device in present where changes[device.uid] != nil && !desiredUIDs.contains(device.uid) {
            restore(device)
        }

        var unsupported: [AudioDevice] = []
        for device in desired {
            if let change = changes[device.uid] {
                // Devices lie: a mic still initialising reports a successful write and drops it, and
                // macOS restores a replugged device's own remembered state. Enforce what MicDrop
                // recorded rather than trusting it, keeping the original record and saved volume.
                if !isApplied(change, on: device), !reapply(device) {
                    unsupported.append(device)
                }
            } else if !mute(device) {
                unsupported.append(device)
            }
        }
        unsupportedDevices = unsupported
        isMuted = wantsMuted && changes.keys.contains { presentUIDs.contains($0) }

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

    private func persistChanges() {
        if changes.isEmpty {
            defaults.removeObject(forKey: Self.recordsKey)
        } else if let data = try? JSONEncoder().encode(changes) {
            defaults.set(data, forKey: Self.recordsKey)
        }
    }

    /// Whether the hardware still reflects the change MicDrop recorded for this device.
    private func isApplied(_ change: Change, on device: AudioDevice) -> Bool {
        switch change {
        case .muteFlag: hardware.isMuted(device)
        case .volume: hardware.volume(of: device) == 0
        }
    }

    /// Re-applies the recorded mute to a device that came back, keeping the original record
    /// (and so the volume saved before MicDrop first muted it). Returns false when the write fails.
    private func reapply(_ device: AudioDevice) -> Bool {
        guard let change = changes[device.uid] else { return false }
        do {
            switch change {
            case .muteFlag:
                try hardware.setMuted(true, on: device)
            case .volume:
                try hardware.setVolume(0, on: device)
            }
            return true
        } catch {
            return false
        }
    }

    private func restore(_ device: AudioDevice) {
        guard let change = changes[device.uid] else { return }
        do {
            switch change {
            case .muteFlag:
                try hardware.setMuted(false, on: device)
            case .volume(let previous):
                try hardware.setVolume(previous > 0 ? previous : 1, on: device)
            }
            changes.removeValue(forKey: device.uid)
        } catch {
            // Keep the change record so the next reconcile() retries
        }
    }
}
