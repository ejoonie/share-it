import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'api/api_client.dart';
import 'providers/session_provider.dart';
import 'providers/core_providers.dart';
import 'repositories/session_repository.dart';
import 'storage/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request App Tracking Transparency permission on iOS 14+ before any
  // tracking-related SDK initialisation, as required by App Store Guideline
  // 5.1.2(i).
  if (Platform.isIOS) {
    await Permission.appTrackingTransparency.request();
  }

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
