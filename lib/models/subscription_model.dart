import 'topic_model.dart';

class SubscriptionModel {
  final TopicModel topic;
  final bool notificationsEnabled;

  const SubscriptionModel({
    required this.topic,
    required this.notificationsEnabled,
  });

  SubscriptionModel copyWith({bool? notificationsEnabled}) {
    return SubscriptionModel(
      topic: topic,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      topic: TopicModel.fromJson(json['topic'] as Map<String, dynamic>),
      notificationsEnabled: json['notifications_enabled'] as bool,
    );
  }
}
