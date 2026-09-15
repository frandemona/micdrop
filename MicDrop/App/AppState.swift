import Observation

/// Composes the app's model objects and keeps settings and controllers in sync.
@Observable
final class AppState {
    let settings: SettingsStore
    let mic: MicController
    let hotkeys: HotkeyController
    let hud = HUDController()

    init(settings: SettingsStore = SettingsStore(), hardware: AudioHardware = CoreAudioHardware()) {
        self.settings = settings
        mic = MicController(hardware: hardware, target: settings.deviceTarget)
        hotkeys = HotkeyController(handler: HotkeyModeHandler(mic: mic, mode: settings.mode))
        mic.onTargetFallback = { [settings] target in settings.deviceTarget = target }
        mic.onMuteStateChanged = { [weak self] isMuted in self?.muteStateDidChange(isMuted) }
    }

    private func muteStateDidChange(_ isMuted: Bool) {
        guard settings.showHUD else { return }
        hud.show(
            isMuted: isMuted,
            targetDescription: HUDController.targetDescription(for: mic.target, devices: mic.availableDevices)
        )
    }

    var deviceTarget: DeviceTarget {
        get { mic.target }
        set {
            mic.setTarget(newValue)
            settings.deviceTarget = newValue
        }
    }

    var mode: MicMode {
        get { settings.mode }
        set {
            settings.mode = newValue
            hotkeys.handler.setMode(newValue)
        }
    }
}
