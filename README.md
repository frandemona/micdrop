# MicDrop

**Mute your microphone on macOS with one keystroke, from any app.**

MicDrop is a small menu bar utility that mutes and unmutes your Mac's microphone system-wide. Press a
global hotkey and every microphone you choose goes silent, whatever app is in front: Zoom, Google Meet,
Teams, Slack, Discord, QuickTime, OBS, anything. The menu bar icon and a brief on-screen indicator
always tell you whether you are live.

It mutes at the hardware level through Core Audio, so apps receive silence rather than a polite request
to stop listening. MicDrop never records audio and never asks for microphone permission.

[Download the latest release](https://github.com/frandemona/micdrop/releases/latest) · macOS 14 Sonoma
or later · Universal (Apple silicon and Intel)

## Features

- **Global hotkey** to mute and unmute from any app, without switching windows.
- **Toggle or push-to-talk.** Tap to switch state, or hold the key to talk and release to mute.
- **Pick your microphone:** the system default, one specific device, or every connected input at once.
- **Menu bar icon** that shows the current state, plus an on-screen indicator on every change.
- **Survives device changes.** Plug in a headset while muted and it gets muted too; unplug a muted mic
  and MicDrop still restores it when it comes back.
- **Recovers after a crash.** If MicDrop is force-quit while muted, the next launch unmutes what it
  changed, so you are never left silently muted.
- **Launches at login**, stays out of the Dock, and uses no network in the App Store build.
- **Localized** in English, Spanish, French, German, Italian, Brazilian Portuguese, Japanese,
  Simplified Chinese, and Korean.

## Install

**Mac App Store:** coming soon.

**Direct download:** grab the `.zip` from the [latest release](https://github.com/frandemona/micdrop/releases/latest),
unzip it **by double-clicking it in Finder**, and drag `MicDrop.app` to your Applications folder.
(Unpacking with the `unzip` command or some third-party unarchivers can leave stray `._` files inside
the app bundle, which breaks its signature and makes macOS report that it can't verify the app. If you
hit that, delete the copy and extract again with Finder.) The app is signed with a Developer ID
certificate and notarized by Apple, so it opens without security warnings, and it updates itself through
Sparkle.

## Using it

1. Click the microphone icon in the menu bar.
2. Click the large button to mute or unmute.
3. Open **SETTINGS** to choose a device, switch between Toggle and Push-to-talk, and record a hotkey.
4. The gear opens Preferences: on-screen indicator, launch at login, updates, and the tip jar.

**How the muting works.** For microphones with a hardware mute control, MicDrop sets that control. For
the rest, it saves the current input volume and sets it to zero, restoring your original level when you
unmute. You can verify either in Audio MIDI Setup, where the Mute checkbox or the input slider reflects
what MicDrop did. Some devices, AirPods among them, accept the command and ignore it; those are listed
as "Can't mute" in the popover rather than being silently reported as muted.

## Privacy

MicDrop collects nothing. No analytics, no accounts, no tracking. Settings stay on your Mac. The direct
download checks GitHub for updates; the App Store build does not talk to the network at all. Full
[privacy policy](https://frandemona.github.io/micdrop/privacy.html).

## Building from source

Requires macOS 14+, Xcode 26 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). The Xcode project is generated from `project.yml` and is not checked in.

```bash
git clone https://github.com/frandemona/micdrop.git
cd micdrop
xcodegen generate
open MicDrop.xcodeproj
```

Two app targets share all sources:

| Target | Distribution | Differences |
|---|---|---|
| `MicDrop` | Direct download | Sparkle auto-updates, tip link |
| `MicDropAppStore` | Mac App Store | `APPSTORE` compilation condition, StoreKit tips, review prompt, no Sparkle |

Run the tests:

```bash
xcodebuild test -project MicDrop.xcodeproj -scheme MicDrop -destination 'platform=macOS,arch=arm64'
```

## Project layout

```
MicDrop/Audio/        Core Audio wrapper and the mute logic (MicController)
MicDrop/MenuBar/      Status item and popover
MicDrop/HUD/          On-screen indicator
MicDrop/Preferences/  Preferences window
MicDrop/Tips/         StoreKit tip jar and the direct-build tip link
MicDrop/Updates/      Sparkle integration
MicDropTests/         Unit tests against a fake audio device
docs/                 Design spec, release process, QA checklist, store metadata
scripts/              Release, icon and screenshot tooling
```

`docs/release.md` covers signing, notarization, and publishing. `docs/qa-checklist.md` is the manual
test pass before a release.

## Why it exists

It replaces [MuteKey](https://apps.apple.com/us/app/mutekey/id1509590766), which is Intel-only and stops
working once macOS drops Rosetta support. MicDrop is a native rewrite with the same idea: one key, mic
off.

## Support

Questions and bug reports: francisco@zereb.ro, or open an issue.

MicDrop is free. There's a tip jar in Preferences if it saves you from a hot-mic moment.
