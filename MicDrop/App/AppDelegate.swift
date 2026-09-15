import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var appState: AppState?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isRunningTests else { return }
        let appState = AppState()
        self.appState = appState
        statusItemController = StatusItemController(appState: appState, openPreferences: {})
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.mic.restoreAll()
    }
}
