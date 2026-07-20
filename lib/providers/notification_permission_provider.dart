import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'session_provider.dart';

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionNotifier, bool>(
      NotificationPermissionNotifier.new,
    );

class NotificationPermissionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return (await Permission.notification.status).isGranted;
  }

  /// 앱이 포그라운드로 복귀할 때 OS 권한 상태를 확인하고 서버에 동기화
  Future<void> sync() async {
    final granted = (await Permission.notification.status).isGranted;
    final previous = state.valueOrNull;
    state = AsyncData(granted);
    if (previous != granted) {
      await _updateServer(granted);
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
  }
}
