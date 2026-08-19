import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/models/entry_model.dart';
import 'package:share_it/providers/expense_provider.dart';
import 'package:share_it/repositories/entry_repository.dart';
import 'package:share_it/repositories/expense_repository.dart';
import 'package:share_it/storage/topic_filter_storage.dart';

// stub EntryRepository that returns an empty list for every query.
class _StubEntryRepository extends EntryRepository {
  _StubEntryRepository() : super(apiClient: ApiClient(), topicId: 0);

  @override
  Future<List<EntryModel>> listEntries({Map<String, dynamic>? q, int page = 1, int limit = 100}) async => [];

  @override
  Future<List<EntryModel>> listAllEntries({
    List<int>? topicIds,
    Map<String, dynamic>? q,
    int page = 1,
    int limit = 100,
  }) async => [];
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

    test('말일로 대체된 뒤 다시 일수가 넉넉한 달로 이동하면 원래 유지되던 일수만큼 이동하지 않고 현재(대체된) 일을 기준으로 이동한다', () async {
      // 1/31 -> 2/28(대체) -> 3월(31일까지 있음): 2/28 기준으로 이동하므로 3/28이어야 함
      await notifier.selectDate(2026, 1, 31);
      await notifier.changeMonth(DateTime(2026, 2));
      expect(notifier.state.day, 28);

      await notifier.changeMonth(DateTime(2026, 3));
      expect(notifier.state.day, 28);
    });
  });
}
