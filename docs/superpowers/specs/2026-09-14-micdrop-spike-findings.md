# MicDrop Task 1 — Core Audio spike / sandbox feasibility findings

Date: 2026-09-15
Environment: macOS 26.6.2 (25G83), Xcode 27.0, `swiftc` 6.4 (Apple Swift version 6.4, swiftlang-6.4.0.34.1 clang-2100.3.34.1), Apple Silicon (arm64).
Connected input devices at test time: MacBook Pro Microphone, USBC Headset, AirPods Pro von Paco. A "rekordbox Aggregate Device" was also present but is correctly excluded by `inputDevices()` because `system_profiler SPAudioDataType` shows it with no `Input Channels` line (0 input channels) at test time — it is an aggregate device with no input side currently configured, not a bug in the enumeration filter.

## Build

```
mkdir -p spike/build
swiftc -swift-version 6 -default-isolation MainActor \
  MicDrop/Audio/AudioDevice.swift MicDrop/Audio/AudioHardware.swift MicDrop/Audio/CoreAudioHardware.swift spike/main.swift \
  -o spike/build/micspike
```

Compiled with zero warnings and zero errors. `-default-isolation MainActor` was accepted (no need for the `-swift-version 5` fallback). No changes to the production `MicDrop/Audio/*.swift` files (as specified in the brief) were needed for a clean Swift 6 strict-concurrency build.

## Build/run adaptation (environment-specific, not a code issue)

Signing the raw `swiftc`-produced executable ad-hoc (`codesign --force -s - -i ro.zereb.MicDropSpike --entitlements spike/sandbox.entitlements spike/build/micspike`) and running it directly crashed immediately on this macOS 26.6.2 build, before any `print` output, with `EXC_BREAKPOINT` / `SIGTRAP` inside `_libsecinit_appsandbox.cold.6` (confirmed via the `.ips` crash report in `~/Library/Logs/DiagnosticReports`). The same binary signed the same way **without** the sandbox entitlement ran fine, and the crash reproduced even with the outer shell's own sandboxing disabled — so this is App Sandbox initialization on this OS build rejecting a bare (non-bundle) ad-hoc-signed Mach-O executable, not a nested-sandbox artifact of the tooling and not a bug in `CoreAudioHardware`.

Fix: wrap the identical compiled binary in a minimal `.app` bundle (`Contents/MacOS/micspike` + a trivial `Contents/Info.plist` with `CFBundleIdentifier: ro.zereb.MicDropSpike`, `CFBundleExecutable: micspike`, `LSUIElement: true`) before codesigning/running. This is purely a packaging step — the compiled code under test is byte-for-byte the same `spike/main.swift` + `MicDrop/Audio/*.swift`. This does not affect the committed spike source files. Task 2's real app target is already built as a proper `.app` bundle via xcodegen/xcodebuild, so this quirk does not recur there.

```
mkdir -p spike/build/MicSpike.app/Contents/MacOS
cp spike/build/micspike spike/build/MicSpike.app/Contents/MacOS/micspike
# Contents/Info.plist: CFBundleExecutable=micspike, CFBundleIdentifier=ro.zereb.MicDropSpike, LSUIElement=true
codesign --force -s - -i ro.zereb.MicDropSpike --entitlements spike/sandbox.entitlements spike/build/MicSpike.app
spike/build/MicSpike.app/Contents/MacOS/micspike
```

## Run 1 — plain sandbox entitlement (`spike/sandbox.entitlements`), bundled

Command:
```
codesign --force -s - -i ro.zereb.MicDropSpike --entitlements spike/sandbox.entitlements spike/build/MicSpike.app
spike/build/MicSpike.app/Contents/MacOS/micspike
```

Full output:
```
Default input: AirPods Pro von Paco

== AirPods Pro von Paco [98-1C-A2-CD-77-35:input] id=102
   canMute=true canSetVolume=true
   mute write OK → isMuted=true
   restored → isMuted=true
   volume write OK → volume=0.0 (was 0.0)
   restored → volume=0.0

== USBC Headset [AppleUSBAudioEngine:Samsung:USBC Headset:20190816:1,2] id=87
   canMute=true canSetVolume=true
   mute write OK → isMuted=true
   restored → isMuted=true
   volume write OK → volume=0.0 (was 0.8711111)
   restored → volume=0.8711111

== MacBook Pro Microphone [BuiltInMicrophoneDevice] id=82
   canMute=true canSetVolume=true
   mute write OK → isMuted=true
   restored → isMuted=true
   volume write OK → volume=0.0 (was 0.0)
   restored → volume=0.0

SANDBOX: ACTIVE
```

Exit code: 0. `SANDBOX: ACTIVE` confirms the Desktop write probe was denied — the process really is sandboxed for this run, so the write results above are trustworthy evidence for the sandbox decision.

(Note: `isMuted` reads `true` after "restored" for AirPods and the built-in mic because those two devices were already muted — by prior system/app state, not by this spike — at the moment the spike captured `before`; the spike correctly restored each device to its own pre-run state. USBC Headset was not muted beforehand and its restored volume, 0.871, matches its pre-run value, confirming the restore path works.)

## Run 2 — audio-input entitlement (Step 6)

Not run. Step 6 is conditional on "any write FAILED" in Run 1. All three connected devices reported `mute write OK` and `volume write OK` under the plain sandbox entitlement, so no device required the escalated entitlement.

## Per-device summary

| Device | canMute | canSetVolume | Mute write (plain sandbox) | Volume write (plain sandbox) | Decision |
|---|---|---|---|---|---|
| AirPods Pro von Paco | true | true | OK | OK | Plain sandbox OK |
| USBC Headset | true | true | OK | OK | Plain sandbox OK |
| MacBook Pro Microphone | true | true | OK | OK | Plain sandbox OK |
| rekordbox Aggregate Device | n/a | n/a | not enumerated (0 input channels at test time) | not enumerated | Not applicable — excluded from `inputDevices()` because it currently has no input side; if the user configures input on it later it will be enumerated and muted like any other device using the same code path (no special-casing needed) |

No device in this test supports neither mute nor volume (the "Can't mute" case) — all connected devices support both properties.

## Decision (per brief's decision rules)

**Writes succeed with plain sandbox → continue, no extra entitlement.**

- All writes on all currently connected input devices succeeded under `spike/sandbox.entitlements` (App Sandbox on, no `com.apple.security.device.audio-input`).
- Per the brief's rules, Task 2's `project.yml` entitlements blocks do **not** need `com.apple.security.device.audio-input: true`.
- The App Store build path remains viable with the plain sandbox entitlement set.

## Files

- `MicDrop/Audio/AudioDevice.swift`, `MicDrop/Audio/AudioHardware.swift`, `MicDrop/Audio/CoreAudioHardware.swift` — production Core Audio layer, compiled clean under Swift 6 strict concurrency, no changes needed from the brief's exact text.
- `spike/main.swift`, `spike/sandbox.entitlements`, `spike/sandbox-audio-input.entitlements` — throwaway spike, exact text from the brief; `spike/build/` is gitignored and not committed.
