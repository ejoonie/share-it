import '../api/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> sendCode(String email) async {
    await _apiClient.post('/api/v1/auth/send_code', {'email': email});
  }

  Future<UserModel> verifyCode(String email, String code) async {
    final json = await _apiClient.post('/api/v1/auth/verify_code', {
      'email': email,
      'code': code,
    });
    return UserModel.fromJson(json);
  }

  Future<UserModel> loginWithPassword(String email, String password) async {
    final json = await _apiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(json);
  }
}
