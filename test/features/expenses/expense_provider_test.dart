import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/models/entry_model.dart';
import 'package:share_it/models/topic_filter.dart';
import 'package:share_it/providers/expense_provider.dart';
import 'package:share_it/repositories/entry_repository.dart';
import 'package:share_it/repositories/expense_repository.dart';
import 'package:share_it/storage/topic_filter_storage.dart';

// stub EntryRepository that returns an empty list for every query.
class _StubEntryRepository extends EntryRepository {
  final EntryModel? entry;
  final Object? getEntryError;

  _StubEntryRepository({this.entry, this.getEntryError})
      : super(apiClient: ApiClient(), topicId: 0);

  @override
  Future<List<EntryModel>> listEntries({
    Map<String, dynamic>? q,
    int page = 1,
    int limit = 100,
  }) async =>
      [];

  @override
  Future<List<EntryModel>> listAllEntries({
    List<int>? topicIds,
    Map<String, dynamic>? q,
    int page = 1,
    int limit = 100,
  }) async =>
      entry == null ? [] : [entry!];

  @override
  Future<EntryModel> getEntry(int id) async {
    if (getEntryError case final error?) throw error;
    return entry!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseNotifier.changeMonth - 선택된 날짜 유지 (이슈 요청)', () {
    late ExpenseNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TopicFilterStorage.create();
      final repo = ExpenseRepository(entryRepository: _StubEntryRepository());
      notifier = ExpenseNotifier(repo, storage);
      // 초기 load()가 오늘 날짜로 선택 상태를 세팅하므로, 테스트용 날짜로 덮어쓴다.
    });

    test('같은 일(day)이 다음 달에도 있으면 그대로 유지한다 (8/15 → 9/15)', () async {
      await notifier.selectDate(2026, 8, 15);

      await notifier.changeMonth(DateTime(2026, 9));

      expect(notifier.state.year, 2026);
      expect(notifier.state.month, 9);
      expect(notifier.state.day, 15);
    });

    test('다음 달에 그 일(day)이 없으면 마지막 날로 대체한다 (1/31 → 2월 28일)', () async {
      await notifier.selectDate(2026, 1, 31);

      await notifier.changeMonth(DateTime(2026, 2));

      expect(notifier.state.year, 2026);
      expect(notifier.state.month, 2);
      expect(notifier.state.day, 28); // 2026년은 윤년이 아님
    });

    test('31일 선택 후 30일까지인 달로 이동하면 30일로 대체한다 (3/31 → 4/30)', () async {
      await notifier.selectDate(2026, 3, 31);

      await notifier.changeMonth(DateTime(2026, 4));

      expect(notifier.state.day, 30);
    });

    test(
        '말일로 대체된 뒤 다시 일수가 넉넉한 달로 이동하면 원래 유지되던 일수만큼 이동하지 않고 현재(대체된) 일을 기준으로 이동한다',
        () async {
      // 1/31 -> 2/28(대체) -> 3월(31일까지 있음): 2/28 기준으로 이동하므로 3/28이어야 함
      await notifier.selectDate(2026, 1, 31);
      await notifier.changeMonth(DateTime(2026, 2));
      expect(notifier.state.day, 28);

      await notifier.changeMonth(DateTime(2026, 3));
      expect(notifier.state.day, 28);
    });
  });

  test('openEntry selects the linked topic and entry date', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await TopicFilterStorage.create();
    final occurredAt = DateTime.utc(2026, 9, 2, 15, 30);
    final entry = EntryModel(
      id: 918,
      topicId: 42,
      createdById: 1,
      occurredAt: occurredAt,
      kind: 'expense',
      amount: 1000,
      createdAt: occurredAt,
      updatedAt: occurredAt,
    );
    final notifier = ExpenseNotifier(
      ExpenseRepository(
        entryRepository: _StubEntryRepository(entry: entry),
      ),
      storage,
    );

    await notifier.openEntry(topicId: 42, entryId: 918);

    final localDate = occurredAt.toLocal();
    expect(notifier.state.topicFilter, const TopicFilterSelected({42}));
    expect(notifier.state.year, localDate.year);
    expect(notifier.state.month, localDate.month);
    expect(notifier.state.day, localDate.day);
    expect(notifier.state.selectedDateExpenses.single.id, 918);
  });

  test('openDate converts the UTC timestamp to the local calendar date',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await TopicFilterStorage.create();
    final occurredAt = DateTime.utc(2026, 9, 3, 1, 30);
    final entry = EntryModel(
      id: 918,
      topicId: 42,
      createdById: 1,
      occurredAt: occurredAt,
      kind: 'expense',
      amount: 1000,
      createdAt: occurredAt,
      updatedAt: occurredAt,
    );
    final notifier = ExpenseNotifier(
      ExpenseRepository(
        entryRepository: _StubEntryRepository(entry: entry),
      ),
      storage,
    );

    await notifier.openDate(topicId: 42, occurredAt: occurredAt);

    final localDate = occurredAt.toLocal();
    expect(notifier.state.topicFilter, const TopicFilterSelected({42}));
    expect(notifier.state.year, localDate.year);
    expect(notifier.state.month, localDate.month);
    expect(notifier.state.day, localDate.day);
  });

  test('openEntry shows a safe message when the entry is not accessible',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await TopicFilterStorage.create();
    final notifier = ExpenseNotifier(
      ExpenseRepository(
        entryRepository: _StubEntryRepository(
          getEntryError: const ApiException(
            statusCode: 404,
            message: 'Entry not found',
          ),
        ),
      ),
      storage,
    );

    await notifier.openEntry(topicId: 42, entryId: 918);

    expect(
      notifier.state.error,
      'This expense may have been deleted or you may no longer have access.',
    );
  });
}
