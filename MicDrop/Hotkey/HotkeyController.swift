import KeyboardShortcuts

protocol MicToggling: AnyObject {
    var isMuted: Bool { get }
    func setMuted(_ muted: Bool)
    func toggle()
}

extension MicController: MicToggling {}

/// Turns hotkey presses into mic actions for the current mode.
final class HotkeyModeHandler {
    private let mic: MicToggling
    private(set) var mode: MicMode

    init(mic: MicToggling, mode: MicMode) {
        self.mic = mic
        self.mode = mode
        if mode == .pushToTalk { mic.setMuted(true) }
    }

    func setMode(_ newMode: MicMode) {
        guard newMode != mode else { return }
        mode = newMode
        if newMode == .pushToTalk { mic.setMuted(true) }
    }

    func keyDown() {
        switch mode {
        case .toggle: mic.toggle()
        case .pushToTalk: mic.setMuted(false)
        }
    }

    func keyUp() {
        if mode == .pushToTalk { mic.setMuted(true) }
    }
}

extension KeyboardShortcuts.Name {
    static let toggleMic = Self("toggleMic")
}

/// Connects the global shortcut to the mode handler. Uses Carbon hotkeys: no Accessibility permission needed.
final class HotkeyController {
    let handler: HotkeyModeHandler

    init(handler: HotkeyModeHandler) {
        self.handler = handler
        KeyboardShortcuts.onKeyDown(for: .toggleMic) { [weak self] in self?.handler.keyDown() }
        KeyboardShortcuts.onKeyUp(for: .toggleMic) { [weak self] in self?.handler.keyUp() }
    }
}
