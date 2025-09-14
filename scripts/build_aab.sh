#!/usr/bin/env bash
set -euo pipefail

./scripts/set_build_from_git.sh
flutter clean
flutter pub get
flutter build appbundle --release  # build Play Store bundle

echo "✅ Built: build/app/outputs/bundle/release/app-release.aab"
