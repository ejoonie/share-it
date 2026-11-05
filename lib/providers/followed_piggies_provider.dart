import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

final followedPiggiesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(subscriptionRepositoryProvider).fetchAll(),
);
