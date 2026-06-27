import '../../../../core/api/api_client.dart';
import '../../../../core/models/topic_model.dart';

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

  Future<List<TopicModel>> fetchAll() async {
    final json = await _apiClient.get(
      '/api/v1/my/topics/subscribed',
      authToken: _authToken,
    );
    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> unsubscribe(int topicId) async {
    await _apiClient.delete(
      '/api/v1/my/topics/subscribed/$topicId',
      authToken: _authToken,
    );
  }
}
