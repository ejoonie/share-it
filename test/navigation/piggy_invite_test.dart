import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/navigation/piggy_invite.dart';
import 'package:share_it/navigation/deep_link_parser.dart';

void main() {
  test('web landing page custom scheme resolves to the same subscription', () {
    for (final input in [
      'https://sharablepiggy.com/topics/abc-123',
      'sharablepiggy://topics/abc-123'
    ]) {
      final result = const DeepLinkParser().parse(Uri.parse(input));
      expect(result, isA<TopicSubscriptionDestination>());
      expect((result as TopicSubscriptionDestination).topicToken, 'abc-123');
      expect(piggyInviteToken(input), 'abc-123');
    }
  });
  test('pasted codes preserve case and hyphens', () {
    expect(piggyInviteToken('  AbC-123_xyz\n'), 'AbC-123_xyz');
  });
  test('rejects unrelated QR links and unsafe path segments', () {
    for (final input in [
      '',
      'https://example.com/topics/abc',
      'sharablepiggy://other/abc',
      'https://sharablepiggy.com/topics/a%2Fb',
      'https://sharablepiggy.com/topics/a/extra',
      '../abc'
    ]) {
      expect(piggyInviteToken(input), isNull, reason: input);
    }
  });
}
