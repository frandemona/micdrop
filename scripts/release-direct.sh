#!/usr/bin/env bash
# Builds, notarizes and publishes a direct-download release with a Sparkle appcast.
# Requires: TEAM_ID, NOTARY_PROFILE env vars; gh logged in; `releases` git remote; gh-pages branch on it.
set -euo pipefail
: "${TEAM_ID:?Set TEAM_ID to your Apple Developer Team ID}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE (create with: xcrun notarytool store-credentials)}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if grep -q "example.com/tip-micdrop" MicDrop/Tips/LinkTipsView.swift; then
  echo "error: replace TipConfig.directTipURL with the real tip page before releasing" >&2
  exit 1
fi

VERSION=$(sed -nE 's/^ *MARKETING_VERSION: "(.*)"/\1/p' project.yml | head -1)
OWNER=$(gh api user --jq .login)
OUT="$ROOT/build/release"
DERIVED="$ROOT/build/release-dd"
rm -rf "$OUT" && mkdir -p "$OUT/updates"

xcodegen generate
xcodebuild archive -project MicDrop.xcodeproj -scheme MicDrop -configuration Release \
  -archivePath "$OUT/MicDrop.xcarchive" -derivedDataPath "$DERIVED" DEVELOPMENT_TEAM="$TEAM_ID"

cat > "$OUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
EOF
xcodebuild -exportArchive -archivePath "$OUT/MicDrop.xcarchive" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist"

APP="$OUT/export/MicDrop.app"
ditto -c -k --keepParent "$APP" "$OUT/notarize.zip"
xcrun notarytool submit "$OUT/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"

ZIP_NAME="MicDrop-$VERSION.zip"
ditto -c -k --keepParent "$APP" "$OUT/updates/$ZIP_NAME"

git fetch releases gh-pages
git show releases/gh-pages:appcast.xml > "$OUT/updates/appcast.xml"
GENERATE_APPCAST=$(find "$DERIVED/SourcePackages/artifacts" -name generate_appcast -type f | head -1)
"$GENERATE_APPCAST" --download-url-prefix "https://github.com/$OWNER/micdrop/releases/download/v$VERSION/" "$OUT/updates"

gh release create "v$VERSION" "$OUT/updates/$ZIP_NAME" --repo "$OWNER/micdrop" \
  --title "MicDrop $VERSION" --notes "MicDrop $VERSION"

git worktree add --detach "$ROOT/build/gh-pages" releases/gh-pages
cp "$OUT/updates/appcast.xml" "$ROOT/build/gh-pages/appcast.xml"
git -C "$ROOT/build/gh-pages" add appcast.xml
git -C "$ROOT/build/gh-pages" commit -m "Appcast for v$VERSION"
git -C "$ROOT/build/gh-pages" push releases HEAD:gh-pages
git worktree remove "$ROOT/build/gh-pages"

echo "Released MicDrop $VERSION"
