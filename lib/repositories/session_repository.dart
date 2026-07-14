import '../api/api_client.dart';
import '../models/bootstrap_response.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';
import '../utils/token_utils.dart';

class SessionRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  SessionRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  // ---------------------------------------------------------------------------
  // 앱 시작 플로우
  // ---------------------------------------------------------------------------

  /// 랜덤 ID로 게스트 계정을 생성하고 토큰을 저장한다.
  Future<void> guestLogin() async {
    final guestToken = generateRandomHexToken(32);
    final json = await _apiClient.post(
      '/api/v1/guest_login',
      {'guest_token': guestToken},
    );
    await _tokenStorage.saveToken(json['token'] as String);
  }

  /// 유저 데이터를 로드한다 (bootstrap API = 신규 유저면 샘플 데이터 생성 + 반환).
  Future<BootstrapResponse> loadData() async {
    final json = await _apiClient.get('/api/v1/my/bootstrap');
    return BootstrapResponse.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // 로그인
  // ---------------------------------------------------------------------------

  /// 이메일로 신규 여부 및 패스워드 설정 여부를 확인한다.
  Future<({bool isNewUser, bool hasPassword})> checkEmail(String email) async {
    final json = await _apiClient.post('/api/v1/auth/check_email', {'email': email});
    return (
      isNewUser: json['is_new_user'] as bool,
      hasPassword: json['has_password'] as bool,
    );
  }

  /// 이메일로 OTP 전송.
  Future<void> requestLoginCode(String email) async {
    await _apiClient.post('/api/v1/auth/request_login_code', {'email': email});
  }

  /// OTP 검증 후 토큰 저장.
  Future<UserModel> verifyLoginCode(String email, String code) async {
    final json = await _apiClient.post('/api/v1/auth/verify_login_code', {
      'email': email,
      'code': code,
    });
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await _tokenStorage.saveToken(user.token);
    return user;
  }

  /// 이메일 + 비밀번호 로그인 후 토큰 저장.
  Future<UserModel> loginWithPassword(String email, String password) async {
    final json = await _apiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await _tokenStorage.saveToken(user.token);
    return user;
  }
}
