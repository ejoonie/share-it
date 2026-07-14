import '../api/api_client.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

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
