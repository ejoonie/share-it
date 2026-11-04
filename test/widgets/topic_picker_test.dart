import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/models/topic_model.dart';
import 'package:share_it/widgets/topic_picker.dart';

TopicModel _topic({required int id, bool isDefault = false}) {
  return TopicModel(
    id: id,
    token: 'token-$id',
    userId: 1,
    title: 'Topic $id',
    isDefault: isDefault,
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  group('resolveDefaultTopicId', () {
    test('토픽 목록이 비어 있으면 null', () {
      expect(resolveDefaultTopicId(const []), isNull);
    });

    test('lastUsedTopicId가 없으면 is_default 토픽을 고른다', () {
      final topics = [
        _topic(id: 1),
        _topic(id: 2, isDefault: true),
        _topic(id: 3),
      ];

      expect(resolveDefaultTopicId(topics), 2);
    });

    test('is_default 토픽도 없으면 첫 번째 토픽을 고른다', () {
      final topics = [_topic(id: 1), _topic(id: 2)];

      expect(resolveDefaultTopicId(topics), 1);
    });

    test('lastUsedTopicId가 목록에 있으면 is_default보다 우선한다', () {
      final topics = [
        _topic(id: 1),
        _topic(id: 2, isDefault: true),
        _topic(id: 3),
      ];

      expect(
        resolveDefaultTopicId(topics, lastUsedTopicId: 3),
        3,
      );
    });

    test('lastUsedTopicId가 목록에 없으면 무시하고 is_default를 고른다', () {
      final topics = [
        _topic(id: 1),
        _topic(id: 2, isDefault: true),
      ];

      expect(
        resolveDefaultTopicId(topics, lastUsedTopicId: 999),
        2,
      );
    });
  });

  group('resolveEntryTopicId', () {
    final topics = [
      _topic(id: 1),
      _topic(id: 2, isDefault: true),
      _topic(id: 3),
    ];

    test('사용자가 직접 선택한 토픽을 가장 먼저 사용한다', () {
      expect(
        resolveEntryTopicId(
          topics,
          selectedTopicId: 3,
          currentTopicId: 1,
          lastUsedTopicId: 2,
        ),
        3,
      );
    });

    test('직접 선택하지 않았으면 현재 보고 있는 토픽을 사용한다', () {
      expect(
        resolveEntryTopicId(
          topics,
          currentTopicId: 1,
          lastUsedTopicId: 3,
        ),
        1,
      );
    });

    test('접근할 수 없는 현재 토픽은 건너뛰고 마지막 사용 토픽을 사용한다', () {
      expect(
        resolveEntryTopicId(
          topics,
          currentTopicId: 99,
          lastUsedTopicId: 3,
        ),
        3,
      );
    });
  });
}
