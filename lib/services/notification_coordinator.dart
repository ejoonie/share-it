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
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Stream<String> get onTokenRefresh;
}

class FirebaseNotificationMessaging implements NotificationMessaging {
  @override
  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

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
  StreamSubscription<RemoteMessage>? _messageSubscription;
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

  /// 알림 탭/수신으로 화면을 이동시켜야 할 때 값을 흘려보내는 스트림.
  /// 아래 세 핸들러(getInitialMessage/onMessage/onMessageOpenedApp)가 전부
  /// 여기로 모여서, 호출부(app.dart)는 앱 상태(종료/포그라운드/백그라운드)를
  /// 신경 쓰지 않고 하나의 리스너로만 처리하면 된다.
  Stream<NotificationDestination> get destinations => _destinations.stream;

  Future<NotificationDestination?> init() async {
    if (_initialized) return null;
    _initialized = true;

    // 1. 콜드 스타트: 앱이 완전히 종료된 상태에서 알림을 탭해 열린 경우.
    // 이 시점엔 아직 스트림 구독 전이라 onMessageOpenedApp으로는 못 받고,
    // Firebase가 "마지막으로 앱을 연 알림"을 별도로 기억해뒀다가 이 호출로
    // 한 번 돌려준다 - 그래서 스트림이 아니라 Future이고, init()의 반환값으로
    // 직접 넘겨준다(destinations 스트림에는 안 흘림, 리스너 등록 전이라 유실됨).
    final initialMessage = await _messaging.getInitialMessage();

    // 2. 포그라운드 수신: 앱을 보고 있는 도중 알림이 도착한 경우. OS가 배너를
    // 띄워주지 않으므로(우리는 로컬 알림을 따로 안 띄움) 이걸 안 받으면
    // 사용자는 푸시가 온 걸 전혀 알 수 없다. 백그라운드 탭과 동일하게
    // 바로 이동시키기 위해 같은 _emitDestination으로 흘려보낸다.
    _messageSubscription = _messaging.onMessage.listen(_emitDestination);

    // 3. 백그라운드 → 포그라운드 복귀: 앱이 백그라운드에 있다가 사용자가
    // 알림 배너를 탭해서 앱으로 돌아온 경우.
    _messageOpenedSubscription = _messaging.onMessageOpenedApp.listen(
      _emitDestination,
    );

    // 4. FCM 토큰이 재발급된 경우(재설치, 앱 데이터 삭제, 주기적 로테이션 등).
    // 새 토큰을 서버에 다시 등록해야 계속 알림을 받을 수 있다.
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(_onTokenRefreshed);

    return initialMessage == null
        ? null
        : NotificationDestination.fromMessage(initialMessage);
  }

  /// 로그아웃 등으로 이 기기를 알림 수신 대상에서 뺄 때 호출한다.
  Future<void> unregisterCurrentDevice() => _onUnregisterRequested();

  /// RemoteMessage를 목적지로 파싱해 destinations 스트림으로 흘려보낸다.
  /// onMessage/onMessageOpenedApp 둘 다 이걸 그대로 재사용해서, 포그라운드로
  /// 왔는지 탭해서 왔는지와 무관하게 동일한 payload 파싱/이동 로직을 탄다.
  void _emitDestination(RemoteMessage message) {
    final destination = NotificationDestination.fromMessage(message);
    if (destination != null) _destinations.add(destination);
  }

  void dispose() {
    _messageSubscription?.cancel();
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
