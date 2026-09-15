import Foundation
import Observation

/// Composes the app's model objects and keeps settings and controllers in sync.
@Observable
final class AppState {
    let settings: SettingsStore
    let mic: MicController
    let hotkeys: HotkeyController
    let hud = HUDController()
    let launchAtLogin = LaunchAtLogin()
    #if APPSTORE
    let tipJar = StoreKitTipJar()
    #else
    /// Set by AppDelegate so tests never start Sparkle.
    var updater: Updater?
    #endif

    init(
        settings: SettingsStore = SettingsStore(),
        hardware: AudioHardware = CoreAudioHardware(),
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        let mic = MicController(hardware: hardware, target: settings.deviceTarget, defaults: defaults)
        mic.onTargetFallback = { [settings] target in settings.deviceTarget = target }
        // A saved specific device that isn't connected at launch falls back to the default device
        // (and is persisted) before the hotkey handler applies Push-to-talk's initial mute.
        mic.handleDevicesChanged()
        self.mic = mic
        hotkeys = HotkeyController(handler: HotkeyModeHandler(mic: mic, mode: settings.mode))
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
