import Testing
@testable import MicDrop

final class FakeMic: MicToggling {
    private(set) var isMuted = false
    func setMuted(_ muted: Bool) { isMuted = muted }
    func toggle() { isMuted.toggle() }
}

@Suite struct HotkeyModeHandlerTests {
    let mic = FakeMic()

    @Test func toggleModeFlipsOnKeyDownAndIgnoresKeyUp() {
        let handler = HotkeyModeHandler(mic: mic, mode: .toggle)
        #expect(!mic.isMuted)
        handler.keyDown()
        #expect(mic.isMuted)
        handler.keyUp()
        #expect(mic.isMuted)
        handler.keyDown()
        #expect(!mic.isMuted)
    }

    @Test func pushToTalkStartsMutedAndIsLiveOnlyWhileHeld() {
        let handler = HotkeyModeHandler(mic: mic, mode: .pushToTalk)
        #expect(mic.isMuted)
        handler.keyDown()
        #expect(!mic.isMuted)
        handler.keyUp()
        #expect(mic.isMuted)
    }

    @Test func switchingToPushToTalkMutes() {
        let handler = HotkeyModeHandler(mic: mic, mode: .toggle)
        handler.setMode(.pushToTalk)
        #expect(handler.mode == .pushToTalk)
        #expect(mic.isMuted)
    }

    @Test func switchingBackToToggleKeepsState() {
        let handler = HotkeyModeHandler(mic: mic, mode: .pushToTalk)
        handler.setMode(.toggle)
        #expect(mic.isMuted)
    }
}
