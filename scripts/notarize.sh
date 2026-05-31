#!/usr/bin/env bash
# Notarize the signed app, then staple the ticket.
# Required env: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD (app-specific password).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Adia.app}"
ZIP="$ROOT/dist/Adia-notarize.zip"

if [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_TEAM_ID:-}" ] || [ -z "${APPLE_APP_PASSWORD:-}" ]; then
  if [ "${ADIA_ALLOW_UNSIGNED_RELEASE:-0}" != "1" ]; then
    echo "✗ APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD are required for production notarization."
    echo "  Set ADIA_ALLOW_UNSIGNED_RELEASE=1 only for local/private test builds."
    exit 1
  fi
  echo "⚠ Skipping notarization for local build."
  echo "  Users will see 'unidentified developer'. Do not ship this artifact."
  exit 0
fi

echo "→ zipping $APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo "→ submitting to notarytool"
xcrun notarytool submit "$ZIP" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

echo "→ stapling"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
rm -f "$ZIP"
echo "✓ notarized + stapled"
