import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/bootstrap_response.dart';
import '../repositories/session_repository.dart';
import '../storage/token_storage.dart';

enum SessionStatus { loading, ready, unauthorized }

class SessionState {
  final SessionStatus status;
  final BootstrapResponse? data;

  const SessionState({
    this.status = SessionStatus.loading,
    this.data,
  });

  SessionState copyWith({SessionStatus? status, BootstrapResponse? data, bool clearData = false}) {
    return SessionState(
      status: status ?? this.status,
      data: clearData ? null : (data ?? this.data),
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionRepository _repository;
  final TokenStorage _tokenStorage;

  SessionNotifier({
    required SessionRepository repository,
    required TokenStorage tokenStorage,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        super(const SessionState());

  /// 앱 시작 시 호출.
  /// - 한 번이라도 로그인한 적 있으면 토큰 없을 때 게스트 생성 없이 unauthorized로 전환.
  /// - 완전 신규 유저면 게스트 로그인 후 데이터 로드.
  Future<void> init() async {
    state = state.copyWith(status: SessionStatus.loading);
    try {
      if (_tokenStorage.getToken() == null) {
        if (_tokenStorage.hasLoggedInBefore) {
          state = state.copyWith(status: SessionStatus.unauthorized);
          return;
        }
        await _repository.guestLogin();
      }
      await _loadData();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        state = state.copyWith(status: SessionStatus.unauthorized);
      } else {
        rethrow;
      }
    }
  }

  /// 로그인 성공 후 호출 — 새 토큰은 이미 저장된 상태.
  Future<void> reload() async {
    state = state.copyWith(status: SessionStatus.loading);
    try {
      await _tokenStorage.markLoggedIn();
      await _loadData();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        state = state.copyWith(status: SessionStatus.unauthorized);
      } else {
        rethrow;
      }
    }
  }

  /// 로그아웃 — 토큰 삭제 후 unauthorized 상태로 전환.
  Future<void> signOut() async {
    await _tokenStorage.clearToken();
    state = state.copyWith(status: SessionStatus.unauthorized, clearData: true);
  }

  /// unauthorized 화면에서 게스트로 계속하기.
  Future<void> continueAsGuest() async {
    state = state.copyWith(status: SessionStatus.loading);
    await _repository.guestLogin();
    await _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repository.loadData();
    state = state.copyWith(status: SessionStatus.ready, data: data);
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  throw UnimplementedError('sessionRepositoryProvider must be overridden');
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  throw UnimplementedError('sessionNotifierProvider must be overridden');
});
