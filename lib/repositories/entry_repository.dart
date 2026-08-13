import '../api/api_client.dart';
import '../models/entry_model.dart';

/// Repository for managing entries.
/// Used in expenses and shopping list
class EntryRepository {
  final ApiClient _apiClient;
  final int topicId;

  EntryRepository({
    required ApiClient apiClient,
    required this.topicId,
  }) : _apiClient = apiClient;

  String get _basePath => '/api/v1/my/topics/$topicId/entries';
  String _basePathFor(int? overrideTopicId) =>
      '/api/v1/my/topics/${overrideTopicId ?? topicId}/entries';

  Future<List<EntryModel>> listEntries({
    Map<String, dynamic>? q,
    int page = 1,
    int limit = 100,
  }) async {
    final json = await _apiClient.get(
      _basePath,
      queryParams: {'page': page, 'limit': limit, ...?q},
    );
    final records = json['records'] as List<dynamic>;
    return records
        .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 내가 구독하는 모든 토픽의 엔트리를 조회한다 (GET /api/v1/entries).
  /// [topicIds]가 null이거나 비어 있으면 구독 중인 모든 토픽을 대상으로 한다.
  Future<List<EntryModel>> listAllEntries({
    List<int>? topicIds,
    Map<String, dynamic>? q,
    int page = 1,
    int limit = 100,
  }) async {
    final json = await _apiClient.get(
      '/api/v1/entries',
      queryParams: {
        'page': page,
        'limit': limit,
        if (topicIds != null && topicIds.isNotEmpty) 'q[topic_id_in][]': topicIds,
        ...?q,
      },
    );
    final records = json['records'] as List<dynamic>;
    return records
        .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EntryModel> createEntry({
    DateTime? occurredAt,
    String? kind,
    String? currency,
    int? amount,
    String? category,
    String? title,
    String? content,
    bool? checked,
  }) async {
    final body = <String, dynamic>{
      if (occurredAt != null) 'occurred_at': occurredAt.toUtc().toIso8601String(),
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
    };
    final json = await _apiClient.post(_basePath, body);
    return EntryModel.fromJson(json);
  }

  Future<EntryModel> updateEntry(
    int id, {
    DateTime? occurredAt,
    String? kind,
    String? currency,
    int? amount,
    String? category,
    String? title,
    String? content,
    bool? checked,
    int? topicId,
  }) async {
    final body = <String, dynamic>{
      if (occurredAt != null) 'occurred_at': occurredAt.toUtc().toIso8601String(),
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
    };
    final json = await _apiClient.patch('${_basePathFor(topicId)}/$id', body);
    return EntryModel.fromJson(json);
  }

  Future<EntryModel> deleteEntry(int id, {int? topicId}) async {
    final json = await _apiClient.delete('${_basePathFor(topicId)}/$id');
    return EntryModel.fromJson(json);
  }
}
