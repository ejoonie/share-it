import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core_providers.dart';
import 'session_provider.dart';

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionNotifier, bool>(
      NotificationPermissionNotifier.new,
    );

class NotificationPermissionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // FCM 토큰이 재발급될 때마다(재설치, 앱 데이터 삭제 등) 다시 등록한다.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (state.valueOrNull == true) _registerDeviceToken(token);
    });
    return (await Permission.notification.status).isGranted;
  }

  /// 앱이 포그라운드로 복귀할 때 OS 권한 상태를 확인하고 서버에 동기화
  Future<void> sync() async {
    final granted = (await Permission.notification.status).isGranted;
    final previous = state.valueOrNull;
    state = AsyncData(granted);
    if (previous != granted) {
      await _updateServer(granted);
    } else if (granted) {
      // 상태는 그대로여도, 토큰이 아직 서버에 등록 안 됐을 수 있으니 확인 차 재시도.
      await _registerDeviceToken();
    }
  }

  /// 시스템 권한 요청 — 결과(granted 여부)를 반환
  Future<bool> request() async {
    final result = await Permission.notification.request();
    final granted = result.isGranted;
    state = AsyncData(granted);
    if (granted) await _updateServer(true);
    return granted;
  }

  Future<void> disable() async {
    state = const AsyncData(false);
    await _updateServer(false);
  }

  Future<void> _updateServer(bool enabled) async {
    try {
      await ref.read(sessionRepositoryProvider).updateNotificationsEnabled(enabled);
    } catch (_) {
      // 네트워크 오류 — 다음 sync 시 재시도됨
    }

    if (enabled) {
      await _registerDeviceToken();
    } else {
      await _unregisterDeviceToken();
    }
  }

  Future<void> _registerDeviceToken([String? token]) async {
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await ref.read(deviceTokenRepositoryProvider).register(
            token: fcmToken,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
    } catch (_) {
      // 네트워크 오류 등 — 다음 sync 시 재시도됨
    }
  }

  Future<void> _unregisterDeviceToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await ref.read(deviceTokenRepositoryProvider).unregister(fcmToken);
    } catch (_) {
      // 네트워크 오류 등 — 무시 (서버에 남아있어도 mute 상태라 실질적 영향 없음)
    }
  }
}
