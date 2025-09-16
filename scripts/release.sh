#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/release.sh patch
#   scripts/release.sh minor
#   scripts/release.sh major
# Env:
#   DRY_RUN=1   # show what would happen, don’t change anything

BUMP="${1:-patch}"   # default to patch
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# --- helpers ---
say() { printf "🔧 %s\n" "$*"; }
run() { if [[ "${DRY_RUN:-}" = "1" ]]; then printf "DRY: %s\n" "$*"; else eval "$@"; fi; }

# --- prechecks ---
if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ Working tree not clean. Commit or stash changes first."; exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not a git repo."; exit 1
fi

if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
  say "Not on main/master (on '$BRANCH'). Continuing anyway…"
fi

if ! command -v awk >/dev/null || ! command -v sed >/dev/null; then
  echo "❌ Need 'awk' and 'sed' available."; exit 1
fi

# --- read version from pubspec.yaml ---
CURR=$(awk -F ': ' '/^version:/ {print $2}' pubspec.yaml | cut -d'+' -f1)
if [[ -z "${CURR}" ]]; then
  echo "❌ Could not read version from pubspec.yaml"; exit 1
fi

MAJ=$(echo "$CURR" | cut -d. -f1)
MIN=$(echo "$CURR" | cut -d. -f2)
PAT=$(echo "$CURR" | cut -d. -f3)

case "$BUMP" in
  major) MAJ=$((MAJ+1)); MIN=0; PAT=0 ;;
  minor) MIN=$((MIN+1)); PAT=0 ;;
  patch) PAT=$((PAT+1)) ;;
  *) echo "❌ Unknown bump '$BUMP' (use patch|minor|major)"; exit 1 ;;
esac

NEW="$MAJ.$MIN.$PAT"

# --- bump build number +1 (the +N part) ---
BUILD=$(awk -F '[+: ]' '/^version:/ {print $3}' pubspec.yaml || true)
[[ -z "${BUILD:-}" ]] && BUILD=0
BUILD=$((BUILD+1))

say "Bumping version: $CURR -> $NEW (+$BUILD)"

# --- update pubspec.yaml ---
run sed -i "s/^version:.*/version: $NEW+$BUILD/" pubspec.yaml

# --- commit + tag ---
run git add pubspec.yaml
run git commit -m "chore(release): $NEW+$BUILD"
run git tag -a "v$NEW" -m "Release $NEW"

# --- push ---
run git push origin "$BRANCH"
run git push origin "v$NEW"

say "✅ Released v$NEW (pubspec $NEW+$BUILD)"

