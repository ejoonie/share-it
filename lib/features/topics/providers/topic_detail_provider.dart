import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/topic_follow_model.dart';
import '../../../core/models/topic_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/repositories/topic_repository.dart';

class TopicDetailState {
  final AsyncValue<TopicModel> topic;
  final AsyncValue<List<TopicFollowModel>> subscribers;

  const TopicDetailState({
    this.topic = const AsyncValue.loading(),
    this.subscribers = const AsyncValue.loading(),
  });

  TopicDetailState copyWith({
    AsyncValue<TopicModel>? topic,
    AsyncValue<List<TopicFollowModel>>? subscribers,
  }) {
    return TopicDetailState(
      topic: topic ?? this.topic,
      subscribers: subscribers ?? this.subscribers,
    );
  }
}

class TopicDetailNotifier extends StateNotifier<TopicDetailState> {
  final Ref _ref;
  final int topicId;

  TopicDetailNotifier(this._ref, this.topicId)
      : super(const TopicDetailState()) {
    loadTopic();
    loadSubscribers();
  }

  TopicRepository? _repo() {
    final authToken = _ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return null;
    return TopicRepository(
      apiClient: _ref.read(apiClientProvider),
      authToken: authToken,
    );
  }

  Future<void> loadTopic() async {
    final repo = _repo();
    if (repo == null) return;

    state = state.copyWith(topic: const AsyncValue.loading());
    try {
      final t = await repo.fetchById(topicId);
      state = state.copyWith(topic: AsyncValue.data(t));
    } catch (e, st) {
      state = state.copyWith(topic: AsyncValue.error(e, st));
    }
  }

  Future<void> loadSubscribers() async {
    final repo = _repo();
    if (repo == null) return;

    state = state.copyWith(subscribers: const AsyncValue.loading());
    try {
      final list = await repo.fetchFollows(topicId: topicId);
      state = state.copyWith(subscribers: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(subscribers: AsyncValue.error(e, st));
    }
  }

  void updateTopic(TopicModel updated) {
    state = state.copyWith(topic: AsyncValue.data(updated));
  }
}

final topicDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<TopicDetailNotifier, TopicDetailState, int>(
  (ref, topicId) => TopicDetailNotifier(ref, topicId),
);
