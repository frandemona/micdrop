# MicDrop QA checklist

Run on a team-signed Release build of each target. Keep System Settings › Sound › Input open.

## Core
- [x] Menu bar icon reflects state; no Dock icon.
- [x] Big button toggles; input meter goes flat when OFF.
- [x] Device: Default / All / MacBook Pro Microphone / USBC Headset each mute only what they should.
- [x] Unplug headset while it is the selected device → Device falls back to Default Input Device.
- [x] Plug headset in while muted with All Input Devices → headset muted.
- [ ] A device that can't be muted shows "Can't mute: …".
- [x] Hotkey toggles with another app focused; Push-to-talk live only while held.
- [x] Quit while muted → all mics restored.
- [x] Relaunch → starts unmuted (Toggle) / muted (Push-to-talk); settings and hotkey remembered.

## Build metadata
- [x] `lipo -info MicDrop.app/Contents/MacOS/MicDrop` shows `x86_64 arm64` for both Release builds.
- [x] App Info version (`CFBundleShortVersionString`, shown in the feedback subject) equals the release tag.

## HUD & Preferences
- [x] HUD shows state + target, click-through, fades ~1 s, works over full-screen apps; toggle off works.
- [x] Launch at Login on → log out/in → MicDrop running; off → not.
- [x] Send Feedback → Mail to francisco@zereb.ro, subject "MicDrop Feedback (vX.Y.Z)".

## App Store build
- [x] Three tip buttons with localized prices; purchase updates total and thanks message.
- [x] Review MicDrop shows the rating prompt.
- [x] No Updates section; no Sparkle.framework in the bundle.

## Direct build
- [x] "Leave a tip" opens the real tip page.
- [x] Check for Updates… reports up to date; after publishing a higher version, an older build updates itself.

## Localization
- [x] Launch with `-AppleLanguages "(xx)"` for every one of `es`, `fr`, `de`, `it`, `pt-BR`, `ja`, `zh-Hans`, `ko`: no truncation or English leftovers.
- [x] Launch with `-NSDoubleLocalizedStrings YES`: no truncation.
- [ ] Native-speaker review done; mark reviewed strings `translated` in Localizable.xcstrings.
