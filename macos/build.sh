#!/bin/bash
# Build FlipIt.app (macOS) and optionally install to /Applications: ./build.sh [--install]
set -euo pipefail
cd "$(dirname "$0")"
OUT=build
APP="$OUT/FlipIt.app"
rm -rf "$OUT"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -target arm64-apple-macos13.0 -o "$APP/Contents/MacOS/FlipIt" FlipIt.swift -framework AppKit -framework CoreText

cp Resources/HelveticaLTStd-BoldCond.ttf Resources/cs_logo.png "$APP/Contents/Resources/"

# App icon
ICONSET="$OUT/AppIcon.iconset"; mkdir -p "$ICONSET"
swift makeicon.swift "$OUT/icon1024.png" Resources/HelveticaLTStd-BoldCond.ttf
for s in 16 32 128 256 512; do
  sips -z $s $s "$OUT/icon1024.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s*2)); sips -z $d $d "$OUT/icon1024.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET" swift makeicon.swift "$OUT/icon1024.png"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>FlipIt</string>
  <key>CFBundleDisplayName</key><string>FlipIt</string>
  <key>CFBundleIdentifier</key><string>kr.co.projectresearch.flipit</string>
  <key>CFBundleExecutable</key><string>FlipIt</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Based on FlipIt by phaselden (CC license). Logo: Clean &amp; Science.</string>
</dict></plist>
PLIST

ID="${SIGN_ID:-act-peter Local Code Signing}"
if security find-identity -v -p codesigning | grep -q "$ID"; then codesign --force --deep --sign "$ID" "$APP"; else codesign --force --deep --sign - "$APP"; fi
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x FlipIt 2>/dev/null || true
  rm -rf /Applications/FlipIt.app
  cp -R "$APP" /Applications/
  xattr -dr com.apple.quarantine /Applications/FlipIt.app 2>/dev/null || true
  echo "Installed /Applications/FlipIt.app"
fi
