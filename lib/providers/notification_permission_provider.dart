import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core_providers.dart';
import 'session_provider.dart';

/// 알림 설정은 서버의 user.notifications_enabled 하나로만 표현한다(디폴트
/// true). OS 알림 권한을 허용했는지는 여기서 추적하지 않는다 - 실제 발송
/// 여부는 서버가 notifications_enabled만으로 판단하고, 디바이스 토큰 등록도
/// 이 값과 무관하게(꺼져 있어도) 항상 시도한다. OS 권한을 안 줬으면 토큰
/// 자체가 안 나오거나 FCM이 전달을 못 할 뿐이니, 그 상태를 앱에서 따로
/// 들고 다니며 다른 동작을 가로막을 이유가 없다.
final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, bool>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(sessionNotifierProvider).data?.user?.notificationsEnabled ??
        true;
  }

  /// 알림 켜기. OS 권한이 아직 결정 안 됐으면 요청 다이얼로그를 띄우되(바로
  /// 허용할 수 있게 하는 용도), 결과와 무관하게 서버 설정은 켠다 - 나중에 OS
  /// 설정 앱에서 권한을 허용해도 별도 조작 없이 알림을 받게 하기 위해서다.
  Future<void> enableNotifications() async {
    await Permission.notification.request();
    await ref.read(notificationRepositoryProvider).setEnabled(true);
    ref.read(sessionNotifierProvider.notifier).setNotificationsEnabled(true);
    state = const AsyncData(true);
    await syncToken();
  }

  /// 알림 끄기. 디바이스 토큰은 그대로 둔다 - 발송 여부는 서버가
  /// notifications_enabled로 걸러내므로 토큰을 해제할 필요가 없다.
  Future<void> disableNotifications() async {
    await ref.read(notificationRepositoryProvider).setEnabled(false);
    ref.read(sessionNotifierProvider.notifier).setNotificationsEnabled(false);
    state = const AsyncData(false);
  }

  Future<void> onTokenRefreshed(String token) => syncToken(token);

  /// 디바이스 토큰 등록 - notifications_enabled/OS 권한 등 어떤 상태에도
  /// 종속되지 않고, 토큰을 구할 수 있으면 무조건 서버에 등록한다. 실제 발송
  /// 여부는 서버가 notifications_enabled로 판단하므로, 여기서 미리 걸러낼
  /// 필요가 없다.
  Future<void> syncToken([String? refreshedToken]) async {
    if (Platform.isIOS) {
      // iOS는 APNs 토큰이 먼저 준비돼야 FCM 토큰을 구할 수 있다. 아직이면
      // 이번엔 건너뛰고 다음 앱 재개/토큰 리프레시 때 다시 시도한다.
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) return;
    }

    final token = refreshedToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await ref.read(notificationRepositoryProvider).registerToken(
            token: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
    } catch (error) {
      debugPrint('[push] Failed to register token: $error');
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
        await ref.read(notificationRepositoryProvider).unregisterToken(token);
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
