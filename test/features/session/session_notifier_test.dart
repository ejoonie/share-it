import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/models/bootstrap_response.dart';
import 'package:share_it/models/topic_model.dart';
import 'package:share_it/providers/session_provider.dart';
import 'package:share_it/repositories/session_repository.dart';
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
  bool guestLoginCalled = false;
  int loadDataCallCount = 0;
  bool throwUnauthorizedOnLoad = false;

  _FakeSessionRepository(TokenStorage storage)
      : super(apiClient: ApiClient(), tokenStorage: storage);

  @override
  Future<void> guestLogin() async {
    guestLoginCalled = true;
    // 실제 토큰 저장은 SessionNotifier 가 아닌 이 stub 의 부모가 담당하지 않으므로 생략
  }

  @override
  Future<BootstrapResponse> loadData() async {
    loadDataCallCount++;
    if (throwUnauthorizedOnLoad) {
      throw ApiException(statusCode: 401, message: 'Unauthorized');
    }
    return _fakeBootstrap();
  }
}

BootstrapResponse _fakeBootstrap() {
  return BootstrapResponse(
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
({_FakeSessionRepository repo, _FakeTokenStorage storage, SessionNotifier notifier})
    _make({String? initialToken}) {
  final storage = _FakeTokenStorage(_prefs);
  if (initialToken != null) storage._token = initialToken;

  final repo = _FakeSessionRepository(storage);
  final notifier = SessionNotifier(repository: repo, tokenStorage: storage);
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
    test('토큰 없으면 게스트 로그인 후 데이터 로드 → ready', () async {
      final (:repo, :storage, :notifier) = _make(); // 토큰 없는 상태

      await notifier.init();

      expect(repo.guestLoginCalled, isTrue, reason: '토큰이 없으므로 게스트 로그인을 호출해야 한다');
      expect(repo.loadDataCallCount, 1);
      expect(notifier.state.status, SessionStatus.ready);
      expect(notifier.state.data, isNotNull);
    });

    test('토큰 있으면 게스트 로그인 건너뛰고 데이터 로드 → ready', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'existing-token');

      await notifier.init();

      expect(repo.guestLoginCalled, isFalse, reason: '이미 토큰이 있으면 게스트 로그인을 하면 안 된다');
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

    test('init() 호출 직후 status 가 loading 으로 전환된다', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'token');

      final states = <SessionStatus>[];
      notifier.addListener((s) => states.add(s.status));

      await notifier.init();

      expect(states.first, SessionStatus.loading, reason: 'init() 시작 시 loading 이어야 한다');
      expect(states.last, SessionStatus.ready);
    });
  });

  // ---------------------------------------------------------------------------
  // reload() — 로그인 성공 후 데이터 리프레시
  // ---------------------------------------------------------------------------
  group('SessionNotifier.reload()', () {
    test('새 토큰이 저장된 상태에서 reload() → ready, 데이터 갱신', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'new-auth-token');

      await notifier.reload();

      expect(notifier.state.status, SessionStatus.ready);
      expect(notifier.state.data, isNotNull);
      expect(repo.guestLoginCalled, isFalse, reason: 'reload() 는 게스트 로그인을 호출하면 안 된다');
    });

    test('reload() 중 401 → unauthorized 상태', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'token');
      repo.throwUnauthorizedOnLoad = true;

      await notifier.reload();

      expect(notifier.state.status, SessionStatus.unauthorized);
    });
  });

  // ---------------------------------------------------------------------------
  // continueAsGuest() — 게스트로 계속하기
  // ---------------------------------------------------------------------------
  group('SessionNotifier.continueAsGuest()', () {
    test('기존 토큰 삭제 후 새 게스트 로그인 → ready', () async {
      final (:repo, :storage, :notifier) = _make(initialToken: 'old-token');

      await notifier.continueAsGuest();

      expect(storage.getToken(), isNull, reason: 'continueAsGuest() 는 기존 토큰을 삭제해야 한다');
      expect(repo.guestLoginCalled, isTrue);
      expect(notifier.state.status, SessionStatus.ready);
    });

    test('continueAsGuest() 후 loadData 호출', () async {
      final (:repo, :storage, :notifier) = _make();

      await notifier.continueAsGuest();

      expect(repo.loadDataCallCount, 1);
    });
  });
}
