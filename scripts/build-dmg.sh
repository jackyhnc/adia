#!/usr/bin/env bash
# Build a DMG installer for the signed/notarized app.
# Output: dist/Adia-<version>.dmg
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Adia.app}"
VERSION="${VERSION:-0.1.0}"
DMG="$ROOT/dist/Adia-${VERSION}.dmg"
STAGE="$ROOT/dist/dmg-stage"

test -d "$APP" || { echo "$APP missing — run build-app.sh first"; exit 1; }

echo "→ staging at $STAGE"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/Adia.app"
ln -s /Applications "$STAGE/Applications"

echo "→ building $DMG"
hdiutil create \
  -volname "Adia" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DMG" >/dev/null

if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
  codesign --sign "$DEVELOPER_ID_APPLICATION" --timestamp "$DMG"
fi

rm -rf "$STAGE"

SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
echo "✓ $DMG"
echo "  sha256: $SHA"
echo "$SHA  $(basename "$DMG")" > "$DMG.sha256"
