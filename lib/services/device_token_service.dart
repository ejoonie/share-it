import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

import '../repositories/device_token_repository.dart';

class DeviceTokenService {
  final DeviceTokenRepository repository;
  StreamSubscription<String>? _refreshSubscription;

  DeviceTokenService(this.repository);

  Future<void> initialize() async {
    // 먼저 구독해서 초기 발급/갱신 이벤트를 놓치지 않는다.
    _refreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerRefreshedToken,
      onError: (Object error) {
        debugPrint('[push] Token refresh failed: $error');
      },
    );

    // 이미 발급된 토큰이 있다면 서버와 동기화한다.
    await syncCurrentToken();
  }

  Future<void> requestPermissionAndSync() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await syncCurrentToken();
  }

  Future<void> syncCurrentToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

        // 아직 APNs 등록이 끝나지 않았으면 onTokenRefresh에 맡긴다.
        if (apnsToken == null) {
          debugPrint('[push] APNs token is not ready');
          return;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await repository.register(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      debugPrint('[push] Token registered');
    } catch (error) {
      debugPrint('[push] Token sync failed: $error');
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await repository.unregister(token);
      debugPrint('[push] Token unregistered');
    } catch (error) {
      debugPrint('[push] Token unregister failed: $error');
    }
  }

  Future<void> _registerRefreshedToken(String token) async {
    try {
      // FCM이 토큰을 직접 전달했으므로 APNs 토큰을 다시 확인할 필요가 없다.
      await repository.register(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      debugPrint('[push] Refreshed token registered');
    } catch (error) {
      debugPrint('[push] Refreshed token registration failed: $error');
    }
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
  }
}
