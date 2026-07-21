import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef GameStateFactory = Map<String, dynamic> Function(Map<String, dynamic> request);

/// In-process WebSocket server that replaces the real game backend during tests.
/// Start it before the test, register action handlers, then point the app's
/// WS_URL dart-define at wsUrl. Guarantees deterministic game state.
class MockGameServer {
  HttpServer? _server;
  final List<WebSocketChannel> _connections = [];
  final Map<String, GameStateFactory> _handlers = {};

  int get port => _server?.port ?? 0;
  String get wsUrl => 'ws://127.0.0.1:$port/ws/game';

  /// Register a handler for a named game action (e.g. 'JOIN_TABLE', 'DROP').
  void onAction(String action, GameStateFactory handler) {
    _handlers[action] = handler;
  }

  Future<void> start() async {
    final wsHandler = webSocketHandler((WebSocketChannel channel) {
      _connections.add(channel);
      channel.stream.listen(
        (message) => _dispatch(channel, message as String),
        onDone: () => _connections.remove(channel),
      );
    });
    _server = await shelf_io.serve(wsHandler, InternetAddress.loopbackIPv4, 0);
  }

  void _dispatch(WebSocketChannel channel, String raw) {
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    final action = payload['action'] as String?;
    if (action != null && _handlers.containsKey(action)) {
      final response = _handlers[action]!(payload);
      channel.sink.add(jsonEncode(response));
    }
  }

  /// Broadcast a game state update to all connected clients.
  void broadcastState(Map<String, dynamic> state) {
    final encoded = jsonEncode({'type': 'GAME_STATE_UPDATE', 'payload': state});
    for (final conn in _connections) {
      conn.sink.add(encoded);
    }
  }

  Future<void> stop() async {
    for (final conn in _connections) {
      await conn.sink.close();
    }
    await _server?.close(force: true);
    _connections.clear();
  }
}
