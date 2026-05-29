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
