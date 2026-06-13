class EntryModel {
  final int id;
  final int topicId;
  final int createdById;
  final int? updatedById;
  final DateTime? occurredAt;
  final String? kind;
  final String currency;
  final int amount;
  final String? category;
  final String? title;
  final String? content;
  final bool checked;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EntryModel({
    required this.id,
    required this.topicId,
    required this.createdById,
    this.updatedById,
    this.occurredAt,
    this.kind,
    this.currency = 'usd',
    this.amount = 0,
    this.category,
    this.title,
    this.content,
    this.checked = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    return EntryModel(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      createdById: json['created_by_id'] as int,
      updatedById: json['updated_by_id'] as int?,
      occurredAt: json['occurred_at'] != null
          ? DateTime.parse(json['occurred_at'] as String).toLocal()
          : null,
      kind: json['kind'] as String?,
      currency: (json['currency'] as String?) ?? 'usd',
      amount: (json['amount'] as int?) ?? 0,
      category: json['category'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      checked: (json['checked'] as bool?) ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  EntryModel copyWith({
    int? id,
    int? topicId,
    int? createdById,
    int? Function()? updatedById,
    DateTime? Function()? occurredAt,
    String? Function()? kind,
    String? currency,
    int? amount,
    String? Function()? category,
    String? Function()? title,
    String? Function()? content,
    bool? checked,
    DateTime? Function()? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EntryModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      createdById: createdById ?? this.createdById,
      updatedById: updatedById != null ? updatedById() : this.updatedById,
      occurredAt: occurredAt != null ? occurredAt() : this.occurredAt,
      kind: kind != null ? kind() : this.kind,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      category: category != null ? category() : this.category,
      title: title != null ? title() : this.title,
      content: content != null ? content() : this.content,
      checked: checked ?? this.checked,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
