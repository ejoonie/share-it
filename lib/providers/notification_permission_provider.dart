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

final notificationSettingsProvider =
    AsyncNotifierProvider<
      NotificationSettingsNotifier,
      NotificationSettingsState
    >(NotificationSettingsNotifier.new);

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettingsState> {
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
    final result = await Permission.notification.request();
    final current = state.requireValue;
    state = AsyncData(current.copyWith(osAuthorization: result));
    return result;
  }

  Future<void> enableNotifications() async {
    final current = state.requireValue;
    await ref.read(notificationRepositoryProvider).setEnabled(true);
    ref.read(sessionNotifierProvider.notifier).setNotificationsEnabled(true);
    state = AsyncData(current.copyWith(serverEnabled: true));
    await syncToken();
  }

  Future<void> disableNotifications() async {
    final current = state.requireValue;
    await ref.read(notificationRepositoryProvider).setEnabled(false);
    ref.read(sessionNotifierProvider.notifier).setNotificationsEnabled(false);
    state = AsyncData(current.copyWith(serverEnabled: false));
    await _unregisterCurrentToken();
  }

  Future<void> syncOsPermission() async {
    final current = state.requireValue;
    final osAuthorization = await Permission.notification.status;
    final updated = current.copyWith(osAuthorization: osAuthorization);
    state = AsyncData(updated);
    if (updated.isActive) await syncToken();
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
    await ref
        .read(notificationRepositoryProvider)
        .registerToken(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
  }

  Future<void> _unregisterCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ref.read(notificationRepositoryProvider).unregisterToken(token);
  }
}
