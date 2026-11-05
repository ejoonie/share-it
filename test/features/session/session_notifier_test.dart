import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/models/bootstrap_response.dart';
import 'package:share_it/models/topic_model.dart';
import 'package:share_it/models/user_model.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/device_token_repository.dart';
import 'package:share_it/repositories/session_repository.dart';
import 'package:share_it/services/device_token_service.dart';
import 'package:share_it/storage/token_storage.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

/// TokenStorage 를 SharedPreferences 없이 메모리에서 동작하도록 대체한다.
/// super 생성자에 실제 SharedPreferences 인스턴스를 전달해 UnimplementedError 를 피하고,
/// 저장소 역할은 직접 필드로 관리한다.
class _FakeTokenStorage extends TokenStorage {
  String? _token;

  _FakeTokenStorage(super.prefs);

  @override
  String? getToken() => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

/// SessionRepository 의 네트워크 호출을 제어 가능한 stub 으로 대체한다.
class _FakeSessionRepository extends SessionRepository {
  int loadDataCallCount = 0;
  bool throwUnauthorizedOnLoad = false;
  bool offline = false;
  bool legacyGuest = false;
  Completer<void>? pendingLoad;

  _FakeSessionRepository(TokenStorage storage)
      : super(apiClient: ApiClient(), tokenStorage: storage);

  @override
  Future<BootstrapResponse> loadData() async {
    loadDataCallCount++;
    if (pendingLoad != null) await pendingLoad!.future;
    if (throwUnauthorizedOnLoad) {
      throw const ApiException(statusCode: 401, message: 'Unauthorized');
    }
    if (offline) throw Exception('offline');
    return _fakeBootstrap().copyWith(
      user: legacyGuest
          ? const UserModel(
              id: 9,
              email: 'legacy@example.com',
              nickName: 'Legacy',
              isGuest: true,
              token: 'legacy-token',
              createdAt: '',
              updatedAt: '',
            )
          : null,
    );
  }
}

class _FakeDeviceTokenService extends DeviceTokenService {
  final TokenStorage storage;
  bool syncCalled = false;
  bool unregisterCalled = false;
  String? authTokenDuringUnregister;

  _FakeDeviceTokenService(this.storage)
      : super(DeviceTokenRepository(apiClient: ApiClient()));

  @override
  Future<void> syncCurrentToken() async {
    syncCalled = true;
  }

