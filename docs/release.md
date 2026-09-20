# Releasing MicDrop

## One-time setup
1. Apple Developer Program membership; note your Team ID (Xcode › Settings › Accounts, or the
   parenthetical in `security find-identity -v -p codesigning`).
2. Certificates — Xcode › Settings › Accounts › your team › Manage Certificates › **+**:
   - **Developer ID Application** — signs the direct download (needed before notarizing).
   - **Apple Distribution** — signs the App Store build.
   Verify with `security find-identity -v -p codesigning`; both should be listed.
3. `xcrun notarytool store-credentials micdrop-notary --apple-id <your Apple ID> --team-id <TEAM_ID>
   --password <app-specific password>` — create the app-specific password at appleid.apple.com
   (Sign-In and Security › App-Specific Passwords). Check it with `xcrun notarytool history
   --keychain-profile micdrop-notary`.
4. App Store Connect — create the app record and the three tip IAPs; copy from `docs/appstore-metadata.md`.
   A Privacy Policy URL is required; that file has the policy text to publish.
5. Sparkle private key lives in the login Keychain; keep the exported backup in a password manager.
   Losing it means installed copies can never update again.
6. Tip link: `TipConfig.directTipURL` in `MicDrop/Tips/LinkTipsView.swift` (set to the Ko-fi page).

Signing is wired up: `project.yml` sets `DEVELOPMENT_TEAM: 333DBUCL9X` for Release, so archives pick
the right identities without touching Xcode. Certificates in use: **Developer ID Application** (direct
download) and **Apple Distribution** + **3rd Party Mac Developer Installer** (App Store `.pkg`).

## Store assets

- Listing copy, promotional text, keywords, review notes, IAP details and the privacy policy text:
  `docs/appstore-metadata.md`.
- Privacy policy is published at https://frandemona.github.io/micdrop/privacy.html (`privacy.html` on
  the `gh-pages` branch).
- Screenshots: capture a window with ⇧⌘4 then Space, then wrap it in a captioned 1280×800 canvas:
  ```
  swift scripts/compose-screenshot.swift ~/Desktop/capture.png build/screenshots/1-popover.png \
    "Mute your mic from anywhere" "One hotkey. Every app. No hunting for a button." 1280
  ```
  Pass `2560` instead of `1280` for the larger accepted size. To capture the HUD, temporarily raise the
  1-second hold in `MicDrop/HUD/HUDController.swift`, capture, then put it back.
- `scripts/make-screenshots.sh` renders the same shots from the UI with no manual capture, via the
  `ScreenshotGenerator` suite. It needs the test host to launch, so it fails while macOS is waiting on
  a permission prompt; the manual route above always works.

## Each release
1. Bump both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`; commit.
   `CURRENT_PROJECT_VERSION` (the build number, `CFBundleVersion`) must increase on every release, direct and
   App Store alike: Sparkle only offers updates with a higher build number and App Store Connect rejects
   duplicates. The release script refuses to publish if the version doesn't match or the build isn't higher.
2. Run `docs/qa-checklist.md` on both builds.
3. Direct: `TEAM_ID=XXXXXXXXXX NOTARY_PROFILE=micdrop-notary scripts/release-direct.sh`
   If it fails partway, fix the cause and re-run — it reuses an existing release and cleans up its worktree.
4. App Store: `xcodegen generate`, then `xcodebuild build -project MicDrop.xcodeproj -scheme MicDropAppStore`
   to confirm it builds. Release uses Automatic signing with no team in `project.yml`, so after each
   `xcodegen generate` select your team in Xcode (Signing & Capabilities, both targets) or pass
   `DEVELOPMENT_TEAM=XXXXXXXXXX` to xcodebuild. Then open `MicDrop.xcodeproj`, scheme `MicDropAppStore`, Product › Archive,
   Distribute App › App Store Connect, then submit in App Store Connect with the IAPs attached.
   The `.pkg` can also be exported headlessly and uploaded with Transporter:
   ```
   xcodebuild archive -project MicDrop.xcodeproj -scheme MicDropAppStore -configuration Release \
     -archivePath build/release/MicDropAppStore.xcarchive -derivedDataPath build/release-appstore-dd \
     DEVELOPMENT_TEAM=333DBUCL9X -allowProvisioningUpdates
   xcodebuild -exportArchive -archivePath build/release/MicDropAppStore.xcarchive \
     -exportPath build/release/appstore -exportOptionsPlist build/release/ExportOptionsAppStore.plist \
     -allowProvisioningUpdates
   ```
   (export options: `method` `app-store-connect`, `teamID` `333DBUCL9X`, `signingStyle` `automatic`).

## Packaging note

Both `ditto` calls in `scripts/release-direct.sh` use `--sequesterRsrc`, which keeps AppleDouble
metadata in a separate `__MACOSX` folder instead of `._` files inside the bundle. Without it, users who
unpack the zip with the `unzip` command or a third-party unarchiver end up with `._` files inside
`Sparkle.framework`, which breaks the code signature and triggers the macOS "could not verify this app
is free of malware" dialog even though the download is correctly signed, notarized and stapled. The
1.0.1 zip was built before this fix.

To check any copy: `codesign --verify --deep --strict /Applications/MicDrop.app` and
`spctl -a -vvv -t exec /Applications/MicDrop.app`. To repair one:
`find /Applications/MicDrop.app -name '._*' -delete`.

## Release log

| Version | Build | Direct download | App Store |
|---|---|---|---|
| 1.0.0 | 1 | Published 2026-09-16: notarized, stapled, [release v1.0.0](https://github.com/frandemona/micdrop/releases/tag/v1.0.0), appcast live | Submitted for review 2026-09-16 |
| 1.0.1 | 2 | Published 2026-09-16: [release v1.0.1](https://github.com/frandemona/micdrop/releases/tag/v1.0.1); used to verify the update path | Not submitted |

**Update path verified 2026-09-16.** A stashed 1.0.0 build offered 1.0.1 through "Check for Updates…"
and installed it. The feed's EdDSA signature was also checked independently by re-signing the zip with
Sparkle's `sign_update` and comparing it to the appcast entry (they matched, as did the byte length).
