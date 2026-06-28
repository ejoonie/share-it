import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../bootstrap/providers/bootstrap_provider.dart';
import '../repositories/entry_repository.dart';
import '../repositories/topic_repository.dart';
import '../storage/token_storage.dart';
import '../../features/share/data/repositories/subscription_repository.dart';

// Provider → 값을 읽기만 할 때 (변경 없음)
// StateProvider → 단순한 값을 읽고 변경할 때 (notifier/state 통합 축약형)
// StateNotifierProvider → 복잡한 로직과 상태를 분리해서 관리할 때

// app 시작시 shared pref 가 없어서 에러가 발생하기 때문에
// bootstrap 시 강제 override 해야 하는 provider
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden with a TokenStorage instance.',
  );
});

// provider 의 watch 는 하위 provider 의 재생성의 의미
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
  final topicId = ref.watch(bootstrapNotifierProvider).data?.topic?.id;

  if (topicId == null) return null;

  return EntryRepository(
    apiClient: ref.watch(apiClientProvider),
    topicId: topicId,
  );
});
