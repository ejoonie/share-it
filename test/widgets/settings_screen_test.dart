import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/design_system/theme.dart';
import 'package:share_it/providers/core_providers.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/session_repository.dart';
import 'package:share_it/repositories/topic_repository.dart';
import 'package:share_it/screens/settings_screen.dart';
import 'package:share_it/storage/token_storage.dart';

void main() {
  testWidgets('settings scrolls on a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storage = await TokenStorage.create();
    PackageInfo.setMockInitialValues(
        appName: 'Piggy',
        packageName: 'piggy',
        version: '1.1.1',
        buildNumber: '23',
        buildSignature: '');
    final client = ApiClient(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'records': [
                {
                  'id': 1,
                  'token': 'test',
                  'user_id': 1,
                  'title': 'Our family piggy for everyday expenses',
                  'is_default': true,
                  'created_at': '',
                  'updated_at': ''
                },
              ]
            }),
            200)));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          topicRepositoryProvider
              .overrideWithValue(TopicRepository(apiClient: client)),
          sessionNotifierProvider.overrideWith((ref) => SessionNotifier(
              repository:
                  SessionRepository(apiClient: client, tokenStorage: storage),
              tokenStorage: storage)),
        ],
        child: MaterialApp(
            theme: PiggyTheme.light,
            builder: (_, child) => MediaQuery(
                  data: const MediaQueryData(
                      size: Size(320, 700), textScaler: TextScaler.linear(1.6)),
                  child: child!,
                ),
            home: const SettingsScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(Divider), findsNothing);
    expect(find.text('My Subscriptions'), findsNothing);
    expect(find.text('Share Expenses'), findsNothing);
    await tester.scrollUntilVisible(find.text('Version 1.1.1 (23)'), 180);
    expect(find.text('Owner (you)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
