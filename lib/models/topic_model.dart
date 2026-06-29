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

  TopicModel copyWith({String? title}) {
    return TopicModel(
      id: id,
      token: token,
      userId: userId,
      title: title ?? this.title,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

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
