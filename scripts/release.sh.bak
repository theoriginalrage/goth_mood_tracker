#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/release.sh patch apk
#   ./scripts/release.sh minor aab
#   ./scripts/release.sh patch both
#   ./scripts/release.sh patch        # defaults to 'both'

BUMP="${1:-patch}"
TARGET="${2:-both}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

PUBSPEC="pubspec.yaml"

# --- sanity checks ---
if ! git diff --quiet; then
  echo "✋ Commit or stash your changes before releasing."
  exit 1
fi

if [[ ! -f "$PUBSPEC" ]]; then
  echo "pubspec.yaml not found. Run from project root."
  exit 1
fi

# --- read current version (X.Y.Z[+N]) ---
CURR_LINE=$(grep -E '^version:\s*[0-9]+\.[0-9]+\.[0-9]+' "$PUBSPEC" | head -n1)
CURR_VER=$(echo "$CURR_LINE" | awk '{print $2}')
BASE=${CURR_VER%%+*}
MAJOR=$(echo "$BASE" | awk -F. '{print $1}')
MINOR=$(echo "$BASE" | awk -F. '{print $2}')
PATCH=$(echo "$BASE" | awk -F. '{print $3}')

case "$BUMP" in
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  patch) PATCH=$((PATCH+1)) ;;
  *) echo "Unknown bump: $BUMP (use major|minor|patch)"; exit 1 ;;
esac

NEW_BASE="${MAJOR}.${MINOR}.${PATCH}"

# --- build number from git commits ---
BUILD_NUM=$(git rev-list --count HEAD)

# --- write pubspec version ---
sed -i "s/^version: .*/version: ${NEW_BASE}+${BUILD_NUM}/" "$PUBSPEC"

# --- commit & tag ---
git add "$PUBSPEC"
git commit -m "chore: release ${NEW_BASE}+${BUILD_NUM}"
git tag -a "v${NEW_BASE}" -m "Release ${NEW_BASE}"

# --- refresh deps & build ---
flutter clean
flutter pub get

case "$TARGET" in
  apk)
    flutter build apk --release
    echo "✅ APK: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  aab)
    flutter build appbundle --release
    echo "✅ AAB: build/app/outputs/bundle/release/app-release.aab"
    ;;
  both)
    flutter build apk --release
    flutter build appbundle --release
    echo "✅ APK: build/app/outputs/flutter-apk/app-release.apk"
    echo "✅ AAB: build/app/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo "Unknown target: $TARGET (use apk|aab|both)"
    exit 1
    ;;
esac

echo
echo "🎯 Release ${NEW_BASE}+${BUILD_NUM} built and tagged as v${NEW_BASE}"
echo "👉 Push it: git push && git push --tags"
