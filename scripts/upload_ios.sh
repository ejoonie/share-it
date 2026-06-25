#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v fastlane >/dev/null 2>&1; then
  echo "fastlane is required to upload iOS artifacts." >&2
  echo "Install fastlane on macOS, then rerun this script." >&2
  exit 1
fi

API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-}"
APP_IDENTIFIER="${IOS_APP_IDENTIFIER:-}"
IPA_PATH="${IOS_ARTIFACT_PATH:-}"

if [[ -z "$API_KEY_PATH" ]]; then
  echo "APP_STORE_CONNECT_API_KEY_PATH is required and must point to a fastlane App Store Connect API key JSON file." >&2
  exit 1
fi

if [[ ! -f "$API_KEY_PATH" ]]; then
  echo "App Store Connect API key file not found: $API_KEY_PATH" >&2
  exit 1
fi

if [[ -z "$APP_IDENTIFIER" ]]; then
  echo "IOS_APP_IDENTIFIER is required, for example com.example.shareIt." >&2
  exit 1
fi

if [[ -z "$IPA_PATH" ]]; then
  shopt -s nullglob
  ipa_files=(build/ios/ipa/*.ipa)
  shopt -u nullglob
  if (( ${#ipa_files[@]} == 1 )); then
    IPA_PATH="${ipa_files[0]}"
  else
    echo "IOS_ARTIFACT_PATH is required when exactly one build/ios/ipa/*.ipa file cannot be found." >&2
    echo "Build one first with a signed iOS archive, for example: scripts/build_ios.sh" >&2
    exit 1
  fi
fi

if [[ ! -f "$IPA_PATH" ]]; then
  echo "iOS IPA not found: $IPA_PATH" >&2
  exit 1
fi

fastlane pilot upload \
  --ipa "$IPA_PATH" \
  --api_key_path "$API_KEY_PATH" \
  --app_identifier "$APP_IDENTIFIER" \
  "$@"
