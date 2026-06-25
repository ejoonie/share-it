#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d android ]]; then
  echo "Android project directory not found: $ROOT_DIR/android" >&2
  echo "Run 'flutter create --platforms=android .' before building Android." >&2
  exit 1
fi

BUILD_MODE="${BUILD_MODE:-release}"
API_BASE_URL="${API_BASE_URL:-}"
TARGET="${TARGET:-lib/main.dart}"
OUTPUT_TYPE="${OUTPUT_TYPE:-apk}"

defines=(--dart-define=APP_ENV=prod)
if [[ -n "$API_BASE_URL" ]]; then
  defines+=(--dart-define="API_BASE_URL=$API_BASE_URL")
fi

case "$OUTPUT_TYPE" in
  apk|appbundle) ;;
  *)
    echo "Unsupported OUTPUT_TYPE '$OUTPUT_TYPE'. Use 'apk' or 'appbundle'." >&2
    exit 1
    ;;
esac

flutter pub get
flutter build "$OUTPUT_TYPE" --"$BUILD_MODE" --target "$TARGET" "${defines[@]}" "$@"
