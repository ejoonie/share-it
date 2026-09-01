import '../api/api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({required apiClient}) : _apiClient = apiClient;

  Future<void> setEnabled(bool enabled) {
    return _apiClient
        .put('/api/v1/my/account/notifications', {'enabled': enabled});
  }
}
