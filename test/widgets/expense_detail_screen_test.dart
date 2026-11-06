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

  for (final operation in ['edit', 'delete']) {
    testWidgets('missing message on $operation keeps conversation usable',
        (tester) async {
      await mount(tester, (request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'records': [
                message(2, 'Other message'),
                message(1, 'Removed elsewhere'),
              ],
              'next_before_id': null,
            }),
            200,
          );
        }
        return http.Response(
          '{"message":"Message not found","code":"message_not_found"}',
          404,
        );
      });
      await tester.enterText(find.byType(TextField), 'Unsent draft');
      await tester.longPress(find.text('Removed elsewhere'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(operation == 'edit' ? 'Edit message' : 'Delete message'),
      );
      await tester.pumpAndSettle();
      if (operation == 'edit') {
        await tester.enterText(find.byType(TextField), 'Revised');
        await tester.pump();
        await tester.tap(find.byTooltip('Save message'));
      } else {
        await tester.tap(find.text('Delete'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Other message'), findsOneWidget);
      expect(find.text('Removed elsewhere'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, true);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Unsent draft',
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Send message',
              ),
            )
            .onPressed,
        isNotNull,
      );
    });
  }

  testWidgets('cancel and successful edit restore the unsent draft',
      (tester) async {
    await mount(tester, (request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'records': [message(1, 'Original')],
            'next_before_id': null,
          }),
          200,
        );
      }
      return http.Response(jsonEncode(message(1, 'Revised')), 200);
    });
    await tester.enterText(find.byType(TextField), 'Draft to preserve');
    for (final cancel in [true, false]) {
      await tester.longPress(find.text('Original'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit message'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Revised');
      await tester.pump();
      await tester
          .tap(cancel ? find.text('Cancel') : find.byTooltip('Save message'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Draft to preserve',
      );
    }
  });

  testWidgets('provider refresh does not replay previous Live event',
      (tester) async {
    final events = StreamController<ChatEvent>.broadcast();
    await mount(
      tester,
      (_) async => http.Response('{"records":[],"next_before_id":null}', 200),
      liveEvents: events.stream,
    );
    events.add(ChatEvent.connected);
    await tester.pumpAndSettle();
    expect(find.text('Conversation · Live'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Conversation · Live'), findsNothing);
    events.add(ChatEvent.connected);
    await tester.pumpAndSettle();
    expect(find.text('Conversation · Live'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    unawaited(events.close());
    await tester.pump();
  });

  testWidgets(
      'changed ID fetches one message and permits sending during refresh',
      (tester) async {
    final events = StreamController<ChatEvent>();
    final pending = Completer<http.Response>();
    final gets = <String>[];
    var delayed = true;
    await mount(
      tester,
      (request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode(message(4, 'New local message')),
            201,
          );
        }
        gets.add(request.url.path);
        if (request.url.path.endsWith('/3')) {
          if (delayed) return pending.future;
          return http.Response(
            jsonEncode(message(3, 'Remote change', author: 2)),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'records': [message(2, 'Existing'), message(1, 'Older')],
            'next_before_id': null,
          }),
          200,
        );
      },
      liveEvents: events.stream,
    );
    events.add(const ChatEvent.message(3));
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'New local message');
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Send message',
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    delayed = false;
    pending.complete(
      http.Response(jsonEncode(message(3, 'Remote change', author: 2)), 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('New local message'), findsOneWidget);
    expect(find.text('Remote change'), findsOneWidget);
    expect(find.text('Older'), findsOneWidget);
    expect(gets.where((path) => path.endsWith('/messages')).length, 1);
    await tester.pumpWidget(const SizedBox());
    unawaited(events.close());
    await tester.pump();
  });

  testWidgets(
      'unloaded old edits stay outside the loaded range and pages deduplicate',
      (tester) async {
    final events = StreamController<ChatEvent>();
    await mount(
      tester,
      (request) async {
        if (request.url.path.endsWith('/5')) {
          return http.Response(
            jsonEncode(message(5, 'Old edited message')),
            200,
          );
        }
        final older = request.url.queryParameters.containsKey('before_id');
        return http.Response(
          jsonEncode({
            'records': older
                ? [message(30, 'Boundary'), message(5, 'Old edited message')]
                : [message(31, 'Latest'), message(30, 'Boundary')],
            'next_before_id': older ? null : 30,
          }),
          200,
        );
      },
      liveEvents: events.stream,
    );
    events.add(const ChatEvent.message(5));
    await tester.pumpAndSettle();
    expect(find.text('Old edited message'), findsNothing);
    await tester.tap(find.text('Load earlier messages'));
    await tester.pumpAndSettle();
    expect(find.text('Boundary'), findsOneWidget);
    expect(find.text('Old edited message'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    unawaited(events.close());
    await tester.pump();
  });

  testWidgets('transient single-message failure retries without another event',
      (tester) async {
    final events = StreamController<ChatEvent>();
    var attempts = 0;
    await mount(
      tester,
      (request) async {
        if (request.url.path.endsWith('/2')) {
          if (++attempts == 1) {
            return http.Response('{"message":"Unavailable"}', 503);
          }
          return http.Response(
            jsonEncode(message(2, 'Recovered message')),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'records': [message(1, 'Existing')],
            'next_before_id': null,
          }),
          200,
        );
      },
      liveEvents: events.stream,
    );
    events.add(const ChatEvent.message(2));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(attempts, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Recovered message'), findsOneWidget);
    expect(find.textContaining('Couldn’t connect'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    unawaited(events.close());
    await tester.pump();
  });

  testWidgets(
      'persistent sync failure backs off and cancels retries on dispose',
      (tester) async {
    final events = StreamController<ChatEvent>();
    var attempts = 0;
    await mount(
      tester,
      (request) async {
        if (request.url.path.endsWith('/2')) {
          attempts++;
          return http.Response('{"message":"Unavailable"}', 503);
        }
        return http.Response('{"records":[],"next_before_id":null}', 200);
      },
      liveEvents: events.stream,
    );
    events.add(const ChatEvent.message(2));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(attempts, 2);
    await tester.pumpWidget(const SizedBox());
    unawaited(events.close());
    await tester.pump(const Duration(seconds: 20));
    expect(attempts, 2);
  });

  testWidgets(
      'sending during older-page fetch automatically completes the requested page',
      (tester) async {
    final pending = Completer<http.Response>();
    var olderRequests = 0;
    await mount(tester, (request) async {
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode(message(32, 'Sent during paging')),
          201,
        );
      }
      if (request.url.queryParameters.containsKey('before_id')) {
        expect(request.url.queryParameters['before_id'], '30');
        if (++olderRequests == 1) return pending.future;
        return http.Response(
          jsonEncode({
            'records': [message(29, 'Earlier message')],
            'next_before_id': null,
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'records': [message(31, 'Latest'), message(30, 'Boundary')],
          'next_before_id': 30,
        }),
        200,
      );
    });
    await tester.tap(find.text('Load earlier messages'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Sent during paging');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    pending.complete(
      http.Response(
        jsonEncode({
          'records': [message(29, 'Earlier message')],
          'next_before_id': null,
        }),
        200,
      ),
    );
    await tester.pumpAndSettle();
    expect(olderRequests, 2);
    expect(find.text('Earlier message'), findsOneWidget);
    expect(find.text('Sent during paging'), findsOneWidget);
    expect(find.text('Boundary'), findsOneWidget);
    expect(find.text('Load earlier messages'), findsNothing);
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
      'loads earlier messages and exposes only safety actions for another author',
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
    expect(find.text('Report message'), findsOneWidget);
    expect(find.text('Block Minji'), findsOneWidget);
  });

  testWidgets('reports another author message with a review reason',
      (tester) async {
    String? reportedPath;
    String? reportedReason;
    await mount(tester, (request) async {
      if (request.method == 'POST') {
        reportedPath = request.url.path;
        reportedReason = (jsonDecode(request.body)
            as Map<String, dynamic>)['reason'] as String;
        return http.Response('{"id":1,"status":"pending"}', 201);
      }
      return http.Response(
        jsonEncode({
          'records': [message(8, 'Unsafe message', author: 2)],
          'next_before_id': null,
        }),
        200,
      );
    });

    await tester.longPress(find.text('Unsafe message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harassment or bullying'));
    await tester.pumpAndSettle();

    expect(reportedPath, '/api/v1/entries/42/messages/8/report');
    expect(reportedReason, 'harassment');
    expect(find.text('Message reported. Thank you.'), findsOneWidget);
  });

  testWidgets('blocks another author and removes their loaded messages',
      (tester) async {
    String? blockedPath;
    await mount(tester, (request) async {
      if (request.method == 'POST') {
        blockedPath = request.url.path;
        return http.Response(
          '{"user":{"id":2,"nick_name":"Minji"}}',
          201,
        );
      }
      return http.Response(
        jsonEncode({
          'records': blockedPath == null
              ? [message(8, 'Unsafe message', author: 2)]
              : [],
          'next_before_id': null,
        }),
        200,
      );
    });

    await tester.longPress(find.text('Unsafe message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Minji'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Block'));
    await tester.pumpAndSettle();

    expect(blockedPath, '/api/v1/entries/42/messages/8/block');
    expect(find.text('Unsafe message'), findsNothing);
    expect(find.text('Minji was blocked.'), findsOneWidget);
  });

  testWidgets('lists and unblocks users from the conversation app bar',
      (tester) async {
    var unblocked = false;
    await mount(tester, (request) async {
      if (request.method == 'DELETE') {
        unblocked = true;
        return http.Response('', 204);
      }
      if (request.url.path == '/api/v1/chat_blocks') {
        return http.Response(
          '{"records":[{"user":{"id":2,"nick_name":"Minji"}}]}',
          200,
        );
      }
      return http.Response('{"records":[],"next_before_id":null}', 200);
    });

    await tester.tap(find.byTooltip('Manage blocked users'));
    await tester.pumpAndSettle();
    expect(find.text('Blocked users'), findsOneWidget);
    expect(find.text('Minji'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(unblocked, true);
    expect(find.text('No blocked users.'), findsOneWidget);
  });

  testWidgets('a pre-block request cannot restore hidden messages',
      (tester) async {
    final pending = Completer<http.Response>();
    var gets = 0;
    var blocked = false;
    await mount(tester, (request) async {
      if (request.method == 'POST') {
        blocked = true;
        return http.Response('{"user":{"id":2,"nick_name":"Minji"}}', 201);
      }
      if (++gets == 2) return pending.future;
      return http.Response(
          jsonEncode({
            'records': blocked ? [] : [message(8, 'Old response', author: 2)],
            'next_before_id': null,
          }),
          200);
    });
    await tester.tap(find.byTooltip('Refresh conversation'));
    await tester.pump();
    await tester.longPress(find.text('Old response'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block Minji'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Block'));
    await tester.pumpAndSettle();
    pending.complete(http.Response(
        jsonEncode({
          'records': [message(8, 'Old response', author: 2)],
          'next_before_id': null,
        }),
        200));
    await tester.pumpAndSettle();
    expect(find.text('Old response'), findsNothing);
    expect(gets, greaterThan(2));
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
