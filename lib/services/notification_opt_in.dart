import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../providers/session_provider.dart';

/// Share 탭 최초 진입 시 띄우는 인앱 알림 opt-in 흐름을 처리한다.
///
/// 이슈 #130:
///   - OS 알림 권한의 허용/거부 결과로는 아무것도 게이팅하지 않는다.
///     (다만 iOS는 네이티브 remote-notification 등록을 트리거해야 APNs
///     토큰이 내려오므로 `requestPermission()` 자체는 호출한다 — 결과는
///     쓰지 않는다.)
///   - "허용" → FCM 토큰을 서버에 등록한다. users.notifications_enabled 는
///     기본값(true)이므로 별도 서버 호출은 없다.
///   - "나중에" → 서버의 users.notifications_enabled 를 false 로 내린다.
class NotificationOptIn {
  final Ref _ref;

  NotificationOptIn(this._ref);

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// opt-in 다이얼로그에서 "허용"을 눌렀을 때, 그리고 앱 시작 시 이미
  /// 허용한 기기에서 토큰을 갱신할 때 호출한다.
  Future<void> enable() async {
    await _ensureRegisteredForRemoteNotifications();
    await _registerToken();
  }

  /// iOS 네이티브 remote-notification 등록(registerForRemoteNotifications)을
  /// 트리거한다. 이걸 안 부르면 APNs 토큰이 내려오지 않아 `getToken()`이
  /// 계속 null이 된다 — `requestPermission()`이 내부적으로 그 등록까지 해준다.
  /// 허용/거부 결과는 쓰지 않으며(이슈 #130), 이미 권한이 결정된 상태면
  /// 다이얼로그 없이 즉시 반환된다.
  Future<void> _ensureRegisteredForRemoteNotifications() async {
    if (!Platform.isIOS) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (error) {
      debugPrint('[push] requestPermission failed: $error');
    }
  }

  /// opt-in 다이얼로그에서 "나중에"를 눌렀을 때.
  Future<void> decline() async {
    try {
      await _ref
          .read(sessionRepositoryProvider)
          .updateNotificationsEnabled(false);
    } catch (error) {
      debugPrint('[push] Failed to disable notifications on server: $error');
    }
  }

  /// 앱 실행 중 FCM 토큰이 재발급되면 다시 등록한다.
  Future<void> handleTokenRefresh(String token) => _registerToken(token);

  /// 로그아웃/회원탈퇴 시 호출 — 아직 인증 토큰이 살아있을 때 이 기기의
  /// FCM 토큰을 서버에서 해제하고, 다음 사용자를 위해 로컬 opt-in 기록도
  /// 지운다. 실패해도 호출자의 로그아웃 흐름을 막지 않는다.
  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _ref.read(deviceTokenRepositoryProvider).unregister(token);
      }
    } catch (error) {
      debugPrint('[push] Failed to unregister device token: $error');
    }
    await _ref.read(notificationOptInStorageProvider).reset();
  }

  Future<void> _registerToken([String? refreshedToken]) async {
    try {
      final token =
          refreshedToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('[push] FCM token unavailable; skipping registration');
        return;
      }
      await _ref
          .read(deviceTokenRepositoryProvider)
          .register(token: token, platform: _platform);
    } catch (error) {
      debugPrint('[push] Failed to register device token: $error');
    }
  }
}

final notificationOptInProvider = Provider<NotificationOptIn>((ref) {
  return NotificationOptIn(ref);
});
