#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:-all}"   # ios | android | all | build | testflight
cd "$(dirname "$0")/.."

# ── 릴리즈 노트 ────────────────────────────────────────────────────────────────
if [ -z "${RELEASE_NOTES:-}" ]; then
  echo ""
  echo "📝  릴리즈 노트를 입력하세요 (스토어에 공개됩니다)."
  echo "    여러 줄 입력 가능 — 완료하면 빈 줄에서 Enter:"
  echo ""
  RELEASE_NOTES=""
  while IFS= read -r line; do
    [ -z "$line" ] && break
    RELEASE_NOTES="${RELEASE_NOTES}${RELEASE_NOTES:+$'\n'}${line}"
  done
  if [ -z "$RELEASE_NOTES" ]; then
    echo "❌  릴리즈 노트가 비어 있습니다. 중단합니다."
    exit 1
  fi
fi
export RELEASE_NOTES

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  릴리즈 노트:"
echo "$RELEASE_NOTES" | sed 's/^/  /'
echo "  플랫폼: $PLATFORM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 이전 빌드 산출물 정리 ──────────────────────────────────────────────────────
clean_artifacts() {
  echo "🧹  이전 빌드 산출물 삭제..."
  find build/ios/ipa          -name "*.ipa" -delete 2>/dev/null || true
  find build/app/outputs      -name "*.aab" -delete 2>/dev/null || true
}

# ── 실행 ───────────────────────────────────────────────────────────────────────
case "$PLATFORM" in
  build)
    clean_artifacts
    bundle exec fastlane build_ios
    bundle exec fastlane build_android
    echo "✅  빌드 완료"
    ;;
  testflight)
    clean_artifacts
    bundle exec fastlane ios testflight
    echo "✅  TestFlight 업로드 완료"
    ;;
  ios)
    clean_artifacts
    bundle exec fastlane ios release
    echo "✅  iOS 배포 완료"
    ;;
  android)
    clean_artifacts
    bundle exec fastlane android release
    echo "✅  Android 배포 완료"
    ;;
  all)
    clean_artifacts
    echo "▶  iOS 빌드 및 배포..."
    bundle exec fastlane ios release
    echo "✅  iOS 완료"
    echo ""
    echo "▶  Android 빌드 및 배포..."
    bundle exec fastlane android release
    echo "✅  Android 완료"
    echo ""
    echo "🎉  양쪽 스토어 배포 완료"
    ;;
  *)
    echo "Usage: $0 [ios|android|all|build|testflight]"
    exit 1
    ;;
esac
