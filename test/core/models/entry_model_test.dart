import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/core/models/entry_model.dart';

void main() {
  group('EntryModel', () {
    // ---------------------------------------------------------------------------
    // Fixtures
    // ---------------------------------------------------------------------------

    final Map<String, dynamic> fullJson = {
      'id': 1,
      'topic_id': 42,
      'created_by_id': 7,
      'updated_by_id': 8,
      'occurred_at': '2026-06-07T12:00:00.000Z',
      'kind': 'expense',
      'currency': 'krw',
      'amount': 15000,
      'category': 'food',
      'title': '점심',
      'content': '팀 점심 식사',
      'checked': false,
      'deleted_at': null,
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-06-02T00:00:00.000Z',
    };

    final Map<String, dynamic> minimalJson = {
      'id': 2,
      'topic_id': 10,
      'created_by_id': 3,
      'updated_by_id': null,
      'occurred_at': null,
      'kind': null,
      'currency': null,   // should fallback to 'usd'
      'amount': null,     // should fallback to 0
      'category': null,
      'title': null,
      'content': null,
      'checked': null,    // should fallback to false
      'deleted_at': null,
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-06-01T00:00:00.000Z',
    };

    // ---------------------------------------------------------------------------
    // fromJson — full payload
    // ---------------------------------------------------------------------------

    group('fromJson', () {
      test('파싱 - 전체 필드', () {
        final model = EntryModel.fromJson(fullJson);

        expect(model.id, 1);
        expect(model.topicId, 42);
        expect(model.createdById, 7);
        expect(model.updatedById, 8);
        expect(model.occurredAt, DateTime.parse('2026-06-07T12:00:00.000Z'));
        expect(model.kind, 'expense');
        expect(model.currency, 'krw');
        expect(model.amount, 15000);
        expect(model.category, 'food');
        expect(model.title, '점심');
        expect(model.content, '팀 점심 식사');
        expect(model.checked, false);
        expect(model.deletedAt, isNull);
        expect(model.createdAt, DateTime.parse('2026-06-01T00:00:00.000Z'));
        expect(model.updatedAt, DateTime.parse('2026-06-02T00:00:00.000Z'));
      });

      test('파싱 - nullable 필드 null', () {
        final model = EntryModel.fromJson(minimalJson);

        expect(model.updatedById, isNull);
        expect(model.occurredAt, isNull);
        expect(model.kind, isNull);
        expect(model.category, isNull);
        expect(model.title, isNull);
        expect(model.content, isNull);
        expect(model.deletedAt, isNull);
      });

      test('파싱 - 기본값 fallback (currency, amount, checked)', () {
        final model = EntryModel.fromJson(minimalJson);

        expect(model.currency, 'usd');
        expect(model.amount, 0);
        expect(model.checked, false);
      });

      test('파싱 - deleted_at 있을 때', () {
        final json = Map<String, dynamic>.from(fullJson)
          ..['deleted_at'] = '2026-06-08T09:00:00.000Z';
        final model = EntryModel.fromJson(json);

        expect(model.deletedAt, DateTime.parse('2026-06-08T09:00:00.000Z'));
      });

      test('파싱 - checked true', () {
        final json = Map<String, dynamic>.from(fullJson)..['checked'] = true;
        final model = EntryModel.fromJson(json);

        expect(model.checked, true);
      });

      test('파싱 - todo kind', () {
        final json = Map<String, dynamic>.from(fullJson)..['kind'] = 'todo';
        final model = EntryModel.fromJson(json);

        expect(model.kind, 'todo');
      });
    });

    // ---------------------------------------------------------------------------
    // copyWith
    // ---------------------------------------------------------------------------

    group('copyWith', () {
      late EntryModel base;

      setUp(() => base = EntryModel.fromJson(fullJson));

      test('변경 없이 호출하면 동일한 값 유지', () {
        final copy = base.copyWith();

        expect(copy.id, base.id);
        expect(copy.topicId, base.topicId);
        expect(copy.createdById, base.createdById);
        expect(copy.updatedById, base.updatedById);
        expect(copy.kind, base.kind);
        expect(copy.currency, base.currency);
        expect(copy.amount, base.amount);
        expect(copy.checked, base.checked);
      });

      test('checked 변경', () {
        final copy = base.copyWith(checked: true);
        expect(copy.checked, true);
        expect(copy.id, base.id); // 나머지 유지
      });

      test('amount, currency 변경', () {
        final copy = base.copyWith(amount: 99999, currency: 'usd');
        expect(copy.amount, 99999);
        expect(copy.currency, 'usd');
      });

      test('nullable 필드 null로 변경 - updatedById', () {
        final copy = base.copyWith(updatedById: () => null);
        expect(copy.updatedById, isNull);
      });

      test('nullable 필드 null로 변경 - deletedAt', () {
        final copy = base.copyWith(deletedAt: () => null);
        expect(copy.deletedAt, isNull);
      });

      test('nullable 필드 null로 변경 - kind', () {
        final copy = base.copyWith(kind: () => null);
        expect(copy.kind, isNull);
      });

      test('title, content 변경', () {
        final copy = base.copyWith(
          title: () => '저녁',
          content: () => '혼밥',
        );
        expect(copy.title, '저녁');
        expect(copy.content, '혼밥');
      });

      test('createdById 변경', () {
        final copy = base.copyWith(createdById: 99);
        expect(copy.createdById, 99);
      });

      test('occurredAt 변경', () {
        final newDate = DateTime(2026, 1, 1);
        final copy = base.copyWith(occurredAt: () => newDate);
        expect(copy.occurredAt, newDate);
      });
    });
  });
}

