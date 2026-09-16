#!/usr/bin/env bash
# Renders App Store screenshots from the real UI and collects them in build/screenshots.
# The test host is sandboxed, so it writes into its container; this copies them out.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodegen generate >/dev/null
TEST_RUNNER_MICDROP_SCREENSHOTS=1 xcodebuild test \
  -project MicDrop.xcodeproj -scheme MicDrop \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/direct \
  -only-testing:MicDropTests/ScreenshotGenerator >/dev/null

CONTAINER="$HOME/Library/Containers/ro.zereb.MicDrop/Data/tmp/micdrop-screenshots"
if [ ! -d "$CONTAINER" ]; then
  echo "error: no screenshots at $CONTAINER — did the generator run?" >&2
  exit 1
fi

OUT="$ROOT/build/screenshots"
rm -rf "$OUT" && mkdir -p "$OUT"
cp "$CONTAINER"/*.png "$OUT"/
echo "Screenshots in $OUT:"
for file in "$OUT"/*.png; do
  printf '  %s  %s\n' "$(basename "$file")" "$(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixel/ {printf "%s ", $2}')"
done
