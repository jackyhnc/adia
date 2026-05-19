#!/usr/bin/env bash
# Code-sign Adia.app with your Developer ID Application certificate.
# Required env: DEVELOPER_ID_APPLICATION (e.g. "Developer ID Application: Jane Doe (TEAM123ABC)")
# Optional env: APP_PATH (default: dist/Adia.app)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Adia.app}"
ENTITLEMENTS="$ROOT/Resources/Adia.entitlements"
ID="${DEVELOPER_ID_APPLICATION:-}"

if [ -z "$ID" ]; then
  echo "⚠ DEVELOPER_ID_APPLICATION not set — producing an ad-hoc signed build."
  echo "  Users will see Gatekeeper warnings. Set DEVELOPER_ID_APPLICATION for a real ship."
  codesign --force --options runtime --timestamp=none \
    --entitlements "$ENTITLEMENTS" \
    --sign "-" "$APP"
  exit 0
fi

test -f "$ENTITLEMENTS" || { echo "missing $ENTITLEMENTS"; exit 1; }

echo "→ signing $APP with $ID"
codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$ID" \
  "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
echo "✓ signed"
