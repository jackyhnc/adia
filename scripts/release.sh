#!/usr/bin/env bash
# Orchestrator: build → sign → notarize → DMG. Outputs dist/Adia-<version>.dmg.
# Usage: VERSION=0.2.0 scripts/release.sh
set -euo pipefail
HERE="$(dirname "$0")"

"$HERE/build-app.sh"
"$HERE/sign.sh"
"$HERE/notarize.sh"
"$HERE/build-dmg.sh"

echo
echo "→ done. uploadable artifacts in dist/:"
ls -lh dist/*.dmg* 2>/dev/null || true
