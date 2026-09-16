#if !APPSTORE
import AppKit
import Observation
import Sparkle

/// Tells Sparkle this agent app handles scheduled update reminders gently, and brings
/// MicDrop forward when a background check finds one — otherwise the alert opens unnoticed.
private nonisolated final class GentleReminderDelegate: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        guard handleShowingUpdate, !state.userInitiated else { return }
        MainActor.assumeIsolated { NSApp.activate() }
    }
}

@Observable
final class Updater {
    @ObservationIgnored private let driverDelegate: GentleReminderDelegate
    @ObservationIgnored private let controller: SPUStandardUpdaterController

    init() {
        let delegate = GentleReminderDelegate()
        driverDelegate = delegate
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: delegate
        )
    }

    var automaticallyChecksForUpdates: Bool {
        get {
            access(keyPath: \.automaticallyChecksForUpdates)
            return controller.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.automaticallyChecksForUpdates) {
                controller.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    func checkForUpdates() {
        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}
#endif
