import '../../../../core/api/api_client.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;
  final String _authToken;

  SubscriptionRepository({
    required ApiClient apiClient,
    required String authToken,
  })  : _apiClient = apiClient,
        _authToken = authToken;

  Future<void> subscribe(String topicToken) async {
    await _apiClient.post(
      '/api/v1/subscriptions',
      {'topic_token': topicToken},
      authToken: _authToken,
    );
  }
}
