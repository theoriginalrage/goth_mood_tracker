#!/usr/bin/env bash
set -euo pipefail

PUBSPEC="pubspec.yaml"
BUILD_NUM=$(git rev-list --count HEAD)

# Pull current base X.Y.Z (without +)
CURR_LINE=$(grep -E '^version:\s*[0-9]+\.[0-9]+\.[0-9]+' "$PUBSPEC" | head -n1)
CURR_VER=$(echo "$CURR_LINE" | awk '{print $2}')
BASE_VER=${CURR_VER%%+*}

sed -i "s/^version: .*/version: ${BASE_VER}+${BUILD_NUM}/" "$PUBSPEC"

echo "🔧 Set version to ${BASE_VER}+${BUILD_NUM} in pubspec.yaml"
