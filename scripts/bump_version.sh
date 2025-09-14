#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/bump_version.sh [major|minor|patch]
# Example: ./scripts/bump_version.sh patch
# Requires: git, awk, sed, grep

BUMP="${1:-patch}"

cd "$(git rev-parse --show-toplevel)"

if ! git diff --quiet; then
  echo "✋ Commit or stash your changes before bumping."
  exit 1
fi

PUBSPEC="pubspec.yaml"

# Read current version from pubspec: e.g., 0.1.0+7
CURR_LINE=$(grep -E '^version:\s*[0-9]+\.[0-9]+\.[0-9]+' "$PUBSPEC" | head -n1)
CURR_VER=$(echo "$CURR_LINE" | awk '{print $2}')         # 0.1.0+7
BASE_VER=${CURR_VER%%+*}                                 # 0.1.0
MAJOR=$(echo "$BASE_VER" | awk -F. '{print $1}')
MINOR=$(echo "$BASE_VER" | awk -F. '{print $2}')
PATCH=$(echo "$BASE_VER" | awk -F. '{print $3}')

case "$BUMP" in
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  patch) PATCH=$((PATCH+1)) ;;
  *) echo "Unknown bump: $BUMP (use major|minor|patch)"; exit 1 ;;
esac

NEW_BASE="${MAJOR}.${MINOR}.${PATCH}"

# Build number from total commits (monotonic across repo)
BUILD_NUM=$(git rev-list --count HEAD)

# Replace version line in pubspec
sed -i "s/^version: .*/version: ${NEW_BASE}+${BUILD_NUM}/" "$PUBSPEC"

# Commit + tag
git add "$PUBSPEC"
git commit -m "chore: bump version to ${NEW_BASE}+${BUILD_NUM}"
git tag -a "v${NEW_BASE}" -m "Release ${NEW_BASE}"
echo "✅ Bumped to ${NEW_BASE}+${BUILD_NUM} and tagged v${NEW_BASE}"
echo "Push with: git push && git push --tags"
