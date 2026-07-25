import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'api/api_client.dart';
import 'providers/session_provider.dart';
import 'providers/core_providers.dart';
import 'repositories/session_repository.dart';
import 'storage/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS 14+: ATT 권한 요청 (GA 등 광고/분석 추적 전에 반드시 호출)
  await AppTrackingTransparency.requestTrackingAuthorization();

  final tokenStorage = await TokenStorage.create();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final sessionRepository = SessionRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        apiClientProvider.overrideWithValue(apiClient),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        sessionNotifierProvider.overrideWith(
          (ref) => SessionNotifier(
            repository: ref.watch(sessionRepositoryProvider),
            tokenStorage: tokenStorage,
          ),
        ),
      ],
      child: const ShareItApp(),
    ),
  );
}
