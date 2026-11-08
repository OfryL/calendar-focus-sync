#!/usr/bin/env bash
# Submits an .app, .dmg, .pkg or .zip to Apple's notary service, waits for
# the verdict, prints the log on failure and staples the ticket on success.
#
# Usage: notarize.sh PATH
#
# Environment:
#   APP_STORE_CONNECT_API_KEY_PATH  path to the .p8 private key
#   APP_STORE_CONNECT_API_KEY_ID    key ID (10 characters)
#   APP_STORE_CONNECT_API_ISSUER_ID issuer UUID
set -euo pipefail

TARGET="${1:?path to notarize}"
: "${APP_STORE_CONNECT_API_KEY_PATH:?}" "${APP_STORE_CONNECT_API_KEY_ID:?}" "${APP_STORE_CONNECT_API_ISSUER_ID:?}"

TMP="${RUNNER_TEMP:-$(mktemp -d)}"
SUBMISSION="$TARGET"

# notarytool accepts dmg/pkg/zip; an .app bundle has to be zipped first.
if [[ "$TARGET" == *.app ]]; then
  SUBMISSION="$TMP/$(basename "$TARGET" .app).zip"
  ditto -c -k --keepParent "$TARGET" "$SUBMISSION"
fi

echo "Submitting $(basename "$SUBMISSION") for notarization..."
RESULT="$TMP/notarization.json"
xcrun notarytool submit "$SUBMISSION" \
  --key "$APP_STORE_CONNECT_API_KEY_PATH" \
  --key-id "$APP_STORE_CONNECT_API_KEY_ID" \
  --issuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
  --wait --timeout 45m \
  --output-format json > "$RESULT"

STATUS=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["status"])' "$RESULT")
ID=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["id"])' "$RESULT")
echo "Notarization $ID: $STATUS"

if [[ "$STATUS" != "Accepted" ]]; then
  echo "::error::Notarization failed ($STATUS). Log:" >&2
  xcrun notarytool log "$ID" \
    --key "$APP_STORE_CONNECT_API_KEY_PATH" \
    --key-id "$APP_STORE_CONNECT_API_KEY_ID" \
    --issuer "$APP_STORE_CONNECT_API_ISSUER_ID" >&2 || true
  exit 1
fi

xcrun stapler staple "$TARGET"
xcrun stapler validate "$TARGET"
