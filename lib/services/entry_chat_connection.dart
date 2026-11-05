import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_client.dart';
import '../providers/core_providers.dart';

class ChatEvent {
  final String kind;
  final int? messageId;
  const ChatEvent._(this.kind, [this.messageId]);
  static const connected = ChatEvent._('connected');
  static const changed = ChatEvent._('changed');
  static const offline = ChatEvent._('offline');
  static const denied = ChatEvent._('denied');
  const ChatEvent.message(int id) : this._('changed', id);
}

final entryChatEventsProvider =
    StreamProvider.autoDispose.family<ChatEvent, int>((ref, entryId) {
  final connection = EntryChatConnection(ref.watch(apiClientProvider), entryId);
  ref.onDispose(connection.dispose);
  return connection.events;
});

class EntryChatConnection {
  final ApiClient api;
  final int entryId;
  final WebSocketChannel Function(Uri) connect;
  late final StreamController<ChatEvent> _events;
  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry;
  Timer? _watchdog;
  bool _disposed = false;
  int _generation = 0;
  int _attempt = 0;

  EntryChatConnection(
    this.api,
    this.entryId, {
    WebSocketChannel Function(Uri)? connect,
  }) : connect = connect ?? WebSocketChannel.connect {
    _events = StreamController<ChatEvent>(onListen: _open);
  }
  Stream<ChatEvent> get events => _events.stream;

  Future<void> _open() async {
    final generation = ++_generation;
    try {
      final response = await api.post(
        '/api/v1/entries/$entryId/messages/connection_ticket',
        {},
      ).timeout(const Duration(seconds: 15));
      if (_disposed || generation != _generation) return;
      final base = Uri.parse(ApiClient.baseUrl);
      final socket = connect(
        base.replace(
          scheme: base.scheme == 'https' ? 'wss' : 'ws',
          path: '/cable',
          queryParameters: {'ticket': response['ticket'] as String},
        ),
      );
      _socket = socket;
      final identifier =
          jsonEncode({'channel': 'EntryMessagesChannel', 'entry_id': entryId});
      _subscription = socket.stream.listen(
        (raw) {
          if (_disposed || generation != _generation) return;
          _watchdog?.cancel();
          _watchdog =
              Timer(const Duration(seconds: 20), () => _lost(generation));
          try {
            final frame = jsonDecode(raw as String) as Map<String, dynamic>;
            switch (frame['type']) {
              case 'welcome':
                socket.sink.add(
                  jsonEncode(
                    {'command': 'subscribe', 'identifier': identifier},
                  ),
                );
              case 'confirm_subscription':
                _attempt = 0;
                _events.add(ChatEvent.connected);
              case 'reject_subscription':
                _deny();
              case 'disconnect':
                _lost(generation);
              default:
                final event = frame['message'];
                if (event is Map && event['type'] == 'changed') {
                  _events.add(
                    event['message_id'] is int
                        ? ChatEvent.message(event['message_id'] as int)
                        : ChatEvent.changed,
                  );
                }
                if (event is Map && event['type'] == 'access_revoked') _deny();
            }
          } catch (_) {
            _lost(generation);
          }
        },
        onError: (Object error) => _lost(generation),
        onDone: () => _lost(generation),
      );
      await socket.ready.timeout(const Duration(seconds: 15));
      if (_disposed || generation != _generation) return;
      _watchdog ??= Timer(const Duration(seconds: 20), () => _lost(generation));
    } catch (error) {
      if (_disposed || generation != _generation) return;
      if (error is ApiException && [401, 403, 404].contains(error.statusCode)) {
        _deny();
      } else {
        _lost(generation);
      }
    }
  }

  void _closeSocket() {
    _watchdog?.cancel();
    _watchdog = null;
    _subscription?.cancel();
    _subscription = null;
    _socket?.sink.close();
    _socket = null;
  }

  void _deny() {
    if (_disposed) return;
    ++_generation;
    _retry?.cancel();
    _closeSocket();
    _events.add(ChatEvent.denied);
  }

  void _lost(int generation) {
    if (_disposed || generation != _generation) return;
    ++_generation;
    _closeSocket();
    _events.add(ChatEvent.offline);
    final seconds = 1 << (_attempt++).clamp(0, 4);
    _retry = Timer(Duration(seconds: seconds), _open);
  }

  void dispose() {
    _disposed = true;
    ++_generation;
    _retry?.cancel();
    _closeSocket();
    _events.close();
  }
}
