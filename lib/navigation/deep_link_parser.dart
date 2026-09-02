sealed class AppDestination {
  const AppDestination();
}

class TopicSubscriptionDestination extends AppDestination {
  final String topicToken;

  const TopicSubscriptionDestination(this.topicToken);
}

class EntryDestination extends AppDestination {
  final int topicId;
  final int entryId;

  const EntryDestination({required this.topicId, required this.entryId});
}

class DeepLinkParser {
  static const _host = 'sharablepiggy.com';

  const DeepLinkParser();

  AppDestination? parse(Uri uri) {
    if (uri.scheme != 'https' || uri.host != _host) return null;

    final segments = uri.pathSegments;
    if (segments.length == 4 &&
        segments[0] == 'topics' &&
        segments[2] == 'entries') {
      final topicId = int.tryParse(segments[1]);
      final entryId = int.tryParse(segments[3]);
      if (topicId == null || entryId == null) return null;
      return EntryDestination(topicId: topicId, entryId: entryId);
    }

    if (segments.length == 2 && segments[0] == 'topics') {
      return TopicSubscriptionDestination(segments[1]);
    }

    return null;
  }
}
