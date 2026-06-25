#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d ios ]]; then
  echo "iOS project directory not found: $ROOT_DIR/ios" >&2
  echo "Run 'flutter create --platforms=ios .' before building iOS." >&2
  exit 1
fi

BUILD_MODE="${BUILD_MODE:-release}"
API_BASE_URL="${API_BASE_URL:-}"
TARGET="${TARGET:-lib/main.dart}"
OUTPUT_TYPE="${OUTPUT_TYPE:-ipa}"
CODESIGN_FLAG="${CODESIGN_FLAG:-}"

codesign_args=()
if [[ -n "$CODESIGN_FLAG" ]]; then
  codesign_args+=("$CODESIGN_FLAG")
fi

defines=(--dart-define=APP_ENV=prod)
if [[ -n "$API_BASE_URL" ]]; then
  defines+=(--dart-define="API_BASE_URL=$API_BASE_URL")
fi

case "$OUTPUT_TYPE" in
  ipa|ios) ;;
  *)
    echo "Unsupported OUTPUT_TYPE '$OUTPUT_TYPE'. Use 'ipa' or 'ios'." >&2
    exit 1
    ;;
esac

flutter pub get
flutter build "$OUTPUT_TYPE" --"$BUILD_MODE" --target "$TARGET" "${codesign_args[@]}" "${defines[@]}" "$@"
