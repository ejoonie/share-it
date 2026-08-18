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
}
