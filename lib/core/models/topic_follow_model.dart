import 'user_model.dart';

class TopicFollowModel {
  final int id;
  final int userId;
  final int topicId;
  final List<String> permissions;
  final DateTime? followedAt;
  final DateTime? invitedAt;
  final UserModel user;

  const TopicFollowModel({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.permissions,
    required this.followedAt,
    required this.invitedAt,
    required this.user,
  });

  factory TopicFollowModel.fromJson(Map<String, dynamic> json) {
    return TopicFollowModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      topicId: json['topic_id'] as int,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      followedAt: json['followed_at'] != null ? DateTime.tryParse(json['followed_at'] as String) : null,
      invitedAt: json['invited_at'] != null ? DateTime.tryParse(json['invited_at'] as String) : null,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
