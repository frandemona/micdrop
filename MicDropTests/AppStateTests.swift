import Foundation
import Testing
@testable import MicDrop

@Suite struct AppStateTests {
    let hardware = FakeAudioHardware()
    let defaults = UserDefaults(suiteName: "AppStateTests-\(UUID().uuidString)")!

    private func makeState() -> AppState {
        let settings = SettingsStore(defaults: defaults)
        settings.showHUD = false
        return AppState(settings: settings, hardware: hardware, defaults: defaults)
    }

    @Test func changingDeviceTargetPersistsAndRetargets() {
        let mac = hardware.add("MacBook")
        let headset = hardware.add("Headset", mute: false)
        let state = makeState()
        state.mic.setMuted(true)

        state.deviceTarget = .specific(uid: headset.uid)
        #expect(SettingsStore(defaults: defaults).deviceTarget == .specific(uid: headset.uid))
        #expect(hardware.state(mac)?.muted == false)
        #expect(hardware.state(headset)?.volume == 0)
    }

    @Test func targetFallbackIsPersisted() {
        hardware.add("MacBook")
        let headset = hardware.add("Headset")
        let state = makeState()
        state.deviceTarget = .specific(uid: headset.uid)

        hardware.remove(headset)
        hardware.simulateDevicesChanged()
        #expect(SettingsStore(defaults: defaults).deviceTarget == .defaultDevice)
    }

    @Test func missingSavedDeviceAtLaunchFallsBackToDefaultAndPushToTalkMutesIt() {
        let mac = hardware.add("MacBook")
        let saved = SettingsStore(defaults: defaults)
        saved.deviceTarget = .specific(uid: "uid-Gone")
        saved.mode = .pushToTalk

        let state = makeState()
        #expect(state.settings.deviceTarget == .defaultDevice)
        #expect(SettingsStore(defaults: defaults).deviceTarget == .defaultDevice)
        #expect(state.mic.target == .defaultDevice)
        #expect(hardware.state(mac)?.muted == true)
        #expect(state.mic.isMuted)
    }

    @Test func changingModePersistsAndAppliesPushToTalk() {
        hardware.add("MacBook")
        let state = makeState()

        state.mode = .pushToTalk
        #expect(SettingsStore(defaults: defaults).mode == .pushToTalk)
        #expect(state.mic.isMuted)
    }
}
