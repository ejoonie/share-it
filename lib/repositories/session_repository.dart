import '../api/api_client.dart';
import '../models/bootstrap_response.dart';
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
}
