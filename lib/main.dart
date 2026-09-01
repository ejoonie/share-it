import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'api/api_client.dart';
import 'firebase_options.dart';
import 'providers/session_provider.dart';
import 'providers/core_providers.dart';
import 'repositories/session_repository.dart';
import 'storage/last_used_topic_storage.dart';
import 'storage/notification_opt_in_storage.dart';
import 'storage/token_storage.dart';
import 'storage/topic_filter_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // iOS ATT 권한 요청은 UIWindow가 준비된 후 첫 프레임에서 한다.
  // runApp() 전에 호출하면 window가 없어서 다이얼로그가 표시되지 않는다.
  // → app.dart _SessionGate.initState의 addPostFrameCallback에서 요청한다.

  final tokenStorage = await TokenStorage.create();
  final topicFilterStorage = await TopicFilterStorage.create();
  final lastUsedTopicStorage = await LastUsedTopicStorage.create();
  final notificationOptInStorage = await NotificationOptInStorage.create();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final sessionRepository = SessionRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        topicFilterStorageProvider.overrideWithValue(topicFilterStorage),
        lastUsedTopicStorageProvider.overrideWithValue(lastUsedTopicStorage),
        notificationOptInStorageProvider
            .overrideWithValue(notificationOptInStorage),
        apiClientProvider.overrideWithValue(apiClient),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        sessionNotifierProvider.overrideWith(
          (ref) => SessionNotifier(
            repository: ref.watch(sessionRepositoryProvider),
            tokenStorage: tokenStorage,
            deviceTokenService: ref.watch(deviceTokenServiceProvider),
          ),
        ),
      ],
      child: const ShareItApp(),
    ),
  );
}
