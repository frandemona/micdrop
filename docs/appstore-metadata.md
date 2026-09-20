# MicDrop: App Store Connect metadata

Draft copy for the App Store listing. Edit freely; nothing here is final until you paste it in.

## App record

| Field | Value |
|---|---|
| Name | MicDrop |
| Subtitle | Mute your mic with one hotkey |
| Bundle ID | `ro.zereb.MicDrop` |
| SKU | micdrop-mac-001 |
| Primary category | Utilities |
| Secondary category | Productivity |
| Price | Free (tips are in-app purchases) |
| Age rating | 4+ |
| Copyright | © 2026 Zereb |
| Support URL | https://github.com/frandemona/micdrop |
| Marketing URL (optional) | https://github.com/frandemona/micdrop |
| Privacy Policy URL | required: see "Privacy policy" below |

## Description

> Mute and unmute your microphone anywhere on your Mac, with one keystroke.
>
> MicDrop lives in the menu bar. Press your hotkey and every microphone you choose goes silent: in
> meetings, recordings, or anything else running. The menu bar icon and a brief on-screen message
> always tell you which state you're in, so you never have to guess whether you're live.
>
> • Global hotkey: mute from any app, without switching windows
> • Toggle or push-to-talk: tap to switch, or hold to talk and release to mute
> • Choose your microphone: the default one, a specific one, or every connected input at once
> • Clear feedback: the menu bar icon changes and an on-screen indicator confirms each change
> • Hardware-level muting: apps receive silence, not a request to be quiet
> • Starts with your Mac, and stays out of the way
>
> MicDrop never records audio, never asks for microphone access, and sends nothing anywhere.
>
> There's a tip jar in Preferences if MicDrop saves you from a hot-mic moment.

## Promotional Text (170 characters max)

Shown above the description, and editable any time without submitting a new build, so use it for
seasonal or "what's new" messaging.

> Never be the one talking on mute. One hotkey silences every mic on your Mac, with a clear on-screen
> confirmation so you always know whether you're live.

Alternatives:

> Hot mic? Not any more. Mute every microphone on your Mac with one keystroke, from any app, and see
> at a glance whether you're live.

> One keystroke mutes your mic everywhere on your Mac. Toggle it or hold to talk, and always know
> which way round you are before you speak.

## Keywords (100 characters max, comma separated)

```
mute,microphone,mic,hotkey,menu bar,push to talk,meetings,privacy,shortcut,audio,mute mic
```

## What's New (first release)

> First release.

## Review notes

> MicDrop is a menu bar utility that mutes the microphone system-wide. It uses Core Audio's standard
> mute and input-volume properties on the user's selected input devices; it never opens an audio
> stream and never requests microphone permission, so no recording ever takes place.
>
> How to test: click the microphone icon in the menu bar, click the large button to mute, and observe
> the input level in System Settings → Sound → Input (for devices without a hardware mute switch the
> input volume goes to zero). Open SETTINGS in the popover to pick a device, switch between Toggle and
> Push-to-talk, and record a hotkey.
>
> The in-app purchases are optional tips. They unlock nothing; the app is fully functional without them.

## In-app purchases (consumable)

| Product ID | Reference name | Display name | Price tier | Description |
|---|---|---|---|---|
| `ro.zereb.MicDrop.tip.small` | Small Tip | Small Tip | $1.99 | A small tip to support MicDrop's development. |
| `ro.zereb.MicDrop.tip.medium` | Medium Tip | Medium Tip | $4.99 | A tip to support MicDrop's development. |
| `ro.zereb.MicDrop.tip.large` | Large Tip | Large Tip | $9.99 | A generous tip to support MicDrop's development. |

Each IAP needs a screenshot for review: a capture of the Preferences window showing the tip buttons is enough.

## App privacy answers

- **Data collection: No.** Answer "No" to "Do you or your third-party partners collect data from this app?"
- No tracking, no analytics, no accounts, no network requests (the App Store build has no network entitlement).
- Export compliance: already declared in the app with `ITSAppUsesNonExemptEncryption = false`, so no per-upload prompt.

## Screenshots

**Guideline 2.3.7: no price references, anywhere in a screenshot.** That includes the words "free",
"tip", "discount" or any amount, in the caption *and* in the captured UI. MicDrop 1.0 build 1 was
rejected on 2026-09-19 for a Preferences screenshot captioned "Free, and out of your way" showing the
window's "MicDrop is free, but please leave a tip..." blurb. Never screenshot the Preferences window:
its tip jar makes it unusable for the store. (The tip jar screenshot required for each in-app purchase
is separate metadata and is fine there.)

macOS accepts at least one, up to ten, at 1280x800, 1440x900, 2560x1600 or 2880x1800.

Approved set:

| # | Shot | Headline | Subtitle |
|---|---|---|---|
| 1 | Popover, muted, settings expanded | Mute your mic from anywhere | One hotkey. Every app. No hunting for a button. |
| 2 | On-screen indicator | Always know if you're live | A clear confirmation every time you mute or unmute. |
| 3 | Popover in Push-to-talk mode (optional) | Toggle or push-to-talk | Tap to switch, or hold your key to talk and release to mute. |

Capture a window with Shift-Cmd-4 then Space, then wrap it:

```
swift scripts/compose-screenshot.swift ~/Desktop/capture.png build/screenshots/1-popover.png \
  "Mute your mic from anywhere" "One hotkey. Every app. No hunting for a button." 1280
```

`scripts/make-screenshots.sh` and the `ScreenshotGenerator` suite render the UI offscreen, but SwiftUI's
`ImageRenderer` draws AppKit-backed controls (pickers, the hotkey recorder) as placeholder blocks, so
their output is **not** usable for the store. Capture real windows.

## Privacy policy

Required by App Store Connect even though MicDrop collects nothing. Publish this text somewhere public -
the `gh-pages` branch of `frandemona/micdrop` already serves files, so `privacy.html` there would be at
`https://frandemona.github.io/micdrop/privacy.html`.

> **MicDrop Privacy Policy**
>
> MicDrop does not collect, store, or transmit any personal data.
>
> MicDrop runs entirely on your Mac. It never records audio and never requests microphone access: it
> only changes the mute and input-volume settings of the audio devices you select. Your settings
> (chosen device, mode, hotkey, and preferences) are stored locally on your Mac and are never sent
> anywhere.
>
> The version downloaded from this website checks for updates, which sends your Mac's IP address and
> standard web request information to GitHub, where the update file is hosted. No identifying data is
> included. The Mac App Store version does not check for updates itself.
>
> Optional tips are handled by Apple through the App Store. Apple does not share your payment details
> with the developer. MicDrop stores only the total amount you have tipped, locally on your Mac.
>
> Questions: francisco@zereb.ro
>
> Last updated: 2026-09-16
