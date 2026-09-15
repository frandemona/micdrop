#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SET="$ROOT/MicDrop/Resources/Assets.xcassets/AppIcon.appiconset"
swift "$ROOT/scripts/make-icon.swift" "$SET/icon-1024.png"
for size in 16 32 64 128 256 512; do
  sips -z "$size" "$size" "$SET/icon-1024.png" --out "$SET/icon-$size.png" >/dev/null
done
cat > "$SET/Contents.json" <<'EOF'
{
  "images" : [
    { "filename" : "icon-16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon-32.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon-32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon-64.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon-128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon-256.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon-256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon-512.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon-512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon-1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
echo "Icon written to $SET"
