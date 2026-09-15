import AppKit
import SwiftUI

final class PreferencesWindowController {
    private let appState: AppState
    private var window: NSWindow?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: PreferencesView(appState: appState))
            hosting.sizingOptions = .preferredContentSize
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.title = String(localized: "MicDrop Preferences")
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        appState.launchAtLogin.refresh()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
