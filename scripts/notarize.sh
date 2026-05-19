#!/usr/bin/env bash
# Notarize the signed app, then staple the ticket.
# Required env: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD (app-specific password).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Adia.app}"
ZIP="$ROOT/dist/Adia-notarize.zip"

if [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_TEAM_ID:-}" ] || [ -z "${APPLE_APP_PASSWORD:-}" ]; then
  echo "⚠ Skipping notarization — APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD not set."
  echo "  The DMG will still build, but users will see 'unidentified developer' on first open."
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
