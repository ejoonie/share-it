import 'entry_model.dart';
import 'topic_model.dart';

/// Response from GET /api/v1/my/bootstrap
///
/// ```json
/// {
///   "bootstrap_created": true,
///   "topic": {
///     "id": 1,
///     "title": "✨ My First Space",
///     "is_default": true,
///     "created_at": "2024-01-01T00:00:00.000Z"
///   },
///   "entries": [
///     {
///       "id": 1,
///       "kind": "todo",
///       "title": "Welcome to Share-it",
///       "content": "Tap the checkbox to complete your first task.",
///       "checked": false
///     },
///     {
///       "id": 2,
///       "kind": "expense",
///       "currency": "usd",
///       "amount": 650,
///       "title": "Blue Bottle Coffee",
///       "content": "Your journey toward mindful tracking starts here.",
///       "checked": false
///     }
///   ]
/// }
/// ```
///
/// [bootstrapCreated] is true only on the very first call (new user).
/// [topic] is the user's default topic — used by [entryRepositoryProvider]
/// to scope all entry API calls.
class BootstrapResponse {
  final bool bootstrapCreated;
  final TopicModel? topic;
  final List<EntryModel> entries;

  const BootstrapResponse({
    required this.bootstrapCreated,
    this.topic,
    required this.entries,
  });

  BootstrapResponse copyWith({TopicModel? topic}) {
    return BootstrapResponse(
      bootstrapCreated: bootstrapCreated,
      topic: topic ?? this.topic,
      entries: entries,
    );
  }

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
