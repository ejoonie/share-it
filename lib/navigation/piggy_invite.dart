import 'deep_link_parser.dart';

/// Codes are opaque: preserve case and hyphens when pasting an invite.
String? piggyInviteToken(String input) {
  final value = input.trim();
  final destination =
      const DeepLinkParser().parse(Uri.tryParse(value) ?? Uri());
  if (destination is TopicSubscriptionDestination) {
    return destination.topicToken;
  }
  return RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value) ? value : null;
}
