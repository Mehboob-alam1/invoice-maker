#!/usr/bin/env bash
# Use Flutter's Dart (not Homebrew dart on PATH) — fixes compileFlutterBuildDebug / analyze crashes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/Users/mac/development/flutter/bin:$PATH"
cd "$ROOT"
flutter pub get
flutter build appbundle --release "$@"
