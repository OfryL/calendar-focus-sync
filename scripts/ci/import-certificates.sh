#!/usr/bin/env bash
# Imports one or more PKCS#12 signing certificates into a throwaway keychain
# on a CI runner, plus Apple's intermediate CAs so the chains validate.
#
# Usage: import-certificates.sh ENV_VAR_NAME [ENV_VAR_NAME...]
#   Each ENV_VAR_NAME is the name of an environment variable that holds a
#   base64-encoded .p12 file. All of them share the password in P12_PASSWORD.
#
# Environment:
#   P12_PASSWORD        password the .p12 files were exported with (required)
#   KEYCHAIN_PASSWORD   password for the temporary keychain (optional)
#   RUNNER_TEMP         scratch directory (set by GitHub Actions)
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 ENV_VAR_NAME [ENV_VAR_NAME...]" >&2
  exit 2
fi
: "${P12_PASSWORD:?P12_PASSWORD must be set}"

TMP="${RUNNER_TEMP:-$(mktemp -d)}"
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -hex 16)}"
KEYCHAIN="$TMP/signing.keychain-db"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"

# Apple intermediate certificates. Without these, codesign fails with
# "unable to build chain" on a clean runner.
for cer in DeveloperIDG2CA AppleWWDRCAG3 AppleWWDRCAG4; do
  curl -fsSL "https://www.apple.com/certificateauthority/${cer}.cer" -o "$TMP/${cer}.cer"
  security import "$TMP/${cer}.cer" -k "$KEYCHAIN" -T /usr/bin/codesign -T /usr/bin/productbuild >/dev/null
done

# The decoded .p12 files live in RUNNER_TEMP, which GitHub wipes with the job.
for var in "$@"; do
  if [[ -z "${!var:-}" ]]; then
    echo "::error::$var is empty; add it as a repository secret (base64 of the .p12)" >&2
    exit 1
  fi
  echo "${!var}" | base64 --decode > "$TMP/$var.p12"
  security import "$TMP/$var.p12" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN" >/dev/null
  echo "Imported $var"
done

# Let codesign/productbuild use the keys without a UI prompt.
security set-key-partition-list -S apple-tool:,apple:,codesign:,productbuild: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null
security list-keychains -d user -s "$KEYCHAIN" login.keychain-db
security default-keychain -s "$KEYCHAIN"

echo "Available signing identities:"
security find-identity -v -p codesigning "$KEYCHAIN"
security find-identity -v "$KEYCHAIN" | grep -E "Installer|Distribution" || true
