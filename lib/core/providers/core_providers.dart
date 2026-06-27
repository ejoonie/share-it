import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../bootstrap/providers/bootstrap_provider.dart';
import '../repositories/entry_repository.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden with a TokenStorage instance.',
  );
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final settingsRefreshProvider = StateProvider<int>((ref) => 0);

final entryRepositoryProvider = Provider<EntryRepository?>((ref) {
  final bootstrapState = ref.watch(bootstrapNotifierProvider);
  if (bootstrapState.status != BootstrapStatus.success) return null;
  final topicId = bootstrapState.data?.topic?.id;
  if (topicId == null) return null;
  final authToken = ref.watch(tokenStorageProvider).getAuthToken();
  if (authToken == null) return null;
  final apiClient = ref.watch(apiClientProvider);
  return EntryRepository(
    apiClient: apiClient,
    topicId: topicId,
    authToken: authToken,
  );
});
