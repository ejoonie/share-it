import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../bootstrap/providers/bootstrap_provider.dart';
import '../repositories/entry_repository.dart';
import '../repositories/topic_repository.dart';
import '../storage/token_storage.dart';
import '../../features/share/data/repositories/subscription_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden with a TokenStorage instance.',
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

final settingsRefreshProvider = StateProvider<int>((ref) => 0);

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository(apiClient: ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(apiClient: ref.watch(apiClientProvider));
});

final entryRepositoryProvider = Provider<EntryRepository?>((ref) {
  final bootstrapState = ref.watch(bootstrapNotifierProvider);
  if (bootstrapState.status != BootstrapStatus.success) return null;
  final topicId = bootstrapState.data?.topic?.id;
  if (topicId == null) return null;
  return EntryRepository(
    apiClient: ref.watch(apiClientProvider),
    topicId: topicId,
  );
});
