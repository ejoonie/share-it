import 'device_token_repository.dart';
import 'session_repository.dart';

class NotificationRepository {
  final DeviceTokenRepository _deviceTokens;
  final SessionRepository _session;

  NotificationRepository({
    required DeviceTokenRepository deviceTokens,
    required SessionRepository session,
  }) : _deviceTokens = deviceTokens,
       _session = session;

  Future<void> setEnabled(bool enabled) {
    return _session.updateNotificationsEnabled(enabled);
  }

  Future<void> registerToken({
    required String token,
    required String platform,
  }) {
    return _deviceTokens.register(token: token, platform: platform);
  }

  Future<void> unregisterToken(String token) {
    return _deviceTokens.unregister(token);
  }
}
