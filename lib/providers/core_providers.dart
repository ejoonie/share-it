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

/// 유저가 명시적으로 선택한 토픽 ID. null이면 세션 기본값을 사용한다.
final selectedTopicIdProvider = StateProvider<int?>((ref) => null);

/// 실제로 사용 중인 토픽 ID.
/// 선택값이 있으면 우선, 없으면 세션 로드 시 내려온 기본 토픽을 사용한다.
final currentTopicIdProvider = Provider<int?>((ref) {
  return ref.watch(selectedTopicIdProvider)
      ?? ref.watch(sessionNotifierProvider).data?.topic?.id;
});

final entryRepositoryProvider = Provider<EntryRepository?>((ref) {
  final topicId = ref.watch(currentTopicIdProvider);
  if (topicId == null) return null;
  return EntryRepository(
    apiClient: ref.watch(apiClientProvider),
    topicId: topicId,
  );
});

