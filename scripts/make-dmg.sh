#!/usr/bin/env bash
# Builds a compressed DMG containing the app and an /Applications shortcut,
# using only tools that ship with macOS.
#
# Usage: make-dmg.sh "/path/to/Calendar Focus Sync.app" "/path/to/output.dmg" [SIGNING_IDENTITY]
#   If SIGNING_IDENTITY is given (e.g. "Developer ID Application"), the DMG
#   itself is code signed with a secure timestamp.
set -euo pipefail

APP="${1:?path to .app}"
OUT="${2:?output .dmg path}"
IDENTITY="${3:-}"

[[ -d "$APP" ]] || { echo "No app bundle at $APP" >&2; exit 1; }

APP_NAME="$(basename "$APP" .app)"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

mkdir -p "$(dirname "$OUT")"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -fs HFS+ \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov "$OUT"

if [[ -n "$IDENTITY" ]]; then
  codesign --force --sign "$IDENTITY" --timestamp "$OUT"
  codesign --verify --verbose=2 "$OUT"
fi

echo "Created $OUT"
