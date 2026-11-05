class TopicModel {
  final String? ownerName;
  final DateTime? followedAt;
  final bool isOwner;
  final int id;
  final String token;
  final int userId;
  final String title;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  const TopicModel({
    this.ownerName,
    this.followedAt,
    this.isOwner = false,
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
      ownerName: ownerName,
      followedAt: followedAt,
      isOwner: isOwner,
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
      ownerName: json['owner_name'] as String?,
      followedAt: DateTime.tryParse(json['followed_at'] as String? ?? ''),
      isOwner: json['is_owner'] as bool? ?? false,
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
