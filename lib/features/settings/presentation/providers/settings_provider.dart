import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/topic_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/repositories/topic_repository.dart';
import '../../../share/data/repositories/subscription_repository.dart';

class SettingsState {
  final AsyncValue<List<TopicModel>> myPiggies;
  final AsyncValue<List<TopicModel>> subscriptions;

  const SettingsState({
    this.myPiggies = const AsyncValue.loading(),
    this.subscriptions = const AsyncValue.loading(),
  });

  SettingsState copyWith({
    AsyncValue<List<TopicModel>>? myPiggies,
    AsyncValue<List<TopicModel>>? subscriptions,
  }) {
    return SettingsState(
      myPiggies: myPiggies ?? this.myPiggies,
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState());

  TopicRepository? _topicRepo() {
    final authToken = _ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return null;
    return TopicRepository(
      apiClient: _ref.read(apiClientProvider),
      authToken: authToken,
    );
  }

  SubscriptionRepository? _subscriptionRepo() {
    final authToken = _ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return null;
    return SubscriptionRepository(
      apiClient: _ref.read(apiClientProvider),
      authToken: authToken,
    );
  }

  Future<void> loadMyPiggies() async {
    final repo = _topicRepo();
    if (repo == null) return;

    state = state.copyWith(myPiggies: const AsyncValue.loading());
    try {
      final list = await repo.fetchOwned();
      state = state.copyWith(myPiggies: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(myPiggies: AsyncValue.error(e, st));
    }
  }

  Future<void> loadSubscriptions() async {
    final repo = _subscriptionRepo();
    if (repo == null) return;

    state = state.copyWith(subscriptions: const AsyncValue.loading());
    try {
      final list = await repo.fetchAll();
      state = state.copyWith(subscriptions: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(subscriptions: AsyncValue.error(e, st));
    }
  }

  Future<bool> unsubscribe(int topicId) async {
    final repo = _subscriptionRepo();
    if (repo == null) return false;

    try {
      await repo.unsubscribe(topicId);
      state = state.copyWith(
        subscriptions: state.subscriptions.whenData(
          (list) => list.where((s) => s.id != topicId).toList(),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final settingsNotifierProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref),
);
