#!/usr/bin/env bash
# Sets the marketing version and bumps the build number in Config/Shared.xcconfig.
#
# Usage: scripts/bump-version.sh 0.8.0
set -euo pipefail

VERSION="${1:?new marketing version, e.g. 0.8.0}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo "Version must look like 1.2 or 1.2.3" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCCONFIG="$ROOT/Config/Shared.xcconfig"

BUILD=$(sed -n 's/^CURRENT_PROJECT_VERSION = \([0-9]*\)$/\1/p' "$XCCONFIG")
NEW_BUILD=$((BUILD + 1))

sed -i '' \
  -e "s/^MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION/" \
  -e "s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $NEW_BUILD/" \
  "$XCCONFIG"

echo "Version $VERSION (build $NEW_BUILD)"
echo "Next: add a '## $VERSION' section to CHANGELOG.md, commit, then: git tag v$VERSION && git push --tags"
