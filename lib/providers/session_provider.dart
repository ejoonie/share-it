import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/bootstrap_response.dart';
import '../models/topic_model.dart';
import '../repositories/session_repository.dart';
import '../services/device_token_service.dart';
import '../storage/token_storage.dart';

enum SessionStatus { loading, ready, unauthorized, failure }

class SessionState {
  final SessionStatus status;
  final BootstrapResponse? data;

  const SessionState({
    this.status = SessionStatus.loading,
    this.data,
  });

  SessionState copyWith({
    SessionStatus? status,
    BootstrapResponse? data,
    bool clearData = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      data: clearData ? null : (data ?? this.data),
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionRepository _repository;
  final TokenStorage _tokenStorage;
  final DeviceTokenService? _deviceTokenService;

  SessionNotifier({
    required SessionRepository repository,
    required TokenStorage tokenStorage,
    DeviceTokenService? deviceTokenService,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        _deviceTokenService = deviceTokenService,
        super(const SessionState());

  /// No account or private data is created until the user signs in.
  Future<void> init() => _restoreSession();

  Future<void> reload() async {
    await _restoreSession(minimumDuration: const Duration(seconds: 2));
    if (state.status == SessionStatus.ready) {
      await _deviceTokenService?.syncCurrentToken();
    }
  }

  Future<void> _restoreSession({
    Duration minimumDuration = Duration.zero,
  }) async {
    state = const SessionState();
    if (_tokenStorage.getToken() == null) {
      state = const SessionState(status: SessionStatus.unauthorized);
      return;
    }
    final minimumDisplay = Future<void>.delayed(minimumDuration);
    late SessionState nextState;
    try {
      nextState = await _loadData();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _tokenStorage.clearToken();
        nextState = const SessionState(status: SessionStatus.unauthorized);
      } else {
        nextState = const SessionState(status: SessionStatus.failure);
      }
    } catch (_) {
      nextState = const SessionState(status: SessionStatus.failure);
    }
    await minimumDisplay;
    if (mounted) state = nextState;
  }

  /// 로그아웃 — 디바이스 토큰 해제 후 인증 토큰을 삭제한다.
  Future<void> signOut() async {
    await _deviceTokenService?.unregisterCurrentToken();
    await _tokenStorage.clearToken();
    state = state.copyWith(status: SessionStatus.unauthorized, clearData: true);
  }

  /// 회원탈퇴 — 서버 계정 삭제 후 로컬 상태 전체 초기화.
  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    await _tokenStorage.clearAll();
    state = state.copyWith(status: SessionStatus.unauthorized, clearData: true);
  }

  Future<SessionState> _loadData() async {
    final data = await _repository.loadData();
    // Reject legacy guest sessions even when talking to an older API.
    if (data.user?.isGuest == true) {
      await _tokenStorage.clearToken();
      return const SessionState(status: SessionStatus.unauthorized);
    }
    return SessionState(status: SessionStatus.ready, data: data);
  }

  void removeTopic(int topicId, {TopicModel? replacement}) {
    final data = state.data;
    if (data == null || data.topic?.id != topicId) return;
    state = state.copyWith(
      data: BootstrapResponse(
        bootstrapCreated: data.bootstrapCreated,
        user: data.user,
        topic: replacement,
        entries: const [],
      ),
    );
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final minimumDelay = Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    final data = state.data;
    final user = data?.user;

    if (user == null) return;

    final newData = data?.copyWith(
      user: user.copyWith(
        notificationsEnabled: enabled,
      ),
    );
    state = state.copyWith(data: newData);

    try {
      await Future.wait(
        [
          minimumDelay,
          _repository.updateNotificationsEnabled(enabled),
        ],
      );
    } catch (e) {
      state = state.copyWith(data: data); // rewind
    }
  }

  Future<void> refreshNotificationEnabled() async {
    final data = state.data;
    final user = data?.user;

    if (user == null) return;

    try {
      final enabled = await _repository.getNotificationsEnabled();
      state = state.copyWith(
        data: data?.copyWith(
          user: user.copyWith(
            notificationsEnabled: enabled,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to refresh notification enabled: $e');
    }
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  throw UnimplementedError('sessionRepositoryProvider must be overridden');
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  throw UnimplementedError('sessionNotifierProvider must be overridden');
});
