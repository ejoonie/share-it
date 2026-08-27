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
  /// [topicIds]가 null이면 구독 중인 모든 토픽을 대상으로 한다.
  /// [topicIds]가 명시적으로 빈 목록이면(전체 선택 해제) 서버 호출 없이 빈 결과를 반환한다.
  Future<List<EntryModel>> listAllEntries({
    List<int>? topicIds,
    Map<String, dynamic>? q,
    int page = 1,
    int limit = 100,
  }) async {
    if (topicIds != null && topicIds.isEmpty) return const [];

    final json = await _apiClient.get(
      '/api/v1/entries',
      queryParams: {
        'page': page,
        'limit': limit,
        if (topicIds != null && topicIds.isNotEmpty)
          'q[topic_id_in][]': topicIds,
        ...?q,
      },
    );
    final records = json['records'] as List<dynamic>;
    return records
        .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 구독 중인 토픽에 엔트리를 생성한다 (POST /api/v1/entries).
  /// [topicId]를 생략하면 이 리포지토리가 바인딩된 토픽에 생성한다.
  /// 서버에서 해당 토픽 follow의 create 권한을 확인한다.
  Future<EntryModel> createEntry({
    int? topicId,
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
      'topic_id': topicId ?? this.topicId,
      if (occurredAt != null)
        'occurred_at': occurredAt.toUtc().toIso8601String(),
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
    };
    final json = await _apiClient.post('/api/v1/entries', body);
    return EntryModel.fromJson(json);
  }

  /// 엔트리를 수정한다 (PATCH /api/v1/entries/:id).
  /// 어느 토픽에 속하든 서버가 entry로부터 토픽을 찾아 follow의 edit 권한을 확인하므로,
  /// 호출하는 쪽에서 topicId를 알 필요가 없다.
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
  }) async {
    final body = <String, dynamic>{
      if (occurredAt != null)
        'occurred_at': occurredAt.toUtc().toIso8601String(),
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
    };
    final json = await _apiClient.patch('/api/v1/entries/$id', body);
    return EntryModel.fromJson(json);
  }

  /// 엔트리를 삭제한다 (DELETE /api/v1/entries/:id). 서버가 follow의 delete 권한을 확인한다.
  Future<EntryModel> deleteEntry(int id) async {
    final json = await _apiClient.delete('/api/v1/entries/$id');
    return EntryModel.fromJson(json);
  }

  /// 여러 엔트리를 한번에 읽음 처리한다 (POST /api/v1/entries/reads).
  /// 실제로 반영된(구독 중인 토픽에 속한) entry id 목록을 반환한다.
  Future<List<int>> markEntriesRead(List<int> entryIds) async {
    if (entryIds.isEmpty) return const [];
    final json = await _apiClient.post('/api/v1/entries/reads', {
      'entry_ids': entryIds,
    });
    final marked = json['marked'] as List<dynamic>? ?? [];
    return marked.map((e) => e as int).toList();
  }
}
