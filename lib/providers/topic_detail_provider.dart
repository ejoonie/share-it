import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/topic_follow_model.dart';
import '../models/topic_model.dart';
import 'core_providers.dart';
import 'session_provider.dart';
import 'expense_provider.dart';
import 'topic_list_events.dart';

class TopicDetailState {
  final bool isFollowing;
  final AsyncValue<TopicModel> topic;
  final AsyncValue<List<TopicFollowModel>> subscribers;

  const TopicDetailState({
    this.isFollowing = true,
    this.topic = const AsyncValue.loading(),
    this.subscribers = const AsyncValue.loading(),
  });

  TopicDetailState copyWith({
    bool? isFollowing,
    AsyncValue<TopicModel>? topic,
    AsyncValue<List<TopicFollowModel>>? subscribers,
  }) {
    return TopicDetailState(
      isFollowing: isFollowing ?? this.isFollowing,
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
  }

  Future<void> loadTopic() async {
    if (!state.isFollowing) return;
    state = state.copyWith(topic: const AsyncValue.loading());
    try {
      final t = await _ref.read(topicRepositoryProvider).fetchById(topicId);
      if (!mounted) return;
      state = state.copyWith(topic: AsyncValue.data(t));
      if (t.isOwner) {
        await loadSubscribers();
      } else {
        state = state.copyWith(subscribers: const AsyncValue.data([]));
      }
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(topic: AsyncValue.error(e, st));
    }
  }

  Future<void> loadSubscribers() async {
    state = state.copyWith(subscribers: const AsyncValue.loading());
    try {
      final list = await _ref
          .read(topicRepositoryProvider)
          .fetchFollows(topicId: topicId);
      if (!mounted) return;
      state = state.copyWith(subscribers: AsyncValue.data(list));
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(subscribers: AsyncValue.error(e, st));
    }
  }

  Future<bool> deleteTopic() async {
    if (state.topic.value?.isOwner != true) return false;
    final repository = _ref.read(topicRepositoryProvider);
    try {
      await repository.delete(topicId);
    } catch (_) {
      return false;
    }
    // Deletion succeeded even if refreshing the remaining topics is offline.
    TopicModel? replacement;
    try {
      final remaining = await repository.fetchOwned();
      replacement = remaining.where((topic) => topic.isDefault).firstOrNull ??
          remaining.firstOrNull;
    } catch (_) {}
    if (_ref.exists(sessionNotifierProvider)) {
      _ref
          .read(sessionNotifierProvider.notifier)
          .removeTopic(topicId, replacement: replacement);
    }
    if (_ref.read(selectedTopicIdProvider) == topicId) {
      _ref.read(selectedTopicIdProvider.notifier).state = replacement?.id;
    }
    await notifyTopicListChanged(_ref);
    if (_ref.exists(expenseNotifierProvider)) {
      _ref.invalidate(expenseNotifierProvider);
    }
    _ref.read(settingsRefreshProvider.notifier).update((value) => value + 1);
    return true;
  }

  Future<bool> unfollow() async {
    if (state.topic.value?.isOwner != false) return false;
    try {
      await _ref.read(subscriptionRepositoryProvider).unsubscribe(topicId);
      if (mounted) state = state.copyWith(isFollowing: false);
      await notifyTopicListChanged(_ref);
      _ref.read(settingsRefreshProvider.notifier).update((value) => value + 1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> follow() async {
    final topic = state.topic.valueOrNull;
    if (topic == null || topic.isOwner || state.isFollowing) return false;
    try {
      await _ref.read(subscriptionRepositoryProvider).subscribe(topic.token);
    } catch (_) {
      return false;
    }
    if (!mounted) return true;
    state = state.copyWith(isFollowing: true);
    await notifyTopicListChanged(_ref);
    _ref.read(settingsRefreshProvider.notifier).update((value) => value + 1);
    // Refresh the follow timestamp without discarding the visible detail on failure.
    try {
      final updated =
          await _ref.read(topicRepositoryProvider).fetchById(topicId);
      if (mounted) state = state.copyWith(topic: AsyncValue.data(updated));
    } catch (_) {}
    return true;
  }

  void updateTopic(TopicModel updated) {
    loadTopic();
  }
}

final topicDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<TopicDetailNotifier, TopicDetailState, int>(
  (ref, topicId) => TopicDetailNotifier(ref, topicId),
);
