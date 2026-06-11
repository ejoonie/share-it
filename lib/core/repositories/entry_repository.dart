import '../api/api_client.dart';
import '../models/entry_model.dart';

class EntryRepository {
  final ApiClient _apiClient;
  final int topicId;
  final String authToken;

  EntryRepository({
    required ApiClient apiClient,
    required this.topicId,
    required this.authToken,
  }) : _apiClient = apiClient;

  String get _basePath => '/api/v1/my/topics/$topicId/entries';

  Future<List<EntryModel>> listEntries() async {
    final json = await _apiClient.get(_basePath, authToken: authToken);
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
      if (occurredAt != null) 'occurred_at': occurredAt.toIso8601String(),
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
    };
    final json = await _apiClient.post(_basePath, body, authToken: authToken);
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
  }) async {
    final body = <String, dynamic>{
      if (occurredAt != null) 'occurred_at': occurredAt.toIso8601String(),
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (checked != null) 'checked': checked,
    };
    final json = await _apiClient.patch(
      '$_basePath/$id',
      body,
      authToken: authToken,
    );
    return EntryModel.fromJson(json);
  }

  Future<EntryModel> deleteEntry(int id) async {
    final json = await _apiClient.delete(
      '$_basePath/$id',
      authToken: authToken,
    );
    return EntryModel.fromJson(json);
  }
}
