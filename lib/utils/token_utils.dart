import 'dart:math';

/// Generates a cryptographically secure random hex string of [length] chars.
String generateRandomHexToken(int length) {
  const chars = '0123456789abcdef';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}
