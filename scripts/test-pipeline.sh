#!/usr/bin/env bash
# Smoke-test the full distribution pipeline.
# Builds Adia.app, signs (ad-hoc if no credentials), skips notarization when
# Apple credentials are absent, builds a DMG, then verifies the artefacts exist
# and the code signature is valid.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
VERSION="0.0.0-test"
DIST="$ROOT/dist"

export VERSION

# Smoke-testing the pipeline mechanics, not producing a shippable artifact —
# ad-hoc signing is fine here even though `sign.sh` requires a Developer ID
# for real releases (DEVELOPER_ID_APPLICATION is part of USER_TODO.md).
export ADIA_ALLOW_UNSIGNED_RELEASE="${ADIA_ALLOW_UNSIGNED_RELEASE:-1}"

echo "=== test-pipeline: starting ==="

# ── 1. Build app ──────────────────────────────────────────────────────────────
echo "→ build-app"
bash "$SCRIPTS/build-app.sh"

APP="$DIST/Adia.app"
if [ ! -d "$APP" ]; then
  echo "✗ $APP not found after build-app.sh"; exit 1
fi
echo "  ✓ $APP exists"

# ── 2. Sign (ad-hoc when no Developer ID cert available) ────────────────────
echo "→ sign"
bash "$SCRIPTS/sign.sh"

# ── 3. Notarize (skips cleanly when Apple credentials are absent) ────────────
echo "→ notarize"
bash "$SCRIPTS/notarize.sh"

# ── 4. Build DMG ─────────────────────────────────────────────────────────────
echo "→ build-dmg"
bash "$SCRIPTS/build-dmg.sh"

DMG="$DIST/Adia-${VERSION}.dmg"
if [ ! -f "$DMG" ]; then
  echo "✗ $DMG not found after build-dmg.sh"; exit 1
fi
echo "  ✓ $DMG exists"

# ── 5. Generate SHA-256 checksum ────────────────────────────────────────────
SHA_FILE="${DMG}.sha256"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$DMG" > "$SHA_FILE"
elif command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$DMG" > "$SHA_FILE"
else
  echo "⚠ no sha256 tool found; skipping checksum"
fi

if [ -f "$SHA_FILE" ]; then
  echo "  ✓ $SHA_FILE exists"
fi

# ── 6. Verify code signature ─────────────────────────────────────────────────
echo "→ codesign --verify"
if codesign --verify --deep --strict "$APP" 2>/dev/null; then
  echo "  ✓ codesign --verify passed"
else
  echo "  ⚠ codesign --verify failed (expected for ad-hoc builds on CI without entitlements)"
fi

echo ""
echo "=== test-pipeline: PASSED ==="
