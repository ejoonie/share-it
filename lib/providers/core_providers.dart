import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../repositories/entry_repository.dart';
import '../repositories/topic_repository.dart';
import '../storage/token_storage.dart';
import '../repositories/subscription_repository.dart';
import 'session_provider.dart';

/// Must be overridden in main() with a real [TokenStorage] instance.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('tokenStorageProvider must be overridden');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

/// Incremented to signal the Settings screen to reload its data.
final settingsRefreshProvider = StateProvider<int>((ref) => 0);

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository(apiClient: ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(apiClient: ref.watch(apiClientProvider));
});

/// topicId는 session 데이터에서 가져온다. null이면 아직 준비 안 된 것.
final entryRepositoryProvider = Provider<EntryRepository?>((ref) {
  final topicId = ref.watch(sessionNotifierProvider).data?.topic?.id;
  if (topicId == null) return null;
  return EntryRepository(
    apiClient: ref.watch(apiClientProvider),
    topicId: topicId,
  );
});

