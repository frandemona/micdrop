import Testing
@testable import MicDrop

@Suite struct MicControllerTests {
    let hardware = FakeAudioHardware()

    @Test func mutesWithMuteProperty() {
        let mic = hardware.add("MacBook")
        let controller = MicController(hardware: hardware, target: .defaultDevice)

        controller.setMuted(true)
        #expect(controller.isMuted)
        #expect(hardware.state(mic)?.muted == true)
        #expect(hardware.state(mic)?.volume == 0.8)

        controller.setMuted(false)
        #expect(!controller.isMuted)
        #expect(hardware.state(mic)?.muted == false)
    }

    @Test func fallsBackToVolumeAndRestoresIt() {
        let headset = hardware.add("Headset", mute: false)
        hardware.setUserVolume(0.6, for: headset)
        let controller = MicController(hardware: hardware, target: .defaultDevice)

        controller.setMuted(true)
        #expect(controller.isMuted)
        #expect(hardware.state(headset)?.volume == 0)

        controller.setMuted(false)
        #expect(hardware.state(headset)?.volume == 0.6)
    }

    @Test func restoresFullVolumeWhenPreviousVolumeWasZero() {
        let headset = hardware.add("Headset", mute: false)
        hardware.setUserVolume(0, for: headset)
        let controller = MicController(hardware: hardware, target: .defaultDevice)

        controller.setMuted(true)
        controller.setMuted(false)
        #expect(hardware.state(headset)?.volume == 1)
    }

    @Test func toggleFlipsState() {
        hardware.add("MacBook")
        let controller = MicController(hardware: hardware, target: .defaultDevice)
        controller.toggle()
        #expect(controller.isMuted)
        controller.toggle()
        #expect(!controller.isMuted)
    }

    @Test func reportsUnsupportedDevicesButStaysMutedIfAnotherSucceeded() {
        hardware.add("MacBook")
        let odd = hardware.add("Odd", mute: false, volume: false)
        let controller = MicController(hardware: hardware, target: .allDevices)

        controller.setMuted(true)
        #expect(controller.isMuted)
        #expect(controller.unsupportedDevices == [odd])

        controller.setMuted(false)
        #expect(controller.unsupportedDevices.isEmpty)
    }

    @Test func staysUnmutedWhenEveryWriteFails() {
        let broken = hardware.add("Broken", failsWrites: true)
        let controller = MicController(hardware: hardware, target: .defaultDevice)

        controller.setMuted(true)
        #expect(!controller.isMuted)
        #expect(controller.unsupportedDevices == [broken])
    }

    @Test func allDevicesTargetMutesEveryDevice() {
        let mac = hardware.add("MacBook")
        let headset = hardware.add("Headset", mute: false)
        let controller = MicController(hardware: hardware, target: .allDevices)

        controller.setMuted(true)
        #expect(hardware.state(mac)?.muted == true)
        #expect(hardware.state(headset)?.volume == 0)
    }

    @Test func specificTargetOnlyMutesThatDevice() {
        let mac = hardware.add("MacBook")
        let headset = hardware.add("Headset")
        let controller = MicController(hardware: hardware, target: .specific(uid: headset.uid))

        controller.setMuted(true)
        #expect(hardware.state(mac)?.muted == false)
        #expect(hardware.state(headset)?.muted == true)
    }

    @Test func changingTargetWhileMutedMovesTheMute() {
        let mac = hardware.add("MacBook")
        let headset = hardware.add("Headset")
        let controller = MicController(hardware: hardware, target: .defaultDevice)
        controller.setMuted(true)

        controller.setTarget(.specific(uid: headset.uid))
        #expect(controller.target == .specific(uid: headset.uid))
        #expect(hardware.state(mac)?.muted == false)
        #expect(hardware.state(headset)?.muted == true)
        #expect(controller.isMuted)
    }

    @Test func mutesDevicesPluggedInWhileMuted() {
        hardware.add("MacBook")
        let controller = MicController(hardware: hardware, target: .allDevices)
        controller.setMuted(true)

        let headset = hardware.add("Headset", mute: false)
        hardware.simulateDevicesChanged()
        #expect(hardware.state(headset)?.volume == 0)
        #expect(controller.availableDevices.map(\.name) == ["MacBook", "Headset"])
    }

    @Test func followsDefaultDeviceChanges() {
        let mac = hardware.add("MacBook")
        let controller = MicController(hardware: hardware, target: .defaultDevice)
        controller.setMuted(true)

        let headset = hardware.add("Headset", mute: false)
        hardware.defaultUID = headset.uid
        hardware.simulateDevicesChanged()
        #expect(hardware.state(mac)?.muted == false)
        #expect(hardware.state(headset)?.volume == 0)
    }

    @Test func fallsBackToDefaultWhenSpecificDeviceDisappears() {
        let mac = hardware.add("MacBook")
        let headset = hardware.add("Headset")
        let controller = MicController(hardware: hardware, target: .specific(uid: headset.uid))
        var fallback: DeviceTarget?
        controller.onTargetFallback = { fallback = $0 }
        controller.setMuted(true)

        hardware.remove(headset)
        hardware.simulateDevicesChanged()
        #expect(controller.target == .defaultDevice)
        #expect(fallback == .defaultDevice)
        #expect(hardware.state(mac)?.muted == true)
    }

    @Test func remutesWhenDevicesReturnAfterUnplug() {
        let headset = hardware.add("Headset", mute: false)
        let controller = MicController(hardware: hardware, target: .defaultDevice)
        controller.setMuted(true)

        hardware.remove(headset)
        hardware.simulateDevicesChanged()
        #expect(!controller.isMuted)

        let returned = hardware.add("Headset", mute: false)
        hardware.simulateDevicesChanged()
        #expect(controller.isMuted)
        #expect(hardware.state(returned)?.volume == 0)
    }

    @Test func restoreAllUndoesEverything() {
        let mac = hardware.add("MacBook")
        let headset = hardware.add("Headset", mute: false)
        let controller = MicController(hardware: hardware, target: .allDevices)
        controller.setMuted(true)

        controller.restoreAll()
        #expect(!controller.isMuted)
        #expect(hardware.state(mac)?.muted == false)
        #expect(hardware.state(headset)?.volume == 0.8)
    }

    @Test func notifiesOnlyWhenMuteStateChanges() {
        hardware.add("MacBook")
        let controller = MicController(hardware: hardware, target: .defaultDevice)
        var events: [Bool] = []
        controller.onMuteStateChanged = { events.append($0) }

        controller.setMuted(true)
        controller.setMuted(true)
        controller.setMuted(false)
        #expect(events == [true, false])
    }

    @Test func listsAvailableDevicesAtInit() {
        hardware.add("MacBook")
        hardware.add("Headset")
        let controller = MicController(hardware: hardware, target: .defaultDevice)
        #expect(controller.availableDevices.map(\.name) == ["MacBook", "Headset"])
    }

    @Test func retriesRestoreThatFailed() {
        let mic = hardware.add("MacBook")
        let controller = MicController(hardware: hardware, target: .defaultDevice)

        controller.setMuted(true)
        #expect(hardware.state(mic)?.muted == true)

        hardware.setFailsWrites(true, for: mic)
        controller.setMuted(false)
        #expect(hardware.state(mic)?.muted == true)

        hardware.setFailsWrites(false, for: mic)
        controller.setMuted(false)
        #expect(hardware.state(mic)?.muted == false)
    }
}
