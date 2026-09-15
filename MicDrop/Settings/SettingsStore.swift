import Foundation
import Observation

nonisolated enum MicMode: String, CaseIterable, Codable, Sendable {
    case toggle
    case pushToTalk
}

/// User settings persisted in UserDefaults. The hotkey itself is persisted by KeyboardShortcuts.
@Observable
final class SettingsStore {
    private enum Key {
        static let deviceTarget = "deviceTarget"
        static let mode = "mode"
        static let showHUD = "showHUD"
        static let settingsExpanded = "settingsExpanded"
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var deviceTarget: DeviceTarget {
        get {
            access(keyPath: \.deviceTarget)
            guard let data = defaults.data(forKey: Key.deviceTarget),
                  let target = try? JSONDecoder().decode(DeviceTarget.self, from: data) else { return .defaultDevice }
            return target
        }
        set {
            withMutation(keyPath: \.deviceTarget) {
                defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.deviceTarget)
            }
        }
    }

    var mode: MicMode {
        get {
            access(keyPath: \.mode)
            return defaults.string(forKey: Key.mode).flatMap(MicMode.init(rawValue:)) ?? .toggle
        }
        set {
            withMutation(keyPath: \.mode) { defaults.set(newValue.rawValue, forKey: Key.mode) }
        }
    }

    var showHUD: Bool {
        get {
            access(keyPath: \.showHUD)
            return defaults.object(forKey: Key.showHUD) as? Bool ?? true
        }
        set {
            withMutation(keyPath: \.showHUD) { defaults.set(newValue, forKey: Key.showHUD) }
        }
    }

    var settingsExpanded: Bool {
        get {
            access(keyPath: \.settingsExpanded)
            return defaults.bool(forKey: Key.settingsExpanded)
        }
        set {
            withMutation(keyPath: \.settingsExpanded) { defaults.set(newValue, forKey: Key.settingsExpanded) }
        }
    }
}
