# MicDrop — Design Spec

Date: 2026-09-14
Status: Approved 2026-09-14; localization (§9) and auto-updates (§10) added after approval

## 1. Purpose

MicDrop is a native macOS menu bar utility that mutes/unmutes microphone input system-wide via a global hotkey or a click. It replaces MuteKey (App Store id1509590766), which is Intel-only and will stop working when Rosetta support ends (Apple support article 102527). MicDrop matches MuteKey's feature set and layout with its own name and icon.

## 2. Identity & targets

| Item | Value |
|---|---|
| App name | MicDrop |
| Bundle ID | `ro.zereb.MicDrop` |
| Minimum macOS | 14.0 (Sonoma) |
| Architectures | Universal (arm64 + x86_64), native |
| Language / UI | Swift 6, SwiftUI (AppKit where needed: status item, HUD panel) |
| Project generation | XcodeGen (`project.yml`), installed via Homebrew |
| App type | Agent app (`LSUIElement = YES`), no Dock icon |

## 3. Distribution variants

One codebase, two Xcode app targets sharing all sources: `MicDrop` (direct) and `MicDropAppStore`. The App Store target sets the `APPSTORE` compilation condition and does not link Sparkle.

| | App Store build | Direct build |
|---|---|---|
| Compilation condition | `APPSTORE` | *(none)* |
| Sandbox | Yes | Hardened runtime, notarized (sandbox also on — no reason to drop it) |
| Tips | StoreKit 2 consumable IAPs: $1.99 / $4.99 / $9.99 | Single "Leave a tip" button opening `TipConfig.directTipURL` (placeholder: `https://example.com/tip-micdrop`) |
| "Review MicDrop" | StoreKit `requestReview` | Hidden |
| "Total amount tipped" | Shown (locally persisted) | Hidden |

IAP product IDs: `ro.zereb.MicDrop.tip.small`, `ro.zereb.MicDrop.tip.medium`, `ro.zereb.MicDrop.tip.large`.

## 4. Architecture

```
MicDropApp (entry, NSApplicationDelegateAdaptor)
 ├─ AppState (@Observable, @MainActor) — single source of truth for UI
 │    ├─ MicController ── AudioHardware (protocol) ── CoreAudioHardware (real) / FakeAudioHardware (tests)
 │    ├─ HotkeyController (KeyboardShortcuts)
 │    ├─ SettingsStore (UserDefaults)
 │    └─ HUDController
 ├─ StatusItemController (NSStatusItem + NSPopover hosting PopoverView)
 ├─ PreferencesWindowController (NSWindow hosting SwiftUI PreferencesView)
 ├─ Updater (Sparkle, direct build only)
 └─ TipJar (protocol) ── StoreKitTipJar (APPSTORE) / LinkTipJar (direct)
```

### 4.1 AudioHardware (protocol)
Thin wrapper over Core Audio HAL so logic is testable.
- `inputDevices() -> [AudioDevice]` (id, uid, name)
- `defaultInputDeviceID() -> AudioDeviceID?`
- `canMute(_:)`, `isMuted(_:)`, `setMuted(_:_:) throws` — `kAudioDevicePropertyMute`, input scope, main element (fallback: per-channel elements 1…n)
- `canSetVolume(_:)`, `volume(_:)`, `setVolume(_:_:) throws` — `kAudioDevicePropertyVolumeScalar`, input scope
- `onDevicesChanged(_ handler:)` — listeners on `kAudioHardwarePropertyDevices` and `kAudioHardwarePropertyDefaultInputDevice`

