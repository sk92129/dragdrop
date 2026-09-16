#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Update pods (equivalent to manual script steps 4-6)
rm -rf ios/Pods
rm -rf ios/Podfile.lock
cd ios
rm -rf build

pod repo update
pod install --repo-update
cd "$ROOT_DIR"
#flutter gen-l10n
#dart update_build_number.dart

# Generate localizations
#echo "🌍 Generating localizations..."
#flutter gen-l10n
