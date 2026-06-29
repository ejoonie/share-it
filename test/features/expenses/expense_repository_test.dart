import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/models/entry_model.dart';
import 'package:share_it/repositories/entry_repository.dart';
import 'package:share_it/repositories/expense_repository.dart';

// stub EntryRepository that returns a fixed list of entries
class _StubEntryRepository extends EntryRepository {
  final List<EntryModel> _entries;

  _StubEntryRepository(this._entries)
      : super(
          apiClient: ApiClient(),
          topicId: 0,
          authToken: '',
        );

  @override
  Future<List<EntryModel>> listEntries({Map<String, dynamic>? q, int page = 1, int limit = 100}) async => _entries;
}

EntryModel _makeEntry({
  required DateTime occurredAt,
  String kind = 'expense',
  int amount = 1000,
}) {
  return EntryModel(
    id: 1,
    topicId: 1,
    createdById: 1,
    occurredAt: occurredAt,
    kind: kind,
    amount: amount,
    createdAt: occurredAt,
    updatedAt: occurredAt,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // timezone 관련 집계 버그 테스트 (이슈 #37)
  //
  // 서버에서 UTC ISO 문자열로 내려온 occurred_at 을 파싱하면 UTC DateTime 이 된다.
  // 집계/필터링 시 반드시 로컬 날짜 기준으로 처리해야 달력 서머리와 레코드 날짜가 일치한다.
  // ---------------------------------------------------------------------------
  group('ExpenseRepository - timezone 집계 (이슈 #37)', () {
    late ExpenseRepository repo;

    // UTC 8일 06:30 (로컬 UTC-4 기준: 30일 20:30)
    final utcDateTime = DateTime.utc(2026, 7, 1, 0, 30); // 7/1 00:30 UTC, 6/30 20:30 -0400

    setUp(() {
      repo = ExpenseRepository(
        entryRepository: _StubEntryRepository([
          _makeEntry(occurredAt: utcDateTime, kind: 'expense', amount: 5000),
        ]),
      );
    });

    test('getMonthlySummary 는 로컬 날짜 기준으로 키를 생성해야 한다', () async {
      final localDate = utcDateTime.toLocal();
      final summary =
          await repo.getMonthlySummary(localDate.year, localDate.month);

      // 로컬 날짜 키가 맵에 존재해야 한다
      final expectedKey =
          DateTime(localDate.year, localDate.month, localDate.day);
      expect(
        summary.containsKey(expectedKey),
        isTrue,
        reason: 'summary 는 로컬 날짜($expectedKey) 키를 가져야 한다',
      );

      // UTC 날짜 키는 존재하면 안 된다 (로컬과 다른 경우)
      final utcKey = DateTime(utcDateTime.year, utcDateTime.month, utcDateTime.day);
      if (utcKey != expectedKey) {
        expect(
          summary.containsKey(utcKey),
          isFalse,
          reason: 'UTC 날짜($utcKey) 키가 아닌 로컬 날짜 키여야 한다',
        );
      }
    });

    test('getExpensesByMonth 는 로컬 월 기준으로 필터링해야 한다', () async {
      final localDate = utcDateTime.toLocal();
      final expenses =
          await repo.getExpensesByMonth(localDate.year, localDate.month);

      expect(
        expenses,
        isNotEmpty,
        reason: '로컬 월(${localDate.month}) 기준으로 조회하면 결과가 있어야 한다',
      );
    });

    test('getExpensesByMonth 는 로컬 월로 조회하면 결과가 있어야 한다', () async {
      final localDate = utcDateTime.toLocal();
      final byLocal =
          await repo.getExpensesByMonth(localDate.year, localDate.month);
      expect(byLocal, isNotEmpty);
      // 서버사이드 필터(ransack)가 UTC 범위로 처리하므로, 잘못된 월로 조회 시 빈 결과를 반환하는
      // 검증은 통합 테스트에서 확인한다.
    });

    test('getMonthlySummary 와 getExpensesByDate 날짜 기준이 일치해야 한다', () async {
      final localDate = utcDateTime.toLocal();
      final summary =
          await repo.getMonthlySummary(localDate.year, localDate.month);

      // 서머리에 표시된 날짜에 getExpensesByDate 로 조회하면 레코드가 있어야 한다
      for (final entry in summary.entries) {
        final date = entry.key;
        final dayExpenses = await repo.getExpensesByDate(date.year, date.month, date.day);
        expect(
          dayExpenses,
          isNotEmpty,
          reason: '서머리 키 $date 에 해당하는 레코드가 getExpensesByDate 에서도 반환돼야 한다',
        );
      }
    });
  });

  group('ExpenseRepository - getExpensesByDate', () {
    test('UTC DateTime 으로 저장된 항목이 로컬 날짜로 조회된다', () async {
      final utcDt = DateTime.utc(2026, 6, 8, 1, 0); // UTC 8일 1시
      final repo = ExpenseRepository(
        entryRepository: _StubEntryRepository([
          _makeEntry(occurredAt: utcDt, kind: 'expense', amount: 3000),
        ]),
      );

      final localDt = utcDt.toLocal();
      final result = await repo.getExpensesByDate(
        localDt.year, localDt.month, localDt.day,
      );

      expect(result, hasLength(1));
    });

    test('로컬 자정 경계에서 UTC 날짜와 다를 때 올바른 날짜에 포함된다', () async {
      // UTC+9 환경에서 로컬 7일 23:30 = UTC 8일 14:30
      // → 로컬 기준 7일로 조회해야 포함돼야 함
      final utcDt = DateTime.utc(2026, 7, 8, 14, 30);
      final repo = ExpenseRepository(
        entryRepository: _StubEntryRepository([
          _makeEntry(occurredAt: utcDt, kind: 'expense', amount: 2000),
        ]),
      );

      final localDt = utcDt.toLocal();
      final localDay = DateTime(localDt.year, localDt.month, localDt.day);

      // 로컬 날짜로 조회 → 있어야 함
      final result = await repo.getExpensesByDate(localDay.year, localDay.month, localDay.day);
      expect(result, hasLength(1),
          reason: '로컬 날짜 기준($localDay)으로 조회하면 결과가 있어야 한다');

      // UTC 날짜(다를 경우)로 조회 → 없어야 함
      final utcDay = DateTime(utcDt.year, utcDt.month, utcDt.day);
      if (utcDay != localDay) {
        final wrongResult = await repo.getExpensesByDate(utcDay.year, utcDay.month, utcDay.day);
        expect(wrongResult, isEmpty,
            reason: 'UTC 날짜 기준($utcDay)으로 조회하면 결과가 없어야 한다');
      }
    });

    // UTC 날짜로 조회 시 빈 결과 검증은 서버사이드(ransack) 필터링 동작이므로
    // 통합 테스트에서 확인한다.
  });
}
