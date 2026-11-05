import 'dart:convert';
import 'dart:async';
import 'package:share_it/services/entry_chat_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/models/bootstrap_response.dart';
import 'package:share_it/models/expense_model.dart';
import 'package:share_it/models/user_model.dart';
import 'package:share_it/providers/core_providers.dart';
import 'package:share_it/providers/expense_provider.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/session_repository.dart';
import 'package:share_it/screens/expense_detail_screen.dart';
import 'package:share_it/storage/token_storage.dart';
import 'package:share_it/storage/topic_filter_storage.dart';
import 'package:share_it/theme/app_theme.dart';

class ChatSession extends SessionNotifier {
  ChatSession(ApiClient api, TokenStorage storage)
      : super(
          repository: SessionRepository(apiClient: api, tokenStorage: storage),
          tokenStorage: storage,
        ) {
    state = const SessionState(
      status: SessionStatus.ready,
      data: BootstrapResponse(
        bootstrapCreated: false,
        entries: [],
        user: UserModel(
          id: 1,
          email: 'test@example.com',
          nickName: 'Me',
          isGuest: false,
          token: 'test',
          createdAt: '',
          updatedAt: '',
        ),
      ),
    );
  }
}

void main() {
  Map<String, dynamic> message(int id, String body, {int author = 1}) => {
        'id': id,
        'body': body,
        'author': {'id': author, 'nick_name': 'Minji'},
        'created_at': '2026-11-05T12:00:00Z',
        'updated_at': '2026-11-05T12:00:00Z',
      };
  Future<void> mount(
    WidgetTester tester,
    Future<http.Response> Function(http.Request) handler, {
    bool small = false,
    Stream<ChatEvent>? liveEvents,
  }) async {
    tester.view.physicalSize =
        small ? const Size(320, 568) : const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient(client: MockClient(handler));
    final storage = await TokenStorage.create();
    final filters = await TopicFilterStorage.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          entryChatEventsProvider
              .overrideWith((ref, id) => liveEvents ?? const Stream.empty()),
          sessionNotifierProvider
              .overrideWith((ref) => ChatSession(api, storage)),
          expenseNotifierProvider
              .overrideWith((ref) => ExpenseNotifier(null, filters)),
          myViewableTopicsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExpenseDetailScreen(
            expense: ExpenseModel(
              id: 42,
              title: 'Cafe latte',
              amount: 550,
              occurredAt: DateTime(2026, 11, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'live events refresh create edit delete and reconnect without duplicate messages',
      (tester) async {
    final events = StreamController<ChatEvent>();
    var records = <Map<String, dynamic>>[];
    await mount(
      tester,
      (_) async => http.Response(
        jsonEncode({'records': records, 'next_before_id': null}),
        200,
      ),
      liveEvents: events.stream,
    );
    events.add(ChatEvent.connected);
    await tester.pumpAndSettle();
    records = [message(1, 'From another person', author: 2)];
    events.add(ChatEvent.changed);
    await tester.pumpAndSettle();
    expect(find.text('From another person'), findsOneWidget);
    records = [message(1, 'Edited remotely', author: 2)];
    events.add(ChatEvent.changed);
    await tester.pumpAndSettle();
    expect(find.text('Edited remotely'), findsOneWidget);
    expect(find.text('From another person'), findsNothing);
    records = [];
    events.add(ChatEvent.changed);
    await tester.pumpAndSettle();
    expect(find.text('Edited remotely'), findsNothing);
    events.add(ChatEvent.offline);
    await tester.pumpAndSettle();
    records = [message(2, 'Sent while disconnected', author: 2)];
    events.add(ChatEvent.connected);
    await tester.pumpAndSettle();
    expect(find.text('Sent while disconnected'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    unawaited(events.close());
    await tester.pump();
  });

  testWidgets('sends a message, edits own message, then deletes it',
      (tester) async {
    final methods = <String>[];
    await mount(tester, (request) async {
      methods.add(request.method);
      expect(request.url.path, startsWith('/api/v1/entries/42/messages'));
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({'records': [], 'next_before_id': null}),
          200,
        );
      }
      if (request.method == 'DELETE') return http.Response('', 204);
      return http.Response(
        jsonEncode(message(1, jsonDecode(request.body)['body'] as String)),
        request.method == 'POST' ? 201 : 200,
      );
    });
    expect(find.textContaining('No messages yet'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Great price');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Great price'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.longPress(find.text('Great price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit message'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Where is this?');
    await tester.pump();
    await tester.tap(find.byTooltip('Save message'));
    await tester.pumpAndSettle();
    expect(find.text('Where is this?'), findsOneWidget);
    await tester.longPress(find.text('Where is this?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Where is this?'), findsNothing);
    expect(methods, containsAllInOrder(['GET', 'POST', 'PATCH', 'DELETE']));
  });

  testWidgets('failed send preserves draft and can be sent again',
      (tester) async {
    var attempts = 0;
    await mount(tester, (request) async {
      if (request.method == 'GET') {
        return http.Response('{"records":[],"next_before_id":null}', 200);
      }
      if (++attempts == 1) {
        return http.Response('{"message":"Unavailable"}', 503);
      }
      return http.Response(jsonEncode(message(1, 'Hello')), 201);
    });
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Hello',
    );
    expect(find.textContaining('Couldn’t connect'), findsOneWidget);
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets(
      'loads earlier messages and does not expose actions for another author',
      (tester) async {
    await mount(
      tester,
      (request) async => http.Response(
        jsonEncode({
          'records': [
            request.url.queryParameters.containsKey('before_id')
                ? message(1, 'Earlier', author: 2)
                : message(2, 'Latest', author: 2),
          ],
          'next_before_id':
              request.url.queryParameters.containsKey('before_id') ? null : 2,
        }),
        200,
      ),
    );
    await tester.tap(find.text('Load earlier messages'));
    await tester.pumpAndSettle();
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    await tester.longPress(find.text('Latest'));
    await tester.pumpAndSettle();
    expect(find.text('Edit message'), findsNothing);
  });

  testWidgets(
      'revoked access disables composer on a small screen with keyboard',
      (tester) async {
    await mount(
      tester,
      (request) async => http.Response('{"message":"Forbidden"}', 403),
      small: true,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    expect(find.textContaining('no longer available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