  @override
  Future<void> unregisterCurrentToken() async {
    unregisterCalled = true;
    authTokenDuringUnregister = storage.getToken();
  }
}

BootstrapResponse _fakeBootstrap() {
  return const BootstrapResponse(
    bootstrapCreated: false,
    topic: TopicModel(
      id: 1,
      token: 'abc123',
      userId: 1,
      title: 'My Space',
      isDefault: true,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    ),
    entries: [],
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late SharedPreferences _prefs;

/// 각 테스트마다 독립적인 storage 와 notifier 를 만든다.
({
  _FakeSessionRepository repo,
  _FakeTokenStorage storage,
  SessionNotifier notifier
}) _make({String? initialToken, DeviceTokenService? deviceTokenService}) {
  final storage = _FakeTokenStorage(_prefs);
  if (initialToken != null) storage._token = initialToken;

  final repo = _FakeSessionRepository(storage);
  final notifier = SessionNotifier(
    repository: repo,
    tokenStorage: storage,
    deviceTokenService: deviceTokenService,
  );
  return (repo: repo, storage: storage, notifier: notifier);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  // ---------------------------------------------------------------------------
  // init() — 앱 시작 플로우
  // ---------------------------------------------------------------------------
  group('SessionNotifier.init()', () {
    test('no token shows welcome without requesting private data', () async {
      final result = _make();
      await result.notifier.init();
      expect(result.repo.loadDataCallCount, 0);
      expect(result.notifier.state.status, SessionStatus.unauthorized);
      expect(result.notifier.state.data, isNull);
    });

    test('토큰 있으면 게스트 로그인 건너뛰고 데이터 로드 → ready', () async {
      final (:repo, :storage, :notifier) =
          _make(initialToken: 'existing-token');

      await notifier.init();

      expect(repo.loadDataCallCount, 1);
      expect(notifier.state.status, SessionStatus.ready);
    });

    test('데이터 로드 중 401 → unauthorized 상태', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'expired-token');
      repo.throwUnauthorizedOnLoad = true;

      await notifier.init();

      expect(notifier.state.status, SessionStatus.unauthorized);
      expect(notifier.state.data, isNull);
    });

    test('legacy guest token returns to welcome without loading the app',
        () async {
      final result = _make(initialToken: 'legacy-token');
      result.repo.legacyGuest = true;
      await result.notifier.init();
      expect(result.notifier.state.status, SessionStatus.unauthorized);
      expect(result.notifier.state.data, isNull);
      expect(result.storage.getToken(), isNull);
    });

    test('network failure preserves token and supports retry', () async {
      final result = _make(initialToken: 'valid-token');
      result.repo.offline = true;
      await result.notifier.init();
      expect(result.notifier.state.status, SessionStatus.failure);
      expect(result.storage.getToken(), 'valid-token');
      result.repo.offline = false;
      await result.notifier.init();
      expect(result.notifier.state.status, SessionStatus.ready);
    });

    test('init() 호출 직후 status 가 loading 으로 전환된다', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'token');

      final states = <SessionStatus>[];
      notifier.addListener((s) => states.add(s.status));

      await notifier.init();

      expect(
        states.first,
        SessionStatus.loading,
        reason: 'init() 시작 시 loading 이어야 한다',
      );
      expect(states.last, SessionStatus.ready);
    });
  });

  // ---------------------------------------------------------------------------
  // reload() — 로그인 성공 후 데이터 리프레시
  // ---------------------------------------------------------------------------
  group('SessionNotifier.reload()', () {
    testWidgets('fast login keeps the splash for at least two seconds',
        (tester) async {
      final result = _make(initialToken: 'token');
      final reload = result.notifier.reload();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1999));
      expect(result.notifier.state.status, SessionStatus.loading);
      await tester.pump(const Duration(milliseconds: 1));
      await reload;
      expect(result.notifier.state.status, SessionStatus.ready);
      result.notifier.dispose();
    });

    testWidgets('slow login waits for data without adding another two seconds',
        (tester) async {
      final result = _make(initialToken: 'token');
      result.repo.pendingLoad = Completer<void>();
      final reload = result.notifier.reload();
      await tester.pump(const Duration(seconds: 3));
      expect(result.notifier.state.status, SessionStatus.loading);
      result.repo.pendingLoad!.complete();
      await tester.pump();
      await reload;
      expect(result.notifier.state.status, SessionStatus.ready);
      result.notifier.dispose();
    });

    test('새 토큰이 저장된 상태에서 reload() → ready, 데이터 갱신', () async {
      final (:repo, :storage, :notifier) =
          _make(initialToken: 'new-auth-token');

      await notifier.reload();

      expect(notifier.state.status, SessionStatus.ready);
      expect(notifier.state.data, isNotNull);
    });

    test('reload() 중 401 → unauthorized 상태', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'token');
      repo.throwUnauthorizedOnLoad = true;

      await notifier.reload();

      expect(notifier.state.status, SessionStatus.unauthorized);
    });

    test('로그인 성공 후 디바이스 토큰을 전송한다', () async {
      final storage = _FakeTokenStorage(_prefs).._token = 'new-auth-token';
      final deviceTokenService = _FakeDeviceTokenService(storage);
      final result = _make(
        initialToken: 'new-auth-token',
        deviceTokenService: deviceTokenService,
      );

      await result.notifier.reload();

      expect(deviceTokenService.syncCalled, isTrue);
    });
  });

  group('SessionNotifier.signOut()', () {
    test('인증 토큰을 지우기 전 디바이스 토큰을 서버에서 해제한다', () async {
      final storage = _FakeTokenStorage(_prefs).._token = 'auth-token';
      final deviceTokenService = _FakeDeviceTokenService(storage);
      final repository = _FakeSessionRepository(storage);
      final notifier = SessionNotifier(
        repository: repository,
        tokenStorage: storage,
        deviceTokenService: deviceTokenService,
      );

      await notifier.signOut();

      expect(deviceTokenService.unregisterCalled, isTrue);
      expect(deviceTokenService.authTokenDuringUnregister, 'auth-token');
      expect(storage.getToken(), isNull);
      expect(notifier.state.status, SessionStatus.unauthorized);
    });
  });
}
