import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/models/topic_filter.dart';
import 'package:share_it/storage/topic_filter_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TopicFilterStorage', () {
    test('아무것도 저장하지 않았으면 All을 반환한다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TopicFilterStorage.create();

      expect(storage.getFilter(), equals(const TopicFilterAll()));
    });

    test('None을 저장하고 다시 읽으면 None이다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TopicFilterStorage.create();

      await storage.saveFilter(const TopicFilterNone());

      expect(storage.getFilter(), equals(const TopicFilterNone()));
    });

    test('Selected를 저장하고 다시 읽으면 같은 topicId 집합이다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TopicFilterStorage.create();

      await storage.saveFilter(const TopicFilterSelected({3, 1, 2}));

      expect(
        storage.getFilter(),
        equals(const TopicFilterSelected({1, 2, 3})),
      );
    });

    test('All을 저장하면 이전에 저장된 값이 지워진다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await TopicFilterStorage.create();

      await storage.saveFilter(const TopicFilterSelected({1, 2}));
      await storage.saveFilter(const TopicFilterAll());

      expect(storage.getFilter(), equals(const TopicFilterAll()));
    });
  });
}
