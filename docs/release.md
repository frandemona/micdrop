# Releasing MicDrop

## One-time setup
1. Apple Developer Program membership; note your Team ID.
2. `xcrun notarytool store-credentials micdrop-notary` (Apple ID + app-specific password).
3. Sparkle private key is in the login Keychain (Task 10). Keep the exported backup safe.
4. App Store Connect: create app "MicDrop", bundle ID `ro.zereb.MicDrop`; create consumable IAPs
   `ro.zereb.MicDrop.tip.small` ($1.99), `.tip.medium` ($4.99), `.tip.large` ($9.99) with localized names.
5. Replace `TipConfig.directTipURL` in `MicDrop/Tips/LinkTipsView.swift` with the real tip page.

## Each release
1. Bump both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`; commit.
   `CURRENT_PROJECT_VERSION` (the build number, `CFBundleVersion`) must increase on every release, direct and
   App Store alike: Sparkle only offers updates with a higher build number and App Store Connect rejects
   duplicates. The release script refuses to publish if the version doesn't match or the build isn't higher.
2. Run `docs/qa-checklist.md` on both builds.
3. Direct: `TEAM_ID=XXXXXXXXXX NOTARY_PROFILE=micdrop-notary scripts/release-direct.sh`
   If it fails partway, fix the cause and re-run — it reuses an existing release and cleans up its worktree.
4. App Store: `xcodegen generate`, open `MicDrop.xcodeproj`, scheme `MicDropAppStore`, Product › Archive,
   Distribute App › App Store Connect, then submit in App Store Connect with the IAPs attached.
