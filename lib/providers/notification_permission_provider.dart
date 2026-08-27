import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core_providers.dart';
import 'session_provider.dart';

class NotificationSettingsState {
  final PermissionStatus osAuthorization;
  final bool serverEnabled;

  const NotificationSettingsState({
    required this.osAuthorization,
    required this.serverEnabled,
  });

  bool get isActive => osAuthorization.isGranted && serverEnabled;

  NotificationSettingsState copyWith({
    PermissionStatus? osAuthorization,
    bool? serverEnabled,
  }) {
    return NotificationSettingsState(
      osAuthorization: osAuthorization ?? this.osAuthorization,
      serverEnabled: serverEnabled ?? this.serverEnabled,
    );
  }
}

final notificationSettingsProvider = AsyncNotifierProvider<
    NotificationSettingsNotifier,
    NotificationSettingsState>(NotificationSettingsNotifier.new);

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettingsState> {
  bool _operationInProgress = false;

  @override
  Future<NotificationSettingsState> build() async {
    final osAuthorization = await Permission.notification.status;
    final serverEnabled =
        ref.read(sessionNotifierProvider).data?.user?.notificationsEnabled ??
            false;
    return NotificationSettingsState(
      osAuthorization: osAuthorization,
      serverEnabled: serverEnabled,
    );
  }

  Future<PermissionStatus> requestOsPermission() async {
    if (_operationInProgress) {
      return state.valueOrNull?.osAuthorization ?? PermissionStatus.denied;
    }
    _operationInProgress = true;
    final current = state.requireValue;
    state = const AsyncLoading();
    try {
      final result = await Permission.notification.request();
      state = AsyncData(current.copyWith(osAuthorization: result));
      return result;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> enableNotifications() async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    final current = state.requireValue;
    state = const AsyncLoading();
    try {
      final osAuthorization = await Permission.notification.status;
      final updated = current.copyWith(osAuthorization: osAuthorization);
      if (!osAuthorization.isGranted) {
        state = AsyncData(updated);
        return;
      }

      await ref.read(notificationRepositoryProvider).setEnabled(true);
      ref.read(sessionNotifierProvider.notifier).setNotificationsEnabled(true);
      state = AsyncData(updated.copyWith(serverEnabled: true));
      await syncToken();
    } catch (_) {
      if (state.isLoading) state = AsyncData(current);
      rethrow;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> disableNotifications() async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    final current = state.requireValue;
    state = const AsyncLoading();
    try {
      await ref.read(notificationRepositoryProvider).setEnabled(false);
      ref.read(sessionNotifierProvider.notifier).setNotificationsEnabled(false);
      state = AsyncData(current.copyWith(serverEnabled: false));
      await _unregisterCurrentToken();
    } catch (_) {
      if (state.isLoading) state = AsyncData(current);
      rethrow;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> syncOsPermission() async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    final current = state.requireValue;
    try {
      final osAuthorization = await Permission.notification.status;
      final updated = current.copyWith(osAuthorization: osAuthorization);
      state = AsyncData(updated);
      if (updated.isActive) await syncToken();
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> onTokenRefreshed(String token) async {
    final current = state.valueOrNull;
    if (current == null || !current.isActive) return;
    try {
      await syncToken(token);
    } on Exception catch (error) {
      debugPrint('[push] Failed to register refreshed token: $error');
    }
  }

  Future<void> syncToken([String? refreshedToken]) async {
    final current = state.valueOrNull;
    if (current == null || !current.isActive) return;

    final token = refreshedToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ref.read(notificationRepositoryProvider).registerToken(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
  }

  Future<void> _unregisterCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ref.read(notificationRepositoryProvider).unregisterToken(token);
  }

  /// 로그아웃/회원탈퇴 시 호출 — 이 기기의 FCM 토큰을 서버에서 먼저 해제하고
  /// (아직 인증 토큰이 남아있을 때), FirebaseMessaging.deleteToken()으로 토큰
  /// 자체도 폐기한다. 둘 중 하나가 실패해도 나머지는 계속 진행하고, 호출자의
  /// 로그아웃 흐름 자체를 막지 않도록 예외를 던지지 않는다 - 서버 해제가
  /// 실패해도 deleteToken()이 성공하면 기존 토큰은 무효화되고, 서버에 남은
  /// 레코드는 다음 발송 시 FCM의 UNREGISTERED 응답으로 정리된다.
  Future<void> unregisterCurrentDevice() async {
    try {
      await _unregisterCurrentToken();
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
