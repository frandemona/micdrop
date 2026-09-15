import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var appState: AppState?
    private var statusItemController: StatusItemController?
    private var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isRunningTests else { return }
        let appState = AppState()
        let preferences = PreferencesWindowController(appState: appState)
        self.appState = appState
        preferencesWindowController = preferences
        statusItemController = StatusItemController(appState: appState) { preferences.show() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.mic.restoreAll()
    }
}
