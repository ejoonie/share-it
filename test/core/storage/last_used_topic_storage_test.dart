import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/storage/last_used_topic_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastUsedTopicStorage', () {
    test('아무것도 저장하지 않았으면 null을 반환한다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LastUsedTopicStorage.create();

      expect(storage.getLastUsedTopicId(), isNull);
    });

    test('저장한 토픽 id를 다시 읽을 수 있다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LastUsedTopicStorage.create();

      await storage.saveLastUsedTopicId(42);

      expect(storage.getLastUsedTopicId(), 42);
    });

    test('다시 저장하면 이전 값을 덮어쓴다', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LastUsedTopicStorage.create();

      await storage.saveLastUsedTopicId(1);
      await storage.saveLastUsedTopicId(2);

      expect(storage.getLastUsedTopicId(), 2);
    });
  });
}
