import AppKit
import Observation
import SwiftUI

/// Owns the menu bar icon and the popover.
final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let appState: AppState

    init(appState: AppState, openPreferences: @escaping () -> Void) {
        self.appState = appState
        super.init()

        let content = PopoverView(appState: appState) { [weak self] in
            self?.popover.performClose(nil)
            openPreferences()
        }
        let hosting = NSHostingController(rootView: content)
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting
        popover.behavior = .transient

        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        updateIcon()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateIcon() {
        let muted = withObservationTracking {
            appState.mic.isMuted
        } onChange: { [weak self] in
            Task { @MainActor in self?.updateIcon() }
        }
        let image = NSImage(
            systemSymbolName: muted ? "mic.slash.fill" : "mic.fill",
            accessibilityDescription: muted ? String(localized: "Microphone OFF") : String(localized: "Microphone ON")
        )
        image?.isTemplate = true
        statusItem.button?.image = image
    }
}
