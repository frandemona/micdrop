# MicDrop QA checklist

Run on a team-signed Release build of each target. Keep System Settings › Sound › Input open.

## Core
- [ ] Menu bar icon reflects state; no Dock icon.
- [ ] Big button toggles; input meter goes flat when OFF.
- [ ] Device: Default / All / MacBook Pro Microphone / USBC Headset each mute only what they should.
- [ ] Unplug headset while it is the selected device → Device falls back to Default Input Device.
- [ ] Plug headset in while muted with All Input Devices → headset muted.
- [ ] A device that can't be muted shows "Can't mute: …".
- [ ] Hotkey toggles with another app focused; Push-to-talk live only while held.
- [ ] Quit while muted → all mics restored.
- [ ] Relaunch → starts unmuted (Toggle) / muted (Push-to-talk); settings and hotkey remembered.

## Build metadata
- [ ] `lipo -info MicDrop.app/Contents/MacOS/MicDrop` shows `x86_64 arm64` for both Release builds.
- [ ] App Info version (`CFBundleShortVersionString`, shown in the feedback subject) equals the release tag.

## HUD & Preferences
- [ ] HUD shows state + target, click-through, fades ~1 s, works over full-screen apps; toggle off works.
- [ ] Launch at Login on → log out/in → MicDrop running; off → not.
- [ ] Send Feedback → Mail to francisco@zereb.ro, subject "MicDrop Feedback (vX.Y.Z)".

## App Store build
- [ ] Three tip buttons with localized prices; purchase updates total and thanks message.
- [ ] Review MicDrop shows the rating prompt.
- [ ] No Updates section; no Sparkle.framework in the bundle.

## Direct build
- [ ] "Leave a tip" opens the real tip page.
- [ ] Check for Updates… reports up to date; after publishing a higher version, an older build updates itself.

## Localization
- [ ] Launch with `-AppleLanguages "(xx)"` for every one of `es`, `fr`, `de`, `it`, `pt-BR`, `ja`, `zh-Hans`, `ko`: no truncation or English leftovers.
- [ ] Launch with `-NSDoubleLocalizedStrings YES`: no truncation.
- [ ] Native-speaker review done; mark reviewed strings `translated` in Localizable.xcstrings.
