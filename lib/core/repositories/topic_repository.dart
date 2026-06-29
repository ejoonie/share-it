import '../api/api_client.dart';
import '../models/topic_follow_model.dart';
import '../models/topic_model.dart';

class TopicRepository {
  final ApiClient _apiClient;

  TopicRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<TopicModel>> fetchOwned() async {
    final json = await _apiClient.get('/api/v1/my/topics/owned');
    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TopicModel> fetchById(int topicId) async {
    final json = await _apiClient.get('/api/v1/my/topics/$topicId');
    return TopicModel.fromJson(json);
  }

  Future<TopicModel> update(int topicId, {String? title, bool? isDefault}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (isDefault != null) body['is_default'] = isDefault;
    final json = await _apiClient.patch('/api/v1/my/topics/$topicId', body);
    return TopicModel.fromJson(json);
  }

  Future<List<TopicFollowModel>> fetchFollows({
    required int topicId,
    page = 1,
    int limit = 10,
  }) async {
    final json = await _apiClient.get('/api/v1/my/topics/$topicId/follows');
    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => TopicFollowModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
