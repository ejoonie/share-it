import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';

/// FCM 디바이스 토큰을 서버에 등록/해제한다. OS 알림 권한이나 서버의
/// notifications_enabled 설정 어느 쪽에도 종속되지 않는다 - 토큰을 구할 수
/// 있으면 무조건 등록하고, 실제 발송 여부는 서버가 별도로 판단한다.
class DeviceTokenSync {
  final Ref _ref;

  DeviceTokenSync(this._ref);

  /// 앱 시작/포그라운드 복귀/토큰 리프레시 시 호출한다.
  Future<void> syncToken([String? refreshedToken]) async {
    if (Platform.isIOS) {
      // permission_handler 등으로 OS 알림 권한만 받으면 UNUserNotificationCenter만
      // 갱신되고 UIApplication.registerForRemoteNotifications()는 안 불려서 APNs
      // 토큰이 영영 안 온다. FirebaseMessaging.requestPermission()이 내부적으로
      // 그 등록까지 트리거해준다 - 이미 권한이 결정된 상태면 다이얼로그 없이
      // 조용히 반환되니 매번 호출해도 안전하고, 결과(허용/거부)는 여기서 쓰지
      // 않는다 - 토큰 등록 자체는 권한 여부와 무관하게 시도한다.
      await FirebaseMessaging.instance.requestPermission();

      // APNs 토큰이 준비될 때까지 짧게 폴링한다 (registerForRemoteNotifications
      // 콜백이 비동기라 바로 다음 줄에서 확인하면 아직 안 왔을 수 있다).
      for (var i = 0; i < 10; i++) {
        if (await FirebaseMessaging.instance.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (await FirebaseMessaging.instance.getAPNSToken() == null) return;
    }

    final token = refreshedToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _ref.read(deviceTokenRepositoryProvider).register(
            token: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
    } catch (error) {
      debugPrint('[push] Failed to register device token: $error');
    }
  }

  /// 로그아웃/회원탈퇴 시 호출 - 이 기기의 FCM 토큰을 서버에서 먼저 해제하고
  /// (아직 인증 토큰이 남아있을 때), FirebaseMessaging.deleteToken()으로 토큰
  /// 자체도 폐기한다. 둘 중 하나가 실패해도 나머지는 계속 진행하고, 호출자의
  /// 로그아웃 흐름 자체를 막지 않도록 예외를 던지지 않는다 - 서버 해제가
  /// 실패해도 deleteToken()이 성공하면 기존 토큰은 무효화되고, 서버에 남은
  /// 레코드는 다음 발송 시 FCM의 UNREGISTERED 응답으로 정리된다.
  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _ref.read(deviceTokenRepositoryProvider).unregister(token);
      }
    } catch (error) {
      debugPrint('[push] Failed to unregister device token on server: $error');
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('[push] Failed to delete local FCM token: $error');
    }
  }
}

final deviceTokenSyncProvider = Provider<DeviceTokenSync>((ref) {
  return DeviceTokenSync(ref);
});
