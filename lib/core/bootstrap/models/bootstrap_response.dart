class TopicModel {
  final int id;
  final String token;
  final int userId;
  final String title;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  const TopicModel({
    required this.id,
    required this.token,
    required this.userId,
    required this.title,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as int,
      token: json['token'] as String,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      isDefault: json['is_default'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class EntryModel {
  final int id;
  final int topicId;
  final String kind;
  final String? currency;
  final int? amount;
  final String? category;
  final String title;
  final String? content;
  final bool checked;
  final String createdAt;
  final String updatedAt;

  const EntryModel({
    required this.id,
    required this.topicId,
    required this.kind,
    this.currency,
    this.amount,
    this.category,
    required this.title,
    this.content,
    required this.checked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    return EntryModel(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      kind: json['kind'] as String,
      currency: json['currency'] as String?,
      amount: json['amount'] as int?,
      category: json['category'] as String?,
      title: json['title'] as String,
      content: json['content'] as String?,
      checked: json['checked'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class BootstrapResponse {
  final bool bootstrapCreated;
  final TopicModel? topic;
  final List<EntryModel> entries;

  const BootstrapResponse({
    required this.bootstrapCreated,
    this.topic,
    required this.entries,
  });

  factory BootstrapResponse.fromJson(Map<String, dynamic> json) {
    final topicJson = json['topic'] as Map<String, dynamic>?;
    final entriesJson = json['entries'] as List<dynamic>? ?? [];

    return BootstrapResponse(
      bootstrapCreated: json['bootstrap_created'] as bool,
      topic: topicJson != null ? TopicModel.fromJson(topicJson) : null,
      entries: entriesJson
          .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
