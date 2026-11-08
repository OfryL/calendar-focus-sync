#!/usr/bin/env bash
# Installs a base64-encoded macOS provisioning profile where Xcode looks for
# it, and exports its UUID and Name to $GITHUB_OUTPUT / $GITHUB_ENV.
#
# Usage: install-provisioning-profile.sh ENV_VAR_NAME
set -euo pipefail

VAR="${1:?name of the env var holding the base64 profile}"
if [[ -z "${!VAR:-}" ]]; then
  echo "::error::$VAR is empty; add it as a repository secret (base64 of the .provisionprofile)" >&2
  exit 1
fi

TMP="${RUNNER_TEMP:-$(mktemp -d)}"
PROFILE="$TMP/profile.provisionprofile"
echo "${!VAR}" | base64 --decode > "$PROFILE"

PLIST="$TMP/profile.plist"
security cms -D -i "$PROFILE" > "$PLIST"
UUID=$(/usr/libexec/PlistBuddy -c 'Print UUID' "$PLIST")
NAME=$(/usr/libexec/PlistBuddy -c 'Print Name' "$PLIST")
APP_ID=$(/usr/libexec/PlistBuddy -c 'Print Entitlements:com.apple.application-identifier' "$PLIST")

# Xcode 16+ reads from the Developer folder; older tools read MobileDevice.
for dir in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" \
           "$HOME/Library/MobileDevice/Provisioning Profiles"; do
  mkdir -p "$dir"
  cp "$PROFILE" "$dir/$UUID.provisionprofile"
done

echo "Installed profile '$NAME' ($UUID) for $APP_ID"
{
  echo "uuid=$UUID"
  echo "name=$NAME"
} >> "${GITHUB_OUTPUT:-/dev/null}"
{
  echo "PROVISIONING_PROFILE_UUID=$UUID"
  echo "PROVISIONING_PROFILE_NAME=$NAME"
} >> "${GITHUB_ENV:-/dev/null}"
