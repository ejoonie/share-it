import 'package:flutter/cupertino.dart';

import '../api/api_client.dart';

/// FCM 디바이스 토큰을 서버에 등록/해제한다.
/// (POST /api/v1/my/device_tokens, DELETE /api/v1/my/device_tokens/:token)
class DeviceTokenRepository {
  final ApiClient _apiClient;

  DeviceTokenRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> register({
    required String token,
    required String platform,
  }) async {
    debugPrint('[push] register()');

    await _apiClient.post('/api/v1/my/device_tokens', {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregister(String token) async {
    await _apiClient.delete('/api/v1/my/device_tokens/$token');
  }
}
