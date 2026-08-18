import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/models/topic_filter.dart';

void main() {
  group('TopicFilter.isSelected', () {
    test('All은 어떤 topicId든 선택된 것으로 취급한다', () {
      const filter = TopicFilterAll();
      expect(filter.isSelected(1), isTrue);
      expect(filter.isSelected(999), isTrue);
    });

    test('None은 어떤 topicId도 선택되지 않은 것으로 취급한다', () {
      const filter = TopicFilterNone();
      expect(filter.isSelected(1), isFalse);
    });

    test('Selected는 포함된 topicId만 선택된 것으로 취급한다', () {
      const filter = TopicFilterSelected({1, 2});
      expect(filter.isSelected(1), isTrue);
      expect(filter.isSelected(2), isTrue);
      expect(filter.isSelected(3), isFalse);
    });
  });

  group('TopicFilter.queryTopicIds', () {
    test('All은 null(필터 없음)을 반환한다', () {
      expect(const TopicFilterAll().queryTopicIds, isNull);
    });

    test('None은 빈 리스트를 반환한다', () {
      expect(const TopicFilterNone().queryTopicIds, isEmpty);
    });

    test('Selected는 선택된 topicId 리스트를 반환한다', () {
      expect(
        const TopicFilterSelected({3, 1, 2}).queryTopicIds,
        containsAll([1, 2, 3]),
      );
    });
  });

  group('TopicFilter.includingTopic', () {
    test('All은 그대로 유지된다 (이미 전체가 선택된 상태)', () {
      const filter = TopicFilterAll();
      expect(filter.includingTopic(1), equals(const TopicFilterAll()));
    });

    test('None에 토픽을 포함시키면 해당 토픽만 선택된 Selected가 된다', () {
      const filter = TopicFilterNone();
      expect(
        filter.includingTopic(5),
        equals(const TopicFilterSelected({5})),
      );
    });

    test('Selected에 새 토픽을 추가하면 기존 선택에 더해진다', () {
      const filter = TopicFilterSelected({1, 2});
      expect(
        filter.includingTopic(3),
        equals(const TopicFilterSelected({1, 2, 3})),
      );
    });

    test('Selected에 이미 포함된 토픽을 추가하면 변화가 없다', () {
      const filter = TopicFilterSelected({1, 2});
      expect(filter.includingTopic(1), equals(filter));
    });
  });

  group('TopicFilter equality', () {
    test('같은 종류의 All/None은 서로 같다', () {
      expect(const TopicFilterAll(), equals(const TopicFilterAll()));
      expect(const TopicFilterNone(), equals(const TopicFilterNone()));
    });

    test('Selected는 원소가 같으면 순서와 무관하게 같다', () {
      expect(
        const TopicFilterSelected({1, 2, 3}),
        equals(const TopicFilterSelected({3, 2, 1})),
      );
    });

    test('Selected는 원소가 다르면 다르다', () {
      expect(
        const TopicFilterSelected({1, 2}),
        isNot(equals(const TopicFilterSelected({1, 2, 3}))),
      );
    });
  });
}
