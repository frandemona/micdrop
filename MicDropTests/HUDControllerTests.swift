import Testing
@testable import MicDrop

@Suite struct HUDControllerTests {
    let headset = AudioDevice(id: 7, uid: "uid-Headset", name: "USBC Headset")

    @Test func describesAllDevices() {
        #expect(HUDController.targetDescription(for: .allDevices, devices: []) == String(localized: "All Devices"))
    }

    @Test func describesDefaultDevice() {
        #expect(HUDController.targetDescription(for: .defaultDevice, devices: [headset]) == String(localized: "Default Device"))
    }

    @Test func describesSpecificDeviceByName() {
        #expect(HUDController.targetDescription(for: .specific(uid: headset.uid), devices: [headset]) == "USBC Headset")
    }

    @Test func missingSpecificDeviceReadsAsDefault() {
        #expect(HUDController.targetDescription(for: .specific(uid: "gone"), devices: [headset]) == String(localized: "Default Device"))
    }
}
