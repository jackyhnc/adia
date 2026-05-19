#!/usr/bin/env bash
# Build a runnable Adia.app bundle from the Swift Package.
# Outputs dist/Adia.app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/Adia.app"
CONFIG="${CONFIG:-release}"
ARCH="${ARCH:-arm64}"
VERSION="${VERSION:-0.1.0}"
BUILD="${BUILD:-$(date +%y%m%d%H%M)}"

echo "→ swift build -c $CONFIG --arch $ARCH"
cd "$ROOT"
swift build -c "$CONFIG" --arch "$ARCH" >/dev/null

BIN="$ROOT/.build/$ARCH-apple-macosx/$CONFIG/Adia"
test -x "$BIN" || { echo "binary missing: $BIN"; exit 1; }

echo "→ assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Adia"

# Info.plist
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Adia</string>
  <key>CFBundleDisplayName</key><string>Adia</string>
  <key>CFBundleIdentifier</key><string>app.adia.Adia</string>
  <key>CFBundleExecutable</key><string>Adia</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleSignature</key><string>????</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026 Adia</string>
  <key>NSScreenCaptureUsageDescription</key>
    <string>Adia watches your screen to keep you on task and verify completion.</string>
  <key>NSAppleEventsUsageDescription</key>
    <string>Adia uses AppleEvents only to query the frontmost app for context.</string>
</dict>
</plist>
PLIST

# Optional icon
if [ -f "$ROOT/assets/AppIcon.icns" ]; then
  cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

echo "✓ built $APP ($VERSION build $BUILD)"
