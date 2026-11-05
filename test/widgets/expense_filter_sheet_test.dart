import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/models/expense_model.dart';
import 'package:share_it/models/topic_filter.dart';
import 'package:share_it/models/topic_model.dart';
import 'package:share_it/providers/core_providers.dart';
import 'package:share_it/providers/expense_provider.dart';
import 'package:share_it/storage/topic_filter_storage.dart';
import 'package:share_it/theme/app_theme.dart';
import 'package:share_it/widgets/expense/expense_filter_sheet.dart';

class _FilterNotifier extends ExpenseNotifier {
  _FilterNotifier(TopicFilterStorage storage, ExpenseState initial)
      : super(null, storage) {
    state = initial;
  }
}

const _topics = [
  TopicModel(
    id: 1,
    token: 'home',
    userId: 1,
    title: 'Home',
    isDefault: true,
    isOwner: true,
    createdAt: '',
    updatedAt: '',
  ),
  TopicModel(
    id: 2,
    token: 'travel',
    userId: 2,
    title: 'Travel',
    ownerName: 'Alex',
    isDefault: false,
    createdAt: '',
    updatedAt: '',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TopicFilterStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await TopicFilterStorage.create();
  });

  ExpenseState state({
    ExpenseType? type,
    TopicFilter topicFilter = const TopicFilterAll(),
  }) {
    final now = DateTime.now();
    return ExpenseState(
      focusedMonth: DateTime(now.year, now.month),
      year: now.year,
      month: now.month,
      day: now.day,
      monthlyExpenses: const [],
      selectedDateExpenses: const [],
      monthlySummary: const {},
      activeFilter: type,
      topicFilter: topicFilter,
    );
  }

  Future<_FilterNotifier> mount(
    WidgetTester tester, {
    ExpenseState? initial,
    Size size = const Size(402, 874),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = _FilterNotifier(storage, initial ?? state());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseNotifierProvider.overrideWith((ref) => notifier),
          myViewableTopicsProvider.overrideWith((ref) async => _topics),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (_) => const ExpenseFilterSheet(),
                  ),
                  child: const Text('Open filters'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    return notifier;
  }

  testWidgets('stages type and piggy choices until Apply filters',
      (tester) async {
    final notifier = await mount(tester);

    await tester.tap(find.text('Expenses'));
    await tester.tap(find.text('Travel'));
    await tester.pump();

    expect(notifier.state.activeFilter, isNull);
    expect(notifier.state.topicFilter, const TopicFilterAll());
    expect(find.text('1 of 2'), findsOneWidget);

    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(notifier.state.activeFilter, ExpenseType.expense);
    expect(notifier.state.topicFilter, const TopicFilterSelected({1}));
    expect(find.text('Filter transactions'), findsNothing);
  });

  testWidgets('closing the sheet discards staged changes', (tester) async {
    final notifier = await mount(tester);

    await tester.tap(find.text('Income'));
    await tester.tap(find.byTooltip('Close filters'));
    await tester.pumpAndSettle();

    expect(notifier.state.activeFilter, isNull);
    expect(notifier.state.topicFilter, const TopicFilterAll());
  });

  testWidgets('Reset restores the default filters when applied',
      (tester) async {
    final notifier = await mount(
      tester,
      initial: state(
        type: ExpenseType.expense,
        topicFilter: const TopicFilterSelected({2}),
      ),
    );

    expect(find.text('1 of 2'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('2 of 2'), findsOneWidget);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(notifier.state.activeFilter, isNull);
    expect(notifier.state.topicFilter, const TopicFilterAll());
  });

  testWidgets('keeps actions reachable on a small screen with large text',
      (tester) async {
    await mount(
      tester,
      size: const Size(320, 568),
      textScale: 1.35,
    );

    expect(find.text('Apply filters'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
