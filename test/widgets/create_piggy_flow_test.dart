import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/providers/core_providers.dart';
import 'package:share_it/providers/expense_provider.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/session_repository.dart';
import 'package:share_it/screens/expense_screen.dart';
import 'package:share_it/storage/last_used_topic_storage.dart';
import 'package:share_it/storage/token_storage.dart';
import 'package:share_it/storage/topic_filter_storage.dart';
import 'package:share_it/models/topic_filter.dart';
import 'package:share_it/widgets/expense/expense_overview.dart';

void main() {
  testWidgets('empty ledger retries creation and recovers with the new piggy',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tokenStorage = await TokenStorage.create();
    final filterStorage = await TopicFilterStorage.create();
    await filterStorage.saveFilter(const TopicFilterSelected({99}));
    final lastUsedStorage = await LastUsedTopicStorage.create();
    var attempts = 0;
    var created = false;
    final topic = {
      'id': 7,
      'token': 'new',
      'user_id': 1,
      'title': 'Everyday',
      'is_default': false,
      'created_at': '',
      'updated_at': '',
    };
    final client = ApiClient(
      client: MockClient(
        (request) async {
          if (request.method == 'POST') {
            attempts++;
            expect(jsonDecode(request.body)['title'], 'Everyday');
            if (attempts == 1) {
              return http.Response('{"message":"Try again"}', 500);
            }
            created = true;
            return http.Response(jsonEncode(topic), 201);
          }
          return http.Response(
            jsonEncode({
              'records':
                  request.url.path.endsWith('/owned') && created ? [topic] : [],
            }),
            200,
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        topicFilterStorageProvider.overrideWithValue(filterStorage),
        lastUsedTopicStorageProvider.overrideWithValue(lastUsedStorage),
        sessionNotifierProvider.overrideWith(
          (ref) => SessionNotifier(
            repository: SessionRepository(
              apiClient: client,
              tokenStorage: tokenStorage,
            ),
            tokenStorage: tokenStorage,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExpenseScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create a piggy'), findsOneWidget);
    await tester.tap(find.text('Create a piggy'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), ' Everyday ');
    await tester.tap(find.text('Create piggy'));
    await tester.pumpAndSettle();
    expect(
      find.text('Couldn’t create your piggy. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create piggy'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ExpenseOverview), findsOneWidget);
    expect(container.read(expenseNotifierProvider).isLoading, isFalse);
    expect(
      container.read(expenseNotifierProvider).topicFilter.isSelected(7),
      isTrue,
    );
    expect(container.read(currentTopicIdProvider), 7);
    expect(lastUsedStorage.getLastUsedTopicId(), 7);
    expect(tester.takeException(), isNull);
  });
}
