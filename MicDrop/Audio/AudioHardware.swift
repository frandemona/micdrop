/// The slice of Core Audio that MicDrop needs. Faked in tests.
protocol AudioHardware: AnyObject {
    func inputDevices() -> [AudioDevice]
    func defaultInputDevice() -> AudioDevice?

    func canMute(_ device: AudioDevice) -> Bool
    func isMuted(_ device: AudioDevice) -> Bool
    func setMuted(_ muted: Bool, on device: AudioDevice) throws

    func canSetVolume(_ device: AudioDevice) -> Bool
    func volume(of device: AudioDevice) -> Float
    func setVolume(_ volume: Float, on device: AudioDevice) throws

    /// Called on the main queue when devices appear/disappear or the default input changes.
    func setDevicesChangedHandler(_ handler: @escaping () -> Void)
}
