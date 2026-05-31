#!/usr/bin/env bash
# Create a self-signed code-signing identity for LOCAL/DEMO builds.
#
# Why: macOS TCC (Screen Recording) keys a grant to the app's code-signing
# identity. Ad-hoc signing (`codesign --sign -`) has no stable identity, so the
# grant is revoked every time the app quits or is rebuilt. A self-signed cert
# gives Adia a stable "designated requirement", so you grant Screen Recording
# ONCE and it sticks across rebuilds and relaunches.
#
# This is for local demos only. It is NOT trusted by Gatekeeper and must never
# be used to distribute the app — ship with a real Developer ID / App Store cert.
#
# Run once:  bash scripts/create-signing-cert.sh
# You will be prompted for your macOS login password (for the keychain step).
set -euo pipefail

IDENTITY="${ADIA_SIGN_IDENTITY:-Adia Demo Self-Signed}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

# No `-v`: a self-signed cert is untrusted, so `-v` (valid only) hides it and the
# guard would wrongly re-create a duplicate. Plain listing finds it.
if security find-identity -p codesigning 2>/dev/null | grep -qF "$IDENTITY"; then
  echo "✓ identity \"$IDENTITY\" already exists — nothing to do."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ generating self-signed code-signing certificate ($IDENTITY)"
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -days 3650 \
  -subj "/CN=$IDENTITY" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" >/dev/null 2>&1

# OpenSSL 3 defaults to a MAC/cipher that macOS's keychain can't verify
# ("MAC verification failed during PKCS12 import"). Use legacy SHA1/3DES, which
# the macOS Security framework reads. `-legacy` exists on OpenSSL 3; older
# OpenSSL/LibreSSL reject the flag, so fall back without it.
if ! openssl pkcs12 -export -legacy -macalg sha1 \
      -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES \
      -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
      -out "$TMP/adia.p12" -passout pass:adia -name "$IDENTITY" >/dev/null 2>&1; then
  openssl pkcs12 -export -macalg sha1 \
    -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES \
    -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -out "$TMP/adia.p12" -passout pass:adia -name "$IDENTITY" >/dev/null 2>&1
fi

echo "→ importing into login keychain (allowing codesign to use the key)"
security import "$TMP/adia.p12" -k "$KEYCHAIN" -P adia \
  -T /usr/bin/codesign -T /usr/bin/security >/dev/null

echo "→ authorizing codesign to use the key without prompting"
echo "  (enter your macOS login password if asked)"
security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN" >/dev/null 2>&1 \
  || security set-key-partition-list -S apple-tool:,apple: -s "$KEYCHAIN" >/dev/null

echo
echo "✓ created \"$IDENTITY\". Verifying:"
security find-identity -p codesigning | grep -F "$IDENTITY" || {
  echo "✗ identity not found in codesigning policy — check the output above."
  exit 1
}
echo "  (CSSMERR_TP_NOT_TRUSTED is expected & fine — self-signed certs aren't"
echo "   Gatekeeper-trusted, but codesign signs with them and TCC honors them.)"
echo
echo "Next: ./scripts/build-app.sh   (it will now sign with this identity)"
