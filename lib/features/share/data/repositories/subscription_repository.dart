import '../../../../core/api/api_client.dart';
import '../../../../core/models/topic_model.dart';

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

  Future<List<TopicModel>> fetchAll() async {
    final json = await _apiClient.get('/api/v1/my/topics/subscribed');
    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> unsubscribe(int topicId) async {
    await _apiClient.delete('/api/v1/my/topics/subscribed/$topicId');
  }
}
