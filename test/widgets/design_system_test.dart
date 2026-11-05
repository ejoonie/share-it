import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/design_system/design_system.dart';
import 'package:share_it/screens/design_system_screen.dart';

void main() {
  test('semantic foreground/background pairs keep readable contrast', () {
    final pairs = <(Color, Color)>[
      (PiggyColors.ink, PiggyColors.background),
      (PiggyColors.secondary, PiggyColors.background),
      (PiggyColors.secondary, PiggyColors.surface),
      (PiggyColors.ink, PiggyColors.card),
      (PiggyColors.secondary, PiggyColors.card),
      (Colors.white, PiggyColors.accent),
      (PiggyColors.accent, PiggyColors.accentSoft),
      (PiggyColors.income, PiggyColors.incomeSoft),
      (PiggyColors.expense, PiggyColors.expenseSoft),
      (PiggyColors.error, PiggyColors.errorSoft),
      (PiggyColors.success, PiggyColors.successSoft),
      (PiggyColors.warning, PiggyColors.warningSoft),
    ];
    for (final (foreground, background) in pairs) {
      final a = foreground.computeLuminance();
      final b = background.computeLuminance();
      final contrast = ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: '$foreground on $background',
      );
    }
  });

  Future<void> mount(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: PiggyTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const DesignSystemScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('catalog remains scrollable at 320 pt with 160% text',
      (tester) async {
    await mount(tester, scale: 1.6);
    expect(tester.takeException(), isNull);
    for (var step = 0; step < 45; step++) {
      if (find
          .text('10 · Spacing & shape')
          .hitTestable()
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('10 · Spacing & shape').hitTestable(), findsOneWidget);
  });

  testWidgets('catalog exposes input errors and interactive calendar states',
      (tester) async {
    await mount(tester);
    await tester.scrollUntilVisible(
      find.text('Show validation error'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Show validation error'));
    await tester.pumpAndSettle();
    expect(find.text('Add a title to continue.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('06 · Calendar states'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final marker = find.byWidgetPredicate(
      (widget) => widget is PiggyDayMarker && widget.day == 4,
    );
    await tester.ensureVisible(marker);
    await tester.pumpAndSettle();
    await tester.tap(marker);
    await tester.pumpAndSettle();
    expect(tester.widget<PiggyDayMarker>(marker).selected, isTrue);
    expect(tester.widget<PiggyDayMarker>(marker).today, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled add action does not fire and keeps a full hit target',
      (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PiggyTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              PiggyAddButton(tooltip: 'Enabled add', onPressed: () => count++),
              const PiggyAddButton(tooltip: 'Disabled add', onPressed: null),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Disabled add'));
    expect(count, 0);
    await tester.tap(find.byTooltip('Enabled add'));
    expect(count, 1);
    final size = tester.getSize(find.byTooltip('Enabled add'));
    expect(size.width, greaterThanOrEqualTo(PiggySize.tapTarget));
    expect(size.height, greaterThanOrEqualTo(PiggySize.tapTarget));
  });
}
