import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/topic_model.dart';
import '../../../../core/providers/core_providers.dart';

class SubscribeState {
  final AsyncValue<TopicModel> topic;
  final AsyncValue<void>? subscribeResult;

  const SubscribeState({
    this.topic = const AsyncValue.loading(),
    this.subscribeResult,
  });

  SubscribeState copyWith({
    AsyncValue<TopicModel>? topic,
    AsyncValue<void>? subscribeResult,
  }) {
    return SubscribeState(
      topic: topic ?? this.topic,
      subscribeResult: subscribeResult ?? this.subscribeResult,
    );
  }
}

class SubscribeNotifier extends StateNotifier<SubscribeState> {
  final Ref _ref;
  final String topicToken;

  SubscribeNotifier(this._ref, this.topicToken) : super(const SubscribeState()) {
    fetchTopic();
  }

  Future<void> fetchTopic() async {
    state = state.copyWith(topic: const AsyncValue.loading());
    try {
      final topic =
          await _ref.read(subscriptionRepositoryProvider).fetchByToken(topicToken);
      state = state.copyWith(topic: AsyncValue.data(topic));
    } catch (e, st) {
      state = state.copyWith(topic: AsyncValue.error(e, st));
    }
  }

  Future<void> subscribe() async {
    state = SubscribeState(
      topic: state.topic,
      subscribeResult: const AsyncValue.loading(),
    );
    try {
      await _ref.read(subscriptionRepositoryProvider).subscribe(topicToken);
      state = SubscribeState(
        topic: state.topic,
        subscribeResult: const AsyncValue.data(null),
      );
    } catch (e, st) {
      state = SubscribeState(
        topic: state.topic,
        subscribeResult: AsyncValue.error(e, st),
      );
    }
  }
}

final subscribeNotifierProvider = StateNotifierProvider.autoDispose
    .family<SubscribeNotifier, SubscribeState, String>(
  (ref, topicToken) => SubscribeNotifier(ref, topicToken),
);
