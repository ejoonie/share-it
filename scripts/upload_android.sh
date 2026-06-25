#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v fastlane >/dev/null 2>&1; then
  echo "fastlane is required to upload Android artifacts." >&2
  echo "Install fastlane, then rerun this script." >&2
  exit 1
fi

ARTIFACT_PATH="${ANDROID_ARTIFACT_PATH:-build/app/outputs/bundle/release/app-release.aab}"
PACKAGE_NAME="${ANDROID_PACKAGE_NAME:-}"
GOOGLE_PLAY_JSON_KEY="${GOOGLE_PLAY_JSON_KEY:-}"
GOOGLE_PLAY_TRACK="${GOOGLE_PLAY_TRACK:-internal}"
RELEASE_STATUS="${GOOGLE_PLAY_RELEASE_STATUS:-draft}"

if [[ -z "$PACKAGE_NAME" ]]; then
  echo "ANDROID_PACKAGE_NAME is required, for example com.example.share_it." >&2
  exit 1
fi

if [[ -z "$GOOGLE_PLAY_JSON_KEY" ]]; then
  echo "GOOGLE_PLAY_JSON_KEY is required and must point to a Google Play service account JSON file." >&2
  exit 1
fi

if [[ ! -f "$GOOGLE_PLAY_JSON_KEY" ]]; then
  echo "Google Play JSON key file not found: $GOOGLE_PLAY_JSON_KEY" >&2
  exit 1
fi

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "Android artifact not found: $ARTIFACT_PATH" >&2
  echo "Build one first, for example: OUTPUT_TYPE=appbundle scripts/build_aos.sh" >&2
  exit 1
fi

case "$ARTIFACT_PATH" in
  *.aab)
    artifact_args=(--aab "$ARTIFACT_PATH")
    ;;
  *.apk)
    artifact_args=(--apk "$ARTIFACT_PATH")
    ;;
  *)
    echo "Unsupported Android artifact '$ARTIFACT_PATH'. Use an .aab or .apk file." >&2
    exit 1
    ;;
esac

fastlane supply \
  --package_name "$PACKAGE_NAME" \
  --json_key "$GOOGLE_PLAY_JSON_KEY" \
  --track "$GOOGLE_PLAY_TRACK" \
  --release_status "$RELEASE_STATUS" \
  "${artifact_args[@]}" \
  "$@"
