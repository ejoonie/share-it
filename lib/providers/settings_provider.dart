import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/topic_model.dart';
import 'core_providers.dart';

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

/// Manages data for the Settings screen.
///
/// This notifier is [autoDispose], so it is created when the Settings screen
/// mounts and destroyed when it leaves the widget tree. Because the Settings
/// screen is only reachable after bootstrap succeeds (see [_BootstrapGate] in
/// app.dart), auth token is guaranteed to be present at construction time.
/// Initial data load therefore happens in the constructor — no manual trigger
/// from the UI is needed.
///
/// For explicit refreshes (e.g. returning from TopicDetailScreen after an
/// edit), callers increment [settingsRefreshProvider], which the Settings
/// screen listens to and forwards here.
class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    loadMyPiggies();
    loadSubscriptions();
  }

  Future<void> loadMyPiggies() async {
    state = state.copyWith(myPiggies: const AsyncValue.loading());
    try {
      final list = await _ref.read(topicRepositoryProvider).fetchOwned();
      state = state.copyWith(myPiggies: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(myPiggies: AsyncValue.error(e, st));
    }
  }

  Future<void> loadSubscriptions() async {
    state = state.copyWith(subscriptions: const AsyncValue.loading());
    try {
      final list = await _ref.read(subscriptionRepositoryProvider).fetchAll();
      state = state.copyWith(subscriptions: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(subscriptions: AsyncValue.error(e, st));
    }
  }

  Future<bool> unsubscribe(int topicId) async {
    try {
      await _ref.read(subscriptionRepositoryProvider).unsubscribe(topicId);
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
