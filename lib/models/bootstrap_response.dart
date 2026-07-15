import 'entry_model.dart';
import 'topic_model.dart';
import 'user_model.dart';

/// Response from GET /api/v1/my/bootstrap
///
/// [bootstrapCreated] is true only on the very first call (new user).
/// [user] is the currently authenticated user.
/// [topic] is the user's default topic — used by [entryRepositoryProvider]
/// to scope all entry API calls.
class BootstrapResponse {
  final bool bootstrapCreated;
  final UserModel? user;
  final TopicModel? topic;
  final List<EntryModel> entries;

  const BootstrapResponse({
    required this.bootstrapCreated,
    this.user,
    this.topic,
    required this.entries,
  });

  BootstrapResponse copyWith({UserModel? user, TopicModel? topic}) {
    return BootstrapResponse(
      bootstrapCreated: bootstrapCreated,
      user: user ?? this.user,
      topic: topic ?? this.topic,
      entries: entries,
    );
  }

  factory BootstrapResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final topicJson = json['topic'] as Map<String, dynamic>?;
    final entriesJson = json['entries'] as List<dynamic>? ?? [];

    return BootstrapResponse(
      bootstrapCreated: json['bootstrap_created'] as bool,
      user: userJson != null ? UserModel.fromJson(userJson) : null,
      topic: topicJson != null ? TopicModel.fromJson(topicJson) : null,
      entries: entriesJson
          .map((e) => EntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
