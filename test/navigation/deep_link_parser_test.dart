import 'package:flutter_test/flutter_test.dart';
import 'package:share_it/navigation/deep_link_parser.dart';

void main() {
  const parser = DeepLinkParser();

  test('parses a topic subscription link', () {
    final destination = parser.parse(
      Uri.parse('https://sharablepiggy.com/topics/invite-token'),
    );

    expect(destination, isA<TopicSubscriptionDestination>());
    expect(
      (destination as TopicSubscriptionDestination).topicToken,
      'invite-token',
    );
  });

  test('parses an entry link before the topic subscription route', () {
    final destination = parser.parse(
      Uri.parse('https://sharablepiggy.com/topics/42/entries/918'),
    );

    expect(destination, isA<EntryDestination>());
    expect((destination as EntryDestination).topicId, 42);
    expect(destination.entryId, 918);
  });

  test('rejects malformed and external links', () {
    expect(parser.parse(Uri.parse('https://example.com/topics/token')), isNull);
    expect(
      parser.parse(Uri.parse('https://sharablepiggy.com/topics/x/entries/y')),
      isNull,
    );
    expect(
      parser.parse(Uri.parse('https://sharablepiggy.com/topics/42/extra')),
      isNull,
    );
  });
}