### 4.2 MicController
- State: `isMuted: Bool`, `target: DeviceTarget` (`.defaultDevice`, `.allDevices`, `.specific(uid:)`), `unsupportedDevices: [AudioDevice]`, `availableDevices: [AudioDevice]`.
- Keeps the user's intent (`wantsMuted`) separately from `isMuted`, so unplugging every mic and plugging one back re-mutes it.
- `mute()`: for each target device — if `canMute` use mute property; else if `canSetVolume` save current volume (keyed by device UID) then set 0; else add to `unsupportedDevices`.
- `unmute()`: undo exactly what `mute()` did per device (clear mute flag it set, restore saved volume; a saved volume of 0 restores to 1.0). Never touches devices it didn't change.
- `toggle()`, `setMuted(_:)`, `setTarget(_:)`. `onMuteStateChanged(Bool)` fires only when `isMuted` actually changes (drives the HUD).
- On device list change while muted: apply mute to newly present target devices. On default-device change with target `.default`: unmute old default (restore), mute new default.
- If `.specific(uid:)` device disappears: fall back to `.defaultDevice`, persist the change.
- `restoreAll()`: called on app termination; unmutes everything MicDrop changed.

### 4.3 HotkeyController
- Uses `KeyboardShortcuts` (sindresorhus, MIT, SPM) with name `.toggleMic`; no default shortcut.
- Mode `.toggle`: `onKeyDown` → `toggle()`.
- Mode `.pushToTalk`: on entering mode, mute. `onKeyDown` → unmute; `onKeyUp` → mute.
- Switching back to Toggle leaves current state unchanged.

### 4.4 SettingsStore (UserDefaults keys)
`deviceTarget` (encoded), `mode`, `showHUD` (default true), `settingsExpanded` (default false). Hotkey persisted by KeyboardShortcuts. Launch at Login is read/written live via `SMAppService.mainApp` (not duplicated in defaults). `totalTipped` (Decimal string, App Store build only).

### 4.5 UI

**Status item:** SF Symbol `mic.fill` (ON) / `mic.slash.fill` (OFF), template image. Left click toggles popover.

**Popover (≈260pt wide), top to bottom:**
1. Large circular button (~180pt): white disc, blue ring; blue `mic.fill` when ON, dark `mic.slash.fill` when OFF. Click → toggle.
2. Label "Microphone ON" (accent blue) / "Microphone OFF" (primary).
3. "SETTINGS ⌃/⌄" disclosure button.
4. Collapsible grid:
   - Device: popup — "Default Input Device", "All Input Devices", divider, each device by name.
   - Mode: popup — "Toggle", "Push-to-talk".
   - Hotkey: `KeyboardShortcuts.Recorder` (includes clear ✕).
5. Footer: gear button (opens Preferences, activates app) left; "Quit" button right.
6. If `unsupportedDevices` non-empty: small warning line "Can't mute: <names>".

**HUD:** borderless, non-activating `NSPanel`, ~200×200pt, rounded 18pt, `NSVisualEffectView` (.hudWindow), centered horizontally in lower third of main screen, ignores mouse, all spaces. Shows symbol + "Mic ON"/"Mic OFF" + secondary line with target ("All Devices", "Default Device", or device name). Fades in, holds 1.0s, fades out 0.3s; re-triggering resets the timer. Only when `showHUD` is true.

**Preferences window** ("MicDrop Preferences", fixed size, not resizable):
- Blurb: "MicDrop is free, but please leave a tip if you want to see more features!"
- Tips area (per variant, §3). App Store: three buttons with emoji + localized price from StoreKit; "Total amount tipped:" + amount. Purchase success → thank-you message and total increments.
- "Settings" group box: ☐ Show HUD on mute/unmute, ☐ Launch at Login.
- Bottom row: "Review MicDrop" (App Store only), "Send Feedback".

**Send Feedback:** opens `mailto:francisco@zereb.ro?subject=MicDrop%20Feedback%20(v<CFBundleShortVersionString>)` via `NSWorkspace.open`.

## 5. Behavior rules

- Launch: always starts unmuted (in Toggle mode); in Push-to-talk mode starts muted.
- Quit (Quit button or system termination): `restoreAll()` before exit.
- Microphone permission: not requested — MicDrop never records audio.
- Sandbox entitlements: `com.apple.security.app-sandbox`; add `com.apple.security.device.audio-input` only if the feasibility spike shows it is required for HAL property writes. App Store build also needs no network entitlement beyond StoreKit (none required).

