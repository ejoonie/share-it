import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/design_system/theme.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/session_repository.dart';
import 'package:share_it/screens/login_screen.dart';
import 'package:share_it/screens/change_password_screen.dart';
import 'package:share_it/widgets/verification_code_field.dart';
import 'package:share_it/storage/token_storage.dart';

class _Auth extends SessionRepository {
  bool newUser = true;
  bool failSend = true;
  int sends = 0;
  _Auth(TokenStorage storage)
      : super(apiClient: ApiClient(), tokenStorage: storage);
  @override
  Future<({bool isNewUser, bool hasPassword})> checkEmail(String email) async =>
      (isNewUser: newUser, hasPassword: !newUser);
  @override
  Future<void> requestPasswordChange() async {}
  @override
  Future<void> requestLoginCode(String email) async {
    sends++;
    if (failSend) throw Exception('offline');
  }
}

void main() {
  const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');

  Future<_Auth> open(WidgetTester tester, {bool newUser = true}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await TokenStorage.create();
    final repo = _Auth(storage)..newUser = newUser;
    await tester.pumpWidget(ProviderScope(overrides: [
      sessionRepositoryProvider.overrideWithValue(repo),
      sessionNotifierProvider.overrideWith(
          (_) => SessionNotifier(repository: repo, tokenStorage: storage)),
    ], child: MaterialApp(theme: PiggyTheme.light, home: const LoginScreen())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('new account can recover from a code delivery failure',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await open(tester);
    expect(find.text('Create account'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.descendant(
      of: find.byType(CheckboxListTile),
      matching: find.byType(Checkbox),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agree & continue'));
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Could not send the code. Please try again.'),
        findsOneWidget);
    repo.failSend = false;
    await tester.ensureVisible(find.text('Agree & continue'));
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();
    expect(find.text('Verify email'), findsOneWidget);
    expect(repo.sends, 2);
    expect(tester.getSize(find.byType(VerificationCodeField)).width, 280);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new account terms open the public policy URLs', (tester) async {
    final launchedUrls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncher, (call) async {
      if (call.method == 'launch') {
        launchedUrls
            .add((call.arguments as Map<Object?, Object?>)['url']! as String);
        return true;
      }
      return false;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncher, null));

    await open(tester);
    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Terms of Service'),
      ),
    );
    final spans = (richText.text as TextSpan).children!.cast<TextSpan>();

    (spans.firstWhere((span) => span.text == 'Terms of Service').recognizer
            as TapGestureRecognizer)
        .onTap!();
    await tester.pump();
    (spans.firstWhere((span) => span.text == 'Privacy Policy').recognizer
            as TapGestureRecognizer)
        .onTap!();
    await tester.pump();

    expect(
      launchedUrls,
      [
        'https://sharablepiggy.com/terms',
        'https://sharablepiggy.com/privacy',
      ],
    );
  });

  testWidgets('password and email-code methods share a recoverable flow',
      (tester) async {
    final repo = await open(tester, newUser: false);
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Use Password'));
    await tester.pumpAndSettle();
    expect(find.text('Enter password'), findsOneWidget);
    await tester.ensureVisible(find.text('Email me a code instead'));
    await tester.tap(find.text('Email me a code instead'));
    await tester.pumpAndSettle();
    expect(find.text('Could not send the code. Please try again.'),
        findsOneWidget);
    repo.failSend = false;
    await tester.ensureVisible(find.text('Email me a code instead'));
    await tester.tap(find.text('Email me a code instead'));
    await tester.pumpAndSettle();
    expect(find.text('Verify email'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('test@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'password change uses full-width code and password fields above a keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repo = _Auth(await TokenStorage.create());
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: PiggyTheme.light,
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 700),
                viewInsets: EdgeInsets.only(bottom: 250),
                textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const ChangePasswordScreen(),
        )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send Verification Code'));
    await tester.tap(find.text('Send Verification Code'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(VerificationCodeField)).width, 280);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('New password'), findsOneWidget);
    for (final field in find.byType(TextFormField).evaluate()) {
      expect(tester.getSize(find.byWidget(field.widget)).width, 280);
    }
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Change Password'));
    expect(tester.takeException(), isNull);
  });
}
