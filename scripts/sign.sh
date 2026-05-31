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
  if [ "${ADIA_ALLOW_UNSIGNED_RELEASE:-0}" != "1" ]; then
    echo "✗ DEVELOPER_ID_APPLICATION is required for production signing."
    echo "  Set ADIA_ALLOW_UNSIGNED_RELEASE=1 only for local/private test builds."
    exit 1
  fi
  echo "⚠ DEVELOPER_ID_APPLICATION not set — producing an ad-hoc signed local build."
  echo "  Users will see Gatekeeper warnings. Do not ship this artifact."
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
