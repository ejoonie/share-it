import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_permission_provider.dart';

sealed class NotificationDestination {
  const NotificationDestination();

  static NotificationDestination? fromMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'entry_change') return null;

    final entryId = int.tryParse('${data['entry_id']}');
    final occurredAt = DateTime.tryParse('${data['occurred_at']}');
    if (entryId == null || occurredAt == null) return null;
    return EntryChangeDestination(entryId: entryId, occurredAt: occurredAt);
  }
}

class EntryChangeDestination extends NotificationDestination {
  final int entryId;
  final DateTime occurredAt;

  const EntryChangeDestination({
    required this.entryId,
    required this.occurredAt,
  });
}

abstract class NotificationMessaging {
  Future<RemoteMessage?> getInitialMessage();
  Stream<RemoteMessage> get onMessageOpenedApp;
  Stream<String> get onTokenRefresh;
}

class FirebaseNotificationMessaging implements NotificationMessaging {
  @override
  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;
}

class NotificationCoordinator {
  final NotificationMessaging _messaging;
  final void Function(String token) _onTokenRefreshed;
  final Future<void> Function() _onUnregisterRequested;
  final _destinations = StreamController<NotificationDestination>.broadcast();
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  NotificationCoordinator({
    required NotificationMessaging messaging,
    required void Function(String token) onTokenRefreshed,
    required Future<void> Function() onUnregisterRequested,
  })  : _messaging = messaging,
        _onTokenRefreshed = onTokenRefreshed,
        _onUnregisterRequested = onUnregisterRequested;

  Stream<NotificationDestination> get destinations => _destinations.stream;

  Future<NotificationDestination?> init() async {
    if (_initialized) return null;
    _initialized = true;

    final initialMessage = await _messaging.getInitialMessage();
    _messageOpenedSubscription = _messaging.onMessageOpenedApp.listen(
      _emitDestination,
    );
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(_onTokenRefreshed);

    return initialMessage == null
        ? null
        : NotificationDestination.fromMessage(initialMessage);
  }

  /// 로그아웃 등으로 이 기기를 알림 수신 대상에서 뺄 때 호출한다.
  Future<void> unregisterCurrentDevice() => _onUnregisterRequested();

  void _emitDestination(RemoteMessage message) {
    final destination = NotificationDestination.fromMessage(message);
    if (destination != null) _destinations.add(destination);
  }

  void dispose() {
    _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _destinations.close();
  }
}

final notificationCoordinatorProvider = Provider<NotificationCoordinator>((
  ref,
) {
  final coordinator = NotificationCoordinator(
    messaging: FirebaseNotificationMessaging(),
    onTokenRefreshed: (token) {
      ref.read(notificationSettingsProvider.notifier).onTokenRefreshed(token);
    },
    onUnregisterRequested: () {
      return ref
          .read(notificationSettingsProvider.notifier)
          .unregisterCurrentDevice();
    },
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
