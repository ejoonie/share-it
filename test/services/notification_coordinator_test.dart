import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/services/notification_coordinator.dart';

void main() {
  group('NotificationDestination.fromMessage', () {
    test('parses an entry-change destination', () {
      final destination = NotificationDestination.fromMessage(
        const RemoteMessage(
          data: {
            'type': 'entry_change',
            'entry_id': '42',
            'occurred_at': '2026-08-26T12:00:00Z',
          },
        ),
      );

      expect(destination, isA<EntryChangeDestination>());
      final entryChange = destination! as EntryChangeDestination;
      expect(entryChange.entryId, 42);
      expect(entryChange.occurredAt, DateTime.utc(2026, 8, 26, 12));
    });

    test('ignores unsupported or malformed payloads', () {
      expect(
        NotificationDestination.fromMessage(
          const RemoteMessage(data: {'type': 'unknown'}),
        ),
        isNull,
      );
      expect(
        NotificationDestination.fromMessage(
          const RemoteMessage(
            data: {
              'type': 'entry_change',
              'entry_id': 'not-an-id',
              'occurred_at': 'not-a-date',
            },
          ),
        ),
        isNull,
      );
    });
  });

  group('NotificationCoordinator', () {
    test('returns the initial destination and initializes only once', () async {
      final messaging = _FakeNotificationMessaging(
        initialMessage: const RemoteMessage(
          data: {
            'type': 'entry_change',
            'entry_id': '7',
            'occurred_at': '2026-08-26T12:00:00Z',
          },
        ),
      );
      final refreshedTokens = <String>[];
      final coordinator = NotificationCoordinator(
        messaging: messaging,
        onTokenRefreshed: refreshedTokens.add,
        onUnregisterRequested: () async {},
      );

      final initial = await coordinator.init();
      final second = await coordinator.init();
      messaging.tokenRefresh.add('new-token');
      await Future<void>.delayed(Duration.zero);

      expect(initial, isA<EntryChangeDestination>());
      expect(second, isNull);
      expect(messaging.initialMessageCalls, 1);
      expect(refreshedTokens, ['new-token']);
      coordinator.dispose();
      await messaging.dispose();
    });

    test('emits opened-message destinations until disposed', () async {
      final messaging = _FakeNotificationMessaging();
      final coordinator = NotificationCoordinator(
        messaging: messaging,
        onTokenRefreshed: (_) {},
        onUnregisterRequested: () async {},
      );
      final destinations = <NotificationDestination>[];
      final subscription = coordinator.destinations.listen(destinations.add);
      await coordinator.init();

      messaging.messageOpened.add(
        const RemoteMessage(
          data: {
            'type': 'entry_change',
            'entry_id': '8',
            'occurred_at': '2026-08-26T12:00:00Z',
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(destinations, hasLength(1));

      coordinator.dispose();
      messaging.messageOpened.add(
        const RemoteMessage(
          data: {
            'type': 'entry_change',
            'entry_id': '9',
            'occurred_at': '2026-08-26T12:00:00Z',
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(destinations, hasLength(1));
      await subscription.cancel();
      await messaging.dispose();
    });

    test('unregisterCurrentDevice delegates to the injected callback', () async {
      final messaging = _FakeNotificationMessaging();
      var unregisterCalls = 0;
      final coordinator = NotificationCoordinator(
        messaging: messaging,
        onTokenRefreshed: (_) {},
        onUnregisterRequested: () async {
          unregisterCalls += 1;
        },
      );

      await coordinator.unregisterCurrentDevice();

      expect(unregisterCalls, 1);
      coordinator.dispose();
      await messaging.dispose();
    });
  });
}

class _FakeNotificationMessaging implements NotificationMessaging {
  final RemoteMessage? initialMessage;
  final messageOpened = StreamController<RemoteMessage>.broadcast();
  final tokenRefresh = StreamController<String>.broadcast();
  int initialMessageCalls = 0;

  _FakeNotificationMessaging({this.initialMessage});

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    initialMessageCalls += 1;
    return initialMessage;
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => messageOpened.stream;

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  Future<void> dispose() async {
    await messageOpened.close();
    await tokenRefresh.close();
  }
}
