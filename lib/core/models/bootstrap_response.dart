import 'entry_model.dart';
import 'topic_model.dart';

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
