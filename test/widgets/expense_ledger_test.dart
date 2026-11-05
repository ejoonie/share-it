import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/models/expense_model.dart';
import 'package:share_it/models/topic_model.dart';
import 'package:share_it/providers/core_providers.dart';
import 'package:share_it/providers/expense_provider.dart';
import 'package:share_it/screens/expense_screen.dart';
import 'package:share_it/storage/topic_filter_storage.dart';
import 'package:share_it/theme/app_theme.dart';
import 'package:share_it/theme/ledger_style.dart';
import 'package:share_it/widgets/main_navigation_shell.dart';

class PreviewNotifier extends ExpenseNotifier {
  PreviewNotifier(TopicFilterStorage storage, ExpenseState initial)
      : super(null, storage) {
    state = initial;
  }
}

class ExpenseChromeHarness extends StatefulWidget {
  const ExpenseChromeHarness({super.key});

  @override
  State<ExpenseChromeHarness> createState() => _ExpenseChromeHarnessState();
}

class _ExpenseChromeHarnessState extends State<ExpenseChromeHarness> {
  bool visible = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ExpenseScreen(
          chromeVisible: visible,
          onChromeVisibilityChanged: (next) => setState(() => visible = next),
        ),
        floatingActionButton: visible
            ? FloatingActionButton(
                tooltip: 'Add transaction',
                onPressed: () {},
                child: const Icon(Icons.add_rounded),
              )
            : null,
        bottomNavigationBar:
            visible ? AppNavigationBar(currentIndex: 0, onTap: (_) {}) : null,
      );
}

void main() {
  final boundaryKey = GlobalKey();
  final now = DateTime.now();
  final chosen = DateTime(now.year, now.month, now.day == 1 ? 2 : now.day - 1);
  final items = [
    ExpenseModel(
      id: 1,
      topicId: 1,
      title: 'Lunch with friends',
      category: 'Food',
      amount: 1200,
      occurredAt: chosen,
    ),
    ExpenseModel(
      id: 2,
      topicId: 1,
      title: 'Afternoon coffee',
      category: 'Cafe',
      amount: 1001,
      occurredAt: chosen,
    ),
  ];
  final fixture = ExpenseState(
    focusedMonth: DateTime(chosen.year, chosen.month),
    year: chosen.year,
    month: chosen.month,
    day: chosen.day,
    monthlyExpenses: [
      ...items,
      ExpenseModel(
        title: 'Salary',
        amount: 280000,
        type: ExpenseType.income,
        occurredAt: chosen,
      ),
    ],
    selectedDateExpenses: items,
    monthlySummary: {
      chosen: {'income': 280000, 'expense': 2201},
    },
  );

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(402, 874),
    double scale = 1,
    ExpenseState? state,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storage = await TopicFilterStorage.create();
    final fontPath = Platform.environment['LEDGER_PREVIEW_FONT'];
    if (fontPath != null) {
      await tester.runAsync(() async {
        final loader = FontLoader('Ahem');
        loader.addFont(
          File(fontPath)
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
        await loader.load();
        final iconPath = Platform.environment['LEDGER_PREVIEW_ICONS'];
        if (iconPath != null) {
          final icons = FontLoader('MaterialIcons');
          icons.addFont(
            File(iconPath)
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)),
          );
          await icons.load();
        }
      });
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseNotifierProvider.overrideWith(
            (ref) => PreviewNotifier(storage, state ?? fixture),
          ),
          myViewableTopicsProvider.overrideWith(
            (ref) async => [
              const TopicModel(
                id: 1,
                token: '',
                userId: 1,
                title: 'My First Piggy',
                isDefault: true,
                createdAt: '',
                updatedAt: '',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: fontPath == null
              ? AppTheme.lightTheme
              : AppTheme.lightTheme.copyWith(
                  textTheme:
                      AppTheme.lightTheme.textTheme.apply(fontFamily: 'Ahem'),
                ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: boundaryKey,
            child: const ExpenseChromeHarness(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'selected date and today have distinct indicators; both totals remain readable',
      (tester) async {
    await mount(tester);
    String keyFor(DateTime d) =>
        'calendar-day-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final selected =
        tester.widget<Container>(find.byKey(ValueKey(keyFor(chosen))));
    final today = tester.widget<Container>(find.byKey(ValueKey(keyFor(now))));
    expect((selected.decoration! as BoxDecoration).color, LedgerStyle.accent);
    final todayBorder = (today.decoration! as BoxDecoration).border! as Border;
    expect(todayBorder.top.color, LedgerStyle.expense);
    expect(find.text('\$0.00'), findsOneWidget);
    expect(find.text('\$22.01'), findsOneWidget);
    expect(find.text('−\$12.00'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('−\$12.00')).style!.color,
      LedgerStyle.expense,
    );
    expect(tester.takeException(), isNull);
    final output = Platform.environment['LEDGER_PREVIEW_PATH'];
    if (output != null) {
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets('scroll direction hides and restores the FAB and navigation',
      (tester) async {
    await mount(tester, size: const Size(320, 640));
    final add = find.byTooltip('Add transaction');
    final navigation = find.byType(NavigationBar);
    expect(add.hitTestable(), findsOneWidget);
    expect(navigation.hitTestable(), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(add.hitTestable(), findsNothing);
    expect(navigation.hitTestable(), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(add.hitTestable(), findsOneWidget);
    expect(navigation.hitTestable(), findsOneWidget);
  });

  testWidgets(
      'small screen and large text scroll to transactions without overflow',
      (tester) async {
    await mount(tester, size: const Size(320, 640), scale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Lunch with friends'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lunch with friends'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await Scrollable.ensureVisible(
      tester.element(find.byTooltip('Transaction options').first),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Transaction options').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets(
      'search and empty state remain available in the new scroll layout',
      (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Search transactions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unmatched');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('No matching transactions'), findsOneWidget);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch with friends'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
