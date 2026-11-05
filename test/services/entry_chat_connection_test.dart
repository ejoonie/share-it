import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:share_it/api/api_client.dart';
import 'package:share_it/services/entry_chat_connection.dart';

class FakeSink implements WebSocketSink {
  final sent = <String>[];
  bool closed = false;
  @override
  void add(dynamic data) => sent.add(data as String);
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSocket implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  @override
  final FakeSink sink = FakeSink();
  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  Future<void> get ready async {}
  void frame(Map<String, dynamic> value) => incoming.add(jsonEncode(value));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('subscribes after welcome and delivers changes and revocation',
      () async {
    final socket = FakeSocket();
    final connected = Completer<void>();
    final api = ApiClient(
      client: MockClient((request) async {
        expect(
          request.url.path,
          '/api/v1/entries/42/messages/connection_ticket',
        );
        return http.Response('{"ticket":"short-lived"}', 201);
      }),
    );
    final connection = EntryChatConnection(
      api,
      42,
      connect: (uri) {
        expect(uri.path, '/cable');
        expect(uri.queryParameters['ticket'], 'short-lived');
        connected.complete();
        return socket;
      },
    );
    final events = <ChatEvent>[];
    final denied = Completer<void>();
    final subscription = connection.events.listen((event) {
      events.add(event);
      if (event == ChatEvent.denied) denied.complete();
    });
    await connected.future;
    socket.frame({'type': 'welcome'});
    socket.frame({'type': 'confirm_subscription'});
    socket.frame({
      'message': {'type': 'changed'},
    });
    socket.frame({
      'message': {'type': 'changed'},
    });
    socket.frame({
      'message': {'type': 'access_revoked'},
    });
    await denied.future;
    expect(jsonDecode(socket.sink.sent.single)['command'], 'subscribe');
    expect(events, [
      ChatEvent.connected,
      ChatEvent.changed,
      ChatEvent.changed,
      ChatEvent.denied,
    ]);
    expect(socket.sink.closed, true);
    connection.dispose();
    await subscription.cancel();
    await socket.incoming.close();
  });

  test('reconnects with a fresh ticket after socket loss', () async {
    var tickets = 0;
    final sockets = <FakeSocket>[];
    final second = Completer<void>();
    final api = ApiClient(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'ticket': 'ticket-${++tickets}'}), 201),
      ),
    );
    final connection = EntryChatConnection(
      api,
      42,
      connect: (_) {
        final socket = FakeSocket();
        sockets.add(socket);
        socket.frame({'type': 'welcome'});
        socket.frame({'type': 'confirm_subscription'});
        return socket;
      },
    );
    var confirmations = 0;
    final subscription = connection.events.listen((event) {
      if (event == ChatEvent.connected) {
        if (++confirmations == 1) {
          sockets.first.incoming.close();
        } else {
          second.complete();
        }
      }
    });
    await second.future.timeout(const Duration(seconds: 5));
    expect(tickets, 2);
    connection.dispose();
    await subscription.cancel();
    await sockets.last.incoming.close();
  });

  test('rejects ticket access without opening a socket or retrying', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response('{"message":"Forbidden"}', 403),
      ),
    );
    final connection = EntryChatConnection(
      api,
      42,
      connect: (_) => throw StateError('Must not connect'),
    );
    expect(await connection.events.first, ChatEvent.denied);
    connection.dispose();
  });
}
