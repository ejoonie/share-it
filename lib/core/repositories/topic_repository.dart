import 'package:share_it/core/models/user_model.dart';

import '../api/api_client.dart';
import '../models/topic_model.dart';

class TopicRepository {
  final ApiClient _apiClient;
  final String _authToken;

  TopicRepository({
    required ApiClient apiClient,
    required String authToken,
  })  : _apiClient = apiClient,
        _authToken = authToken;

  Future<List<TopicModel>> fetchOwned() async {
    final json = await _apiClient.get(
      '/api/v1/my/topics/owned',
      authToken: _authToken,
    );
    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TopicModel> fetchById(int topicId) async {
    final json = await _apiClient.get(
      '/api/v1/my/topics/$topicId',
      authToken: _authToken,
    );
    return TopicModel.fromJson(json);
  }

  Future<TopicModel> updateTitle(int topicId, String title) async {
    final json = await _apiClient.patch(
      '/api/v1/my/topics/$topicId',
      {'title': title},
      authToken: _authToken,
    );
    return TopicModel.fromJson(json);
  }

  Future<List<UserModel>> fetchSubscribers({
    required int topicId,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _apiClient.get(
      '/api/v1/my/topics/$topicId/subscribers?page=$page&limit=$limit',
      authToken: _authToken,
    );

    final list = json['records'] as List<dynamic>? ?? [];
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
