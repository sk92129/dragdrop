#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Build Android APK (debug)
echo "🔨 Building Android APK (debug)..."
flutter build apk --debug --dart-define-from-file=env/dev.json
