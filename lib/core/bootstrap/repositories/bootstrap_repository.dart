import '../../api/api_client.dart';
import '../../models/bootstrap_response.dart';
import '../../models/user_model.dart';
import '../../storage/token_storage.dart';
import '../../utils/token_utils.dart';

class BootstrapRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  BootstrapRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  /// Generates a new random guest token, persists it, and returns it.
  /// Used when the previous guest token already has a registered account but
  /// the corresponding auth token was lost.
  Future<String> rotateGuestToken() async {
    final newToken = generateRandomHexToken(32);
    await _tokenStorage.saveGuestToken(newToken);
    return newToken;
  }

  /// Creates a guest user via POST /api/v1/guest_login and persists the
  /// returned auth token. Returns the created [UserModel].
  Future<UserModel> guestLogin(String guestToken) async {
    final json = await _apiClient.post(
      '/api/v1/guest_login',
      {'guest_token': guestToken},
    );
    final user = UserModel.fromJson(json);
    await _tokenStorage.saveAuthToken(user.token);
    return user;
  }

  /// Calls GET /api/v1/my/bootstrap with the stored auth token and returns
  /// the [BootstrapResponse].
  Future<BootstrapResponse> getBootstrap() async {
    final json = await _apiClient.get('/api/v1/my/bootstrap');
    return BootstrapResponse.fromJson(json);
  }
}
