import '../api/api_client.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';

class AuthLoginResult {
  final UserModel user;
  final bool isNewUser;

  const AuthLoginResult({required this.user, required this.isNewUser});
}

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  /// Requests a 6-digit OTP to be sent to [email] via SES.
  Future<void> requestLoginCode(String email) async {
    await _apiClient.post(
      '/api/v1/auth/request_login_code',
      {'email': email},
    );
  }

  /// Verifies the OTP [code] for [email] and returns the authenticated user.
  /// Persists the auth token on success.
  Future<AuthLoginResult> verifyLoginCode(String email, String code) async {
    final json = await _apiClient.post(
      '/api/v1/auth/verify_login_code',
      {'email': email, 'code': code},
    );
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await _tokenStorage.saveAuthToken(user.token);
    return AuthLoginResult(
      user: user,
      isNewUser: json['is_new_user'] as bool,
    );
  }

  /// Logs in with [email] and [password] and returns the authenticated user.
  /// Persists the auth token on success.
  Future<AuthLoginResult> loginWithPassword(String email, String password) async {
    final json = await _apiClient.post(
      '/api/v1/auth/login',
      {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    await _tokenStorage.saveAuthToken(user.token);
    return AuthLoginResult(
      user: user,
      isNewUser: json['is_new_user'] as bool,
    );
  }

  /// Accepts the terms of service for the currently authenticated user.
  Future<UserModel> acceptTerms() async {
    final json = await _apiClient.post(
      '/api/v1/my/account/accept_terms',
      {},
    );
    return UserModel.fromJson(json);
  }

  /// Requests a verification code for changing the password of the current user.
  Future<void> requestPasswordChange() async {
    await _apiClient.post(
      '/api/v1/my/account/request_password_change',
      {},
    );
  }

  /// Changes the password after verifying [code].
  Future<void> changePassword({
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiClient.post(
      '/api/v1/my/account/change_password',
      {
        'code': code,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
