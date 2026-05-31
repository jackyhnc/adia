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

cd "$ROOT"

# Local/demo builds read ~/.adia/openai_key at runtime. Embedding a model key in a
# client app is extractable, so require an explicit opt-in for private demos only.
KEYFILE="${ADIA_EMBED_KEY_FILE:-$HOME/.adia/openai_key}"
SECRETS="$ROOT/Sources/AdiCore/Secrets.swift"
if [ "${ADIA_EMBED_AGENT_KEY:-0}" = "1" ] && [ -f "$KEYFILE" ] && [ -f "$SECRETS" ]; then
  echo "→ embedding demo API key from $KEYFILE"
  EMBED_KEY="$(tr -d '\n' < "$KEYFILE")" python3 - "$SECRETS" <<'PY'
import os, re, sys
p = sys.argv[1]
key = os.environ["EMBED_KEY"]
s = open(p).read()
s = re.sub(r'public static let apiKey = ".*?"',
           'public static let apiKey = "%s"' % key, s, count=1)
open(p, "w").write(s)
PY
else
  python3 - "$SECRETS" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'public static let apiKey = ".*?"',
           'public static let apiKey = ""', s, count=1)
open(p, "w").write(s)
PY
fi

echo "→ swift build -c $CONFIG --arch $ARCH"
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
  <key>LSUIElement</key><false/>
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

# Code-sign so macOS treats it as a valid app and TCC (Screen Recording) can
# attach a grant. Prefer a STABLE identity (self-signed for local demos, or a
# real Developer ID for distribution): TCC keys the Screen Recording grant to
# the signing identity, so a stable identity means the user grants permission
# ONCE and it survives rebuilds/quits. Ad-hoc signing has no stable identity,
# so macOS revokes the grant every time the app quits or is rebuilt.
#
# Create the local self-signed identity once with: scripts/create-signing-cert.sh
SIGN_IDENTITY="${ADIA_SIGN_IDENTITY:-Adia Demo Self-Signed}"
# NOTE: no `-v` — a self-signed cert is untrusted by Gatekeeper, so `-v` (valid
# only) would hide it even though codesign can sign with it just fine.
if security find-identity -p codesigning 2>/dev/null | grep -qF "$SIGN_IDENTITY"; then
  echo "→ signing with stable identity: $SIGN_IDENTITY"
  codesign --force --deep --sign "$SIGN_IDENTITY" "$APP" >/dev/null 2>&1 \
    || echo "  (codesign failed — continuing unsigned)"
else
  echo "→ ad-hoc signing (no stable identity found)"
  echo "  ⚠ Screen Recording grant will NOT persist across rebuilds/quits."
  echo "    Run scripts/create-signing-cert.sh once to fix this for demos."
  codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "  (codesign failed — continuing unsigned)"
fi

echo "✓ built $APP ($VERSION build $BUILD)"
