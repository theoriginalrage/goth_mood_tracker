#!/usr/bin/env bash
set -euo pipefail

./scripts/set_build_from_git.sh    # updates version
flutter clean                      # clear old build junk
flutter pub get                    # fetch dependencies
flutter build apk --release        # build release APK

echo "✅ Built: build/app/outputs/flutter-apk/app-release.apk"
