import AppKit
import Foundation
import KeyboardShortcuts
import SwiftUI
import Testing
@testable import MicDrop

/// Generates App Store screenshots from the real UI, so they always match what ships.
///
///     TEST_RUNNER_MICDROP_SCREENSHOTS=1 xcodebuild test -project MicDrop.xcodeproj -scheme MicDrop \
///       -destination 'platform=macOS,arch=arm64' -derivedDataPath build/direct \
///       -only-testing:MicDropTests/ScreenshotGenerator
///
/// Produces 2560×1600 PNGs, the size App Store Connect expects. The test host is sandboxed, so they
/// land in its container (the run prints each path); `scripts/make-screenshots.sh` copies them to
/// build/screenshots/.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["MICDROP_SCREENSHOTS"] != nil))
struct ScreenshotGenerator {
    private static let canvas = NSSize(width: 2560, height: 1600)
    /// Inside the sandboxed test host's container; `scripts/make-screenshots.sh` copies them out.
    private static let outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("micdrop-screenshots")

    // MARK: Screenshots

    @Test func popoverMuted() throws {
        let state = makeAppState(muted: true, mode: .toggle, expanded: true)
        let ui = render(PopoverView(appState: state, openPreferences: {}))
        try write(
            compose(title: "Mute your mic from anywhere", subtitle: "One hotkey. Every app. No hunting for a button.", ui: ui),
            named: "1-popover-muted"
        )
    }

    @Test func popoverLive() throws {
        let state = makeAppState(muted: false, mode: .pushToTalk, expanded: true)
        let ui = render(PopoverView(appState: state, openPreferences: {}))
        try write(
            compose(title: "Toggle or push-to-talk", subtitle: "Tap to switch, or hold your key to talk and release to mute.", ui: ui),
            named: "2-popover-push-to-talk"
        )
    }

    @Test func hud() throws {
        let ui = render(
            HUDView(isMuted: true, targetDescription: "All Devices")
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        )
        try write(
            compose(title: "Always know if you're live", subtitle: "A glance at the menu bar, and a clear on-screen confirmation.", ui: ui),
            named: "3-hud"
        )
    }

    @Test func preferences() throws {
        let state = makeAppState(muted: false, mode: .toggle, expanded: false)
        let ui = render(PreferencesView(appState: state))
        try write(
            compose(title: "Free, and out of your way", subtitle: "Starts at login, stays in the menu bar, collects nothing.", ui: ui),
            named: "4-preferences"
        )
    }

    // MARK: Helpers

    private func makeAppState(muted: Bool, mode: MicMode, expanded: Bool) -> AppState {
        let hardware = FakeAudioHardware()
        hardware.add("MacBook Pro Microphone")
        hardware.add("USBC Headset")
        let defaults = UserDefaults(suiteName: "Screenshots-\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        settings.showHUD = true
        settings.settingsExpanded = expanded
        settings.mode = mode
        let state = AppState(settings: settings, hardware: hardware, defaults: defaults)
        KeyboardShortcuts.setShortcut(.init(.n, modifiers: [.command, .option]), for: .toggleMic)
        state.deviceTarget = .allDevices
        state.mic.setMuted(muted)
        return state
    }

    @MainActor
    private func render(_ view: some View) -> NSImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 4
        return renderer.nsImage ?? NSImage(size: .zero)
    }

    /// Draws the UI on a branded background with a headline above it.
    private func compose(title: String, subtitle: String, ui: NSImage) -> NSImage {
        let size = Self.canvas
        return NSImage(size: size, flipped: false) { rect in
            NSGradient(
                starting: NSColor(calibratedRed: 0.16, green: 0.42, blue: 0.86, alpha: 1),
                ending: NSColor(calibratedRed: 0.05, green: 0.16, blue: 0.42, alpha: 1)
            )?.draw(in: rect, angle: -90)

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 104, weight: .bold),
                .foregroundColor: NSColor.white,
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 52, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.8),
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
            title.draw(
                at: NSPoint(x: (size.width - titleSize.width) / 2, y: size.height - 210),
                withAttributes: titleAttributes
            )
            subtitle.draw(
                at: NSPoint(x: (size.width - subtitleSize.width) / 2, y: size.height - 300),
                withAttributes: subtitleAttributes
            )

            // The UI sits in the remaining space, scaled to fit with room to breathe.
            let available = NSSize(width: size.width - 640, height: size.height - 560)
            let scale = min(available.width / ui.size.width, available.height / ui.size.height, 1)
            let drawn = NSSize(width: ui.size.width * scale, height: ui.size.height * scale)
            let origin = NSPoint(x: (size.width - drawn.width) / 2, y: (size.height - drawn.height) / 2 - 110)
            let frame = NSRect(origin: origin, size: drawn)

            NSGraphicsContext.current?.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
            shadow.shadowBlurRadius = 60
            shadow.shadowOffset = NSSize(width: 0, height: -20)
            shadow.set()
            ui.draw(in: frame)
            NSGraphicsContext.current?.restoreGraphicsState()
            return true
        }
    }

    private func write(_ image: NSImage, named name: String) throws {
        let size = Self.canvas
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()

        let data = try #require(rep.representation(using: .png, properties: [:]))
        try FileManager.default.createDirectory(at: Self.outputDirectory, withIntermediateDirectories: true)
        let url = Self.outputDirectory.appendingPathComponent("\(name).png")
        try data.write(to: url)
        print("wrote \(url.path)")
    }
}
