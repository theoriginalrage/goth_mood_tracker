#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/release.sh patch
#   scripts/release.sh minor
#   scripts/release.sh major
# Env:
#   DRY_RUN=1   # preview without making changes

BUMP="${1:-patch}"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

say() { printf "🔧 %s\n" "$*"; }
run() { if [[ "${DRY_RUN:-}" = "1" ]]; then printf "DRY: %q " "$1"; shift || true; printf "%q " "$@"; printf "\n"; else "$@"; fi; }

# --- prechecks ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not a git repo."; exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Working tree not clean. Commit or stash changes first."; exit 1
fi

# --- read version line from pubspec.yaml ---
LINE="$(grep -E '^version:' pubspec.yaml | head -1 | sed 's/^version:[[:space:]]*//')"
if [[ -z "$LINE" ]]; then
  echo "❌ Could not read version from pubspec.yaml"; exit 1
fi
# LINE is like "1.0.0" or "1.0.0+12"
BASE="${LINE%%+*}"
if [[ "$LINE" == *"+"* ]]; then
  BUILD="${LINE##*+}"
else
  BUILD="0"
fi
# sanitize BUILD
if ! [[ "$BUILD" =~ ^[0-9]+$ ]]; then BUILD="0"; fi

IFS='.' read -r MAJ MIN PAT <<< "$BASE"

case "$BUMP" in
  major) MAJ=$((MAJ+1)); MIN=0; PAT=0 ;;
  minor) MIN=$((MIN+1)); PAT=0 ;;
  patch) PAT=$((PAT+1)) ;;
  *) echo "❌ Unknown bump '$BUMP' (use patch|minor|major)"; exit 1 ;;
esac

NEW="${MAJ}.${MIN}.${PAT}"
BUILD=$((BUILD+1))

say "Bumping version: ${BASE}${LINE/*+/+${BUILD-?}} -> ${NEW}+${BUILD}"

# --- update pubspec.yaml (portable sed) ---
# GNU sed: -i, BSD/macOS sed: -i ''
if sed --version >/dev/null 2>&1; then
  run sed -i "s/^version:.*/version: ${NEW}+${BUILD}/" pubspec.yaml
else
  run sed -i '' "s/^version:.*/version: ${NEW}+${BUILD}/" pubspec.yaml
fi

# --- commit + tag + push ---
run git add pubspec.yaml
run git commit -m "chore(release): ${NEW}+${BUILD}"
run git tag -a "v${NEW}" -m "Release ${NEW}"
run git push origin "$BRANCH"
run git push origin "v${NEW}"

say "✅ Released v${NEW} (pubspec ${NEW}+${BUILD})"

