import '../api/api_client.dart';

class EntryMessage {
  final int id;
  final int authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  EntryMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        authorId = json['author']['id'] as int,
        authorName = json['author']['nick_name'] as String,
        body = json['body'] as String,
        createdAt = DateTime.parse(json['created_at'] as String),
        updatedAt = DateTime.parse(json['updated_at'] as String);
}

class MessagePage {
  final List<EntryMessage> messages;
  final int? nextBeforeId;
  MessagePage.fromJson(Map<String, dynamic> json)
      : messages = (json['records'] as List)
            .map((item) => EntryMessage.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextBeforeId = json['next_before_id'] as int?;
}

class BlockedChatUser {
  final int id;
  final String name;

  BlockedChatUser.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['nick_name'] as String;
}

class EntryMessageRepository {
  final ApiClient client;
  EntryMessageRepository(this.client);
  String _path(int entryId) => '/api/v1/entries/$entryId/messages';

  Future<MessagePage> list(int entryId, {int? beforeId}) async =>
      MessagePage.fromJson(
        await client.get(
          _path(entryId),
          queryParams: {
            'limit': 30,
            if (beforeId != null) 'before_id': beforeId,
          },
        ),
      );

  Future<EntryMessage> get(int entryId, int messageId) async =>
      EntryMessage.fromJson(await client.get('${_path(entryId)}/$messageId'));

  Future<EntryMessage> send(int entryId, String body) async =>
      EntryMessage.fromJson(await client.post(_path(entryId), {'body': body}));

  Future<EntryMessage> edit(int entryId, int messageId, String body) async =>
      EntryMessage.fromJson(
        await client.patch('${_path(entryId)}/$messageId', {'body': body}),
      );

  Future<void> delete(int entryId, int messageId) async {
    await client.delete('${_path(entryId)}/$messageId');
  }

  Future<void> report(int entryId, int messageId, String reason) async {
    await client.post(
      '${_path(entryId)}/$messageId/report',
      {'reason': reason},
    );
  }

  Future<BlockedChatUser> block(int entryId, int messageId) async {
    final json = await client.post(
      '${_path(entryId)}/$messageId/block',
      const {},
    );
    return BlockedChatUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<List<BlockedChatUser>> listBlockedUsers() async {
    final json = await client.get('/api/v1/chat_blocks');
    return (json['records'] as List)
        .map(
          (record) => BlockedChatUser.fromJson(
            (record as Map<String, dynamic>)['user'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> unblock(int userId) async {
    await client.delete('/api/v1/chat_blocks/$userId');
  }
}
