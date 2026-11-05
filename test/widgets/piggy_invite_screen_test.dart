import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/models/topic_model.dart';
import 'package:share_it/screens/piggy_invite_screen.dart';

void main() {
  const topic = TopicModel(
      id: 1,
      token: 'test-piggy',
      userId: 1,
      title: 'Family Piggy',
      isDefault: true,
      createdAt: '',
      updatedAt: '');

  testWidgets('QR actions fit a small screen and code can be copied',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        home: PiggyInviteScreen(topic: topic, initialMode: InviteMode.yours)));
    await tester.pumpAndSettle();
    expect(find.text('Family Piggy'), findsOneWidget);
    expect(find.text('test-piggy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save QR'), findsOneWidget);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text('Copy code'));
    await tester.pumpAndSettle();
    expect(find.text('Code copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('code search rejects external links without opening subscription',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: PiggyInviteScreen(topic: topic, initialMode: InviteMode.text)));
    await tester.enterText(
        find.byType(TextField), 'https://example.com/topics/abc');
    await tester.pump();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a Piggy code or invitation link.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