## 6. Error handling

- Core Audio write failure → device goes into `unsupportedDevices`, shown in popover; `isMuted` still reflects the user's intent for devices that succeeded.
- If *every* target device fails, `isMuted` stays false and popover shows the warning (never claim muted when nothing is muted).
- StoreKit errors/cancellation: silent on cancel; brief inline message on failure.
- `SMAppService` register failure: revert toggle, show inline message.

## 7. Testing

- Unit tests (XCTest/Swift Testing) for `MicController` against `FakeAudioHardware`: mute/unmute via mute property, via volume fallback with exact restore, unsupported devices, hot-plug while muted, default-device switch, specific-device removal fallback, `restoreAll`.
- Unit tests for hotkey mode logic (key down/up → controller calls) with an injectable event source.
- Manual checklist on real hardware: MacBook Pro Microphone, USBC Headset, All Devices, hotkey in both modes, HUD, Launch at Login, feedback mail, StoreKit test configuration (`.storekit` file) for tips.

## 8. Build order (first step is a gate)

1. **Feasibility spike (throwaway):** sandboxed CLI/app that toggles mute/volume on each input device on this Mac, including the USBC Headset. Confirms sandbox allows HAL writes and which devices support mute vs volume. Findings may adjust §4.2/§5.
2. Project scaffold (XcodeGen, two configs, SPM dependency).
3. AudioHardware + MicController with tests.
4. Status item + popover.
5. Hotkey + modes.
6. HUD.
7. Preferences, Launch at Login, feedback.
8. Tip jars (StoreKit config file + link variant).
9. Sparkle auto-updates (direct build) + GitHub release feed setup.
10. Localization (9 languages).
11. App icon (original design, no SF Symbols), release script, manual checklist.

## 9. Localization

- All user-facing strings live in a single String Catalog `MicDrop/Resources/Localizable.xcstrings`; SwiftUI `Text("…")` / `String(localized:)` only — no hardcoded concatenation.
- Languages: English (development), Spanish (`es`), French (`fr`), German (`de`), Italian (`it`), Portuguese – Brazil (`pt-BR`), Japanese (`ja`), Chinese Simplified (`zh-Hans`), Korean (`ko`).
- `CFBundleLocalizations` lists all nine languages in both Info.plists. No `InfoPlist.xcstrings` — the display name is "MicDrop" everywhere and there are no usage strings.
- Device names come from Core Audio and are not translated. Prices come localized from StoreKit.
- Translations are drafted during implementation and flagged for native-speaker review before release; String Catalog state `needs_review` until confirmed.
- Layout: popover and Preferences use flexible widths so German/French labels don't truncate; verified with `-AppleLanguages (de)` and the pseudo-language "Double-Length".

## 10. Auto-updates (direct build only)

- Sparkle 2 via SPM, linked only by the `MicDrop` (direct) target; Sparkle code wrapped in `#if !APPSTORE`.
- GitHub repo `micdrop` is public but holds only the `gh-pages` branch (appcast) and Releases; the app source is never pushed there.
- Sandboxed Sparkle setup: `SUEnableInstallerLauncherService = YES`, `SUEnableDownloaderService = NO` (network client entitlement instead), mach-lookup entitlement `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` / `-spki`.
- `SUFeedURL = https://<gh-owner>.github.io/micdrop/appcast.xml` (owner filled in once the repo exists); `SUPublicEDKey` from `generate_keys` (private key stays in the login Keychain, never committed).
- `SUEnableAutomaticChecks = YES`, daily interval; user can "Check for Updates…" from a button in Preferences, and toggle "Automatically check for updates".
- Release pipeline script `scripts/release-direct.sh`: archive → export Developer ID → notarize (`notarytool`) → staple → zip/dmg → `generate_appcast` → `gh release create vX.Y` with the archive → commit updated `appcast.xml` to the `gh-pages` branch.
- App Store build: no Sparkle code, no update UI.

## 11. Out of scope

Per-app muting, menu bar icon customization, analytics.
