import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../bootstrap/providers/bootstrap_provider.dart';
import '../repositories/entry_repository.dart';
import '../repositories/topic_repository.dart';
import '../storage/token_storage.dart';
import '../../features/share/data/repositories/subscription_repository.dart';

// ---------------------------------------------------------------------------
// Provider types
//   Provider              — read-only dependency, no state changes
//   StateProvider         — simple value that can be changed externally
//   StateNotifierProvider — complex state + logic separated into a Notifier
//
// Watching inside a Provider means "recreate me when the dependency changes",
// not "rebuild the UI". UI rebuilds only happen when a widget calls ref.watch.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Bootstrap → provider chain
//
// This app creates a guest account on first launch, so an auth token is not
// available until the bootstrap sequence completes. The provider chain below
// propagates that readiness signal automatically:
//
//   bootstrapNotifierProvider (success)
//       └─ entryRepositoryProvider   (null until topicId is known)
//               └─ expenseRepositoryProvider
//                       └─ ExpenseNotifier (auto-loads in constructor)
//
// Providers that do not depend on a specific topic (topics, subscriptions)
// are always available once ApiClient has a TokenStorage, but are only
// accessed from screens that are gated behind bootstrap (see _BootstrapGate
// in app.dart), so the token is guaranteed to exist at call time.
// ---------------------------------------------------------------------------

/// Must be overridden in main() with a real [TokenStorage] instance.
/// TokenStorage requires async initialisation (SharedPreferences), so it
/// cannot be created inside a synchronous Provider body.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError(
    'tokenStorageProvider must be overridden with a TokenStorage instance.',
  );
});

/// Depends on [tokenStorageProvider] so that ApiClient always reads the
/// current auth token from storage on every request.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

/// Incremented to signal the Settings screen to reload its data.
/// Used when returning from TopicDetailScreen after an edit, or when the
/// Settings tab is tapped.
final settingsRefreshProvider = StateProvider<int>((ref) => 0);

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository(apiClient: ref.watch(apiClientProvider));
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(apiClient: ref.watch(apiClientProvider));
});

/// Returns null until bootstrap succeeds and a default topic is available.
/// Downstream providers (expenseRepositoryProvider) treat null as "not ready"
/// and skip loading until this resolves.
final entryRepositoryProvider = Provider<EntryRepository?>((ref) {
  final topicId = ref.watch(bootstrapNotifierProvider).data?.topic?.id;
  if (topicId == null) return null;
  return EntryRepository(
    apiClient: ref.watch(apiClientProvider),
    topicId: topicId,
  );
});
