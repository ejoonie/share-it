import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/bootstrap_response.dart';
import '../../storage/token_storage.dart';
import 'bootstrap_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum BootstrapStatus { initial, loading, success, failure }

class BootstrapState {
  final BootstrapStatus status;
  final BootstrapResponse? data;
  final String? error;

  const BootstrapState({
    this.status = BootstrapStatus.initial,
    this.data,
    this.error,
  });

  BootstrapState copyWith({
    BootstrapStatus? status,
    BootstrapResponse? data,
    String? Function()? error,
  }) {
    return BootstrapState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error != null ? error() : this.error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BootstrapNotifier extends StateNotifier<BootstrapState> {
  final BootstrapRepository _repository;
  final TokenStorage _tokenStorage;

  BootstrapNotifier({
    required BootstrapRepository repository,
    required TokenStorage tokenStorage,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        super(const BootstrapState());

  /// Runs the full bootstrap sequence:
  ///   1. If no auth token stored, perform guest_login to obtain one.
  ///   2. Call /my/bootstrap with the auth token.
  Future<void> init(String guestToken) async {
    state = state.copyWith(status: BootstrapStatus.loading, error: () => null);
    try {
      var authToken = _tokenStorage.getAuthToken();

      if (authToken == null) {
        try {
          final user = await _repository.guestLogin(guestToken);
          authToken = user.token;
        } on ApiException catch (e) {
          // 409 means this guest_token was already registered but the auth
          // token was lost. Generate a new guest_token and retry once.
          if (e.statusCode == 409) {
            final newGuestToken = await _repository.rotateGuestToken();
            final user = await _repository.guestLogin(newGuestToken);
            authToken = user.token;
          } else {
            rethrow;
          }
        }
      }

      final bootstrapData = await _repository.getBootstrap(authToken);
      state = state.copyWith(
        status: BootstrapStatus.success,
        data: bootstrapData,
      );
    } catch (e) {
      state = state.copyWith(
        status: BootstrapStatus.failure,
        error: () => e.toString(),
      );
    }
  }

  /// Retry bootstrap after a failure.
  Future<void> retry(String guestToken) => init(guestToken);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final bootstrapRepositoryProvider = Provider<BootstrapRepository>((ref) {
  throw UnimplementedError(
    'bootstrapRepositoryProvider must be overridden with a BootstrapRepository instance.',
  );
});

final bootstrapNotifierProvider =
    StateNotifierProvider<BootstrapNotifier, BootstrapState>((ref) {
  throw UnimplementedError(
    'bootstrapNotifierProvider must be overridden with a BootstrapRepository instance.',
  );
});
