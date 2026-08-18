import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/topic_model.dart';
import 'core_providers.dart';
import 'expense_provider.dart';

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
      // Filter/Add Expense 등에서 쓰는 토픽 목록 캐시를 무효화해
      // 재시작 없이도 방금 구독한 토픽이 바로 보이게 한다.
      _ref.invalidate(myViewableTopicsProvider);
      // 달력 Filter가 특정 토픽만 골라서 보는 중이었다면, 방금 구독한
      // 토픽도 자동으로 선택에 포함시킨다 (전체 선택 상태면 이미 보이므로 그대로 둔다).
      final topicId = state.topic.value?.id;
      if (topicId != null) {
        await _ref
            .read(expenseNotifierProvider.notifier)
            .includeTopicInSelection(topicId);
      }
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
