import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/design_system/theme.dart';
import 'package:share_it/models/bootstrap_response.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/session_repository.dart';
import 'package:share_it/screens/login_screen.dart';
import 'package:share_it/widgets/app_loading_indicator.dart';
import 'package:share_it/screens/welcome_screen.dart';
import 'package:share_it/storage/token_storage.dart';

class _Repository extends SessionRepository {
  _Repository(TokenStorage storage)
      : super(apiClient: ApiClient(), tokenStorage: storage);
  int loads = 0;
  @override
  Future<BootstrapResponse> loadData() async {
    loads++;
    return const BootstrapResponse(bootstrapCreated: false, entries: []);
  }
}

void main() {
  Future<({TokenStorage storage, _Repository repo})> open(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await TokenStorage.create();
    final repo = _Repository(storage);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
          sessionNotifierProvider.overrideWith(
            (_) => SessionNotifier(repository: repo, tokenStorage: storage),
          ),
        ],
        child: MaterialApp(
          theme: PiggyTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (storage: storage, repo: repo);
  }

  testWidgets('public welcome and cancelled login never bootstrap',
      (tester) async {
    final result = await open(tester);
    expect(result.repo.loads, 0);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(result.repo.loads, 0);
    expect(result.storage.getToken(), isNull);
  });

  testWidgets(
      'successful login reveals splash throughout the return transition',
      (tester) async {
    final result = await open(tester);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await result.storage.saveToken('authenticated');
    Navigator.of(tester.element(find.byType(LoginScreen))).pop(true);
    await tester.pump();
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.text('Little expenses.\nA clearer picture.'), findsNothing);
    expect(result.repo.loads, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(result.repo.loads, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(result.repo.loads, 1);
  });

  testWidgets('small screen and enlarged text keep the CTA reachable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, textScale: 1.6);
    await tester.scrollUntilVisible(find.text('Get started'), 200);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
