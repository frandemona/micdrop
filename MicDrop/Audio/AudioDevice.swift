/// A Core Audio input device. `uid` is stable across reconnects; `id` is not.
nonisolated struct AudioDevice: Hashable, Sendable {
    let id: UInt32
    let uid: String
    let name: String
}

/// Which input devices MicDrop mutes.
nonisolated enum DeviceTarget: Codable, Hashable, Sendable {
    case defaultDevice
    case allDevices
    case specific(uid: String)
}
