// THROWAWAY feasibility check — not shipped. Delete after Task 1 is signed off.
import Foundation

let hardware = CoreAudioHardware()
print("Default input:", hardware.defaultInputDevice()?.name ?? "none")

for device in hardware.inputDevices() {
    print("\n== \(device.name) [\(device.uid)] id=\(device.id)")
    print("   canMute=\(hardware.canMute(device)) canSetVolume=\(hardware.canSetVolume(device))")
    if hardware.canMute(device) {
        let before = hardware.isMuted(device)
        do {
            try hardware.setMuted(true, on: device)
            usleep(200_000)
            print("   mute write OK → isMuted=\(hardware.isMuted(device))")
            try hardware.setMuted(before, on: device)
            print("   restored → isMuted=\(hardware.isMuted(device))")
        } catch {
            print("   mute write FAILED: \(error)")
        }
    }
    if hardware.canSetVolume(device) {
        let before = hardware.volume(of: device)
        do {
            try hardware.setVolume(0, on: device)
            usleep(200_000)
            print("   volume write OK → volume=\(hardware.volume(of: device)) (was \(before))")
            try hardware.setVolume(before, on: device)
            print("   restored → volume=\(hardware.volume(of: device))")
        } catch {
            print("   volume write FAILED: \(error)")
        }
    }
}

// Proves the sandbox is really active: writing to the real Desktop must be denied.
let realHome = String(cString: getpwuid(getuid())!.pointee.pw_dir)
let probe = URL(fileURLWithPath: realHome).appendingPathComponent("Desktop/micdrop-sandbox-probe.txt")
do {
    try "x".write(to: probe, atomically: true, encoding: .utf8)
    try? FileManager.default.removeItem(at: probe)
    print("\nSANDBOX: NOT ACTIVE")
} catch {
    print("\nSANDBOX: ACTIVE")
}
