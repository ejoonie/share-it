import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/models/user_model.dart';

void main() {
  group('UserModel', () {
    final Map<String, dynamic> guestJson = {
      'id': 1,
      'email': 'abc123@example.com',
      'nick_name': 'Guest-abc123',
      'is_guest': true,
      'token': 'auth_token_xyz',
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-06-01T00:00:00.000Z',
    };

    final Map<String, dynamic> regularJson = {
      'id': 2,
      'email': 'user@example.com',
      'nick_name': 'Alice',
      'is_guest': false,
      'token': 'auth_token_abc',
      'created_at': '2026-05-01T00:00:00.000Z',
      'updated_at': '2026-05-10T00:00:00.000Z',
    };

    group('fromJson', () {
      test('파싱 - 게스트 유저', () {
        final model = UserModel.fromJson(guestJson);

        expect(model.id, 1);
        expect(model.email, 'abc123@example.com');
        expect(model.nickName, 'Guest-abc123');
        expect(model.isGuest, true);
        expect(model.token, 'auth_token_xyz');
        expect(model.createdAt, '2026-06-01T00:00:00.000Z');
        expect(model.updatedAt, '2026-06-01T00:00:00.000Z');
      });

      test('파싱 - 일반 유저', () {
        final model = UserModel.fromJson(regularJson);

        expect(model.id, 2);
        expect(model.email, 'user@example.com');
        expect(model.nickName, 'Alice');
        expect(model.isGuest, false);
        expect(model.token, 'auth_token_abc');
      });

      test('파싱 - nick_name 매핑 (snake_case → camelCase)', () {
        final model = UserModel.fromJson(guestJson);
        expect(model.nickName, isNotEmpty);
      });
    });
  });
}

