import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/providers/core_providers.dart';
import 'package:share_it/repositories/topic_repository.dart';
import 'package:share_it/repositories/subscription_repository.dart';
import 'package:share_it/screens/topic_detail_screen.dart';

void main() {
  for (final owner in [false, true]) {
    testWidgets(
        owner
            ? 'owner can edit and load followers'
            : 'follower can toggle follow and undo unfollow', (tester) async {
      var followRequests = 0;
      var deletes = 0;
      final client = ApiClient(client: MockClient((request) async {
        if (request.method == 'DELETE') {
          deletes++;
          return http.Response('', 204);
        }
        if (request.url.path.endsWith('/follows')) {
          followRequests++;
          return http.Response('{"records":[]}', 200);
        }
        return http.Response(
            jsonEncode({
              'id': 1,
              'token': 'piggy',
              'user_id': 2,
              'title': 'Family',
              'is_default': false,
              'created_at': '2026-01-01T12:00:00Z',
              'updated_at': '',
              'owner_name': 'Alex',
              'is_owner': owner,
              'followed_at': '2026-10-10T12:00:00Z',
            }),
            200);
      }));
      await tester.pumpWidget(ProviderScope(
          overrides: [
            topicRepositoryProvider
                .overrideWithValue(TopicRepository(apiClient: client)),
            subscriptionRepositoryProvider
                .overrideWithValue(SubscriptionRepository(apiClient: client)),
          ],
          child: MaterialApp(
              home: Builder(
                  builder: (context) => TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    const TopicDetailScreen(topicId: 1))),
                        child: const Text('Open'),
                      )))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsOneWidget);
      expect(followRequests, owner ? 1 : 0);
      expect(find.byIcon(Icons.edit_outlined),
          owner ? findsOneWidget : findsNothing);
      if (owner) {
        expect(find.text('Owner (you)'), findsOneWidget);
        expect(find.text('Unfollow'), findsNothing);
        await tester.ensureVisible(find.text('Delete piggy'));
        await tester.tap(find.text('Delete piggy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(deletes, 0);
        await tester.tap(find.text('Delete piggy'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(deletes, 1);
        expect(find.text('Open'), findsOneWidget);
      } else {
        expect(find.text('Delete piggy'), findsNothing);
        expect(find.text('Followed on'), findsOneWidget);
        expect(find.text('Oct 10, 2026'), findsOneWidget);
        await tester.tap(find.text('Unfollow'));
        await tester.pumpAndSettle();
        expect(deletes, 1);
        expect(find.text('Follow'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        expect(find.text('Not following'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(find.text('Unfollow'), findsOneWidget);
        expect(find.text('Following'), findsOneWidget);
        await tester.tap(find.text('Unfollow'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Follow'));
        await tester.pumpAndSettle();
        expect(find.text('Unfollow'), findsOneWidget);
        expect(deletes, 2);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
