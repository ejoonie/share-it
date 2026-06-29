import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'api/api_client.dart';
import 'providers/bootstrap_provider.dart';
import 'repositories/bootstrap_repository.dart';
import 'providers/core_providers.dart';
import 'storage/token_storage.dart';
import 'utils/token_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = await TokenStorage.create();

  // Retrieve or generate the guest token used to create the guest account.
  var guestToken = tokenStorage.getGuestToken();
  if (guestToken == null) {
    guestToken = generateRandomHexToken(32);
    await tokenStorage.saveGuestToken(guestToken);
  }

  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final bootstrapRepository = BootstrapRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        apiClientProvider.overrideWithValue(apiClient),
        bootstrapRepositoryProvider
            .overrideWithValue(bootstrapRepository),
        bootstrapNotifierProvider.overrideWith(
          (ref) => BootstrapNotifier(
            repository: ref.watch(bootstrapRepositoryProvider),
            tokenStorage: tokenStorage,
          ),
        ),
      ],
      child: ShareItApp(guestToken: guestToken),
    ),
  );
}
