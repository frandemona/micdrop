import Foundation
import Testing
@testable import MicDrop

@Suite struct SettingsStoreTests {
    let defaults = UserDefaults(suiteName: "SettingsStoreTests-\(UUID().uuidString)")!

    @Test func hasSpecDefaults() {
        let store = SettingsStore(defaults: defaults)
        #expect(store.deviceTarget == .defaultDevice)
        #expect(store.mode == .toggle)
        #expect(store.showHUD)
        #expect(!store.settingsExpanded)
    }

    @Test func persistsAcrossInstances() {
        let store = SettingsStore(defaults: defaults)
        store.deviceTarget = .specific(uid: "uid-Headset")
        store.mode = .pushToTalk
        store.showHUD = false
        store.settingsExpanded = true

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.deviceTarget == .specific(uid: "uid-Headset"))
        #expect(reloaded.mode == .pushToTalk)
        #expect(!reloaded.showHUD)
        #expect(reloaded.settingsExpanded)
    }
}
