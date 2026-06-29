import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/models/topic_model.dart';

void main() {
  group('TopicModel', () {
    final Map<String, dynamic> fullJson = {
      'id': 1,
      'token': 'abc123token',
      'user_id': 7,
      'title': '✨ My First Space',
      'is_default': true,
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-06-02T00:00:00.000Z',
    };

    group('fromJson', () {
      test('파싱 - 전체 필드', () {
        final model = TopicModel.fromJson(fullJson);

        expect(model.id, 1);
        expect(model.token, 'abc123token');
        expect(model.userId, 7);
        expect(model.title, '✨ My First Space');
        expect(model.isDefault, true);
        expect(model.createdAt, '2026-06-01T00:00:00.000Z');
        expect(model.updatedAt, '2026-06-02T00:00:00.000Z');
      });

      test('파싱 - is_default false', () {
        final json = Map<String, dynamic>.from(fullJson)
          ..['is_default'] = false;
        final model = TopicModel.fromJson(json);

        expect(model.isDefault, false);
      });

      test('파싱 - 다른 토픽 id', () {
        final json = Map<String, dynamic>.from(fullJson)
          ..['id'] = 99
          ..['token'] = 'zzz999';
        final model = TopicModel.fromJson(json);

        expect(model.id, 99);
        expect(model.token, 'zzz999');
      });
    });
  });
}

