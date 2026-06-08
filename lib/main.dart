import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/bootstrap/providers/bootstrap_provider.dart';
import 'core/bootstrap/repositories/bootstrap_repository.dart';
import 'core/storage/token_storage.dart';
import 'core/utils/token_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = await TokenStorage.create();

  // Retrieve or generate the guest token used to create the guest account.
  var guestToken = tokenStorage.getGuestToken();
  if (guestToken == null) {
    guestToken = generateRandomHexToken(32);
    await tokenStorage.saveGuestToken(guestToken);
  }

  final apiClient = ApiClient();
  final bootstrapRepository = BootstrapRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  runApp(
    ProviderScope(
      overrides: [
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
