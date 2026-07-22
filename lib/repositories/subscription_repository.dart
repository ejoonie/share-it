import '../api/api_client.dart';
import '../models/subscription_model.dart';
import '../models/topic_model.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<TopicModel> fetchByToken(String topicToken) async {
    final json = await _apiClient.get('/api/v1/topics/$topicToken');
    return TopicModel.fromJson(json);
  }

  Future<void> subscribe(String topicToken) async {
    await _apiClient.post('/api/v1/topics/$topicToken/follow', {});
  }

  Future<List<SubscriptionModel>> fetchAll() async {
    final json = await _apiClient.get('/api/v1/my/topics/subscribed');
    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> unsubscribe(int topicId) async {
    await _apiClient.delete('/api/v1/my/topics/subscribed/$topicId');
  }

  Future<void> updateNotifications(int topicId, {required bool enabled}) async {
    await _apiClient.patch(
      '/api/v1/my/topics/subscribed/$topicId/notifications',
      {'notifications_enabled': enabled},
    );
  }
}
