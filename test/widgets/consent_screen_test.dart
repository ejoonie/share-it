import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/models/user_model.dart';
import 'package:share_it/screens/consent_screen.dart';

void main() {
  testWidgets('consent screen opens the public policy URLs', (tester) async {
    const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');
    final launchedUrls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncher, (call) async {
      if (call.method == 'launch') {
        launchedUrls.add(
          (call.arguments as Map<Object?, Object?>)['url']! as String,
        );
        return true;
      }
      return false;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncher, null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ConsentScreen(
            user: UserModel(
              id: 1,
              email: 'test@example.com',
              nickName: 'Tester',
              isGuest: false,
              token: 'token',
              createdAt: '',
              updatedAt: '',
            ),
          ),
        ),
      ),
    );

    final richTexts = tester
        .widgetList<RichText>(find.byType(RichText))
        .where((widget) => widget.text.toPlainText().startsWith('I agree'));
    for (final richText in richTexts) {
      final link = (richText.text as TextSpan)
          .children!
          .cast<TextSpan>()
          .firstWhere((span) => span.recognizer != null);
      (link.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pump();
    }

    expect(
      launchedUrls,
      [
        'https://sharablepiggy.com/terms',
        'https://sharablepiggy.com/privacy',
      ],
    );
  });
}
