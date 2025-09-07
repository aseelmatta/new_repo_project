// websocket_service.dart
//
// This service provides a convenient wrapper around the `web_socket_channel`
// package for connecting to a WebSocket server, listening for JSON
// messages and sending JSON commands.  To use this service, add
// `web_socket_channel` to your `pubspec.yaml` dependencies.
//
// Example usage:
//
//   final wsService = WebSocketService();
//   wsService.connect('ws://10.0.2.2:6789');
//   wsService.messages.listen((msg) {
//     print('Received message: \$msg');
//   });
//   // To send a message:
//   wsService.send({'type': 'ping'});
//   // Don't forget to dispose when done:
//   wsService.disconnect();

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  /// Connect to the WebSocket server at [url].  If a connection is
  /// already open it will be closed before a new one is established.
  void connect(String url) {
    disconnect();
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  /// Register this client with the server by sending a JSON message
  /// containing the currently authenticated user's UID.  The backend
  /// uses the "register" message to map WebSocket connections to
  /// users so that it can deliver targeted events (for example when a
  /// delivery is assigned to a specific courier).  You should call
  /// this method immediately after connecting and obtaining the
  /// current user's UID via AuthService.getUid().
  void registerUser(String uid) {
    if (uid.isNotEmpty) {
      send({'type': 'register', 'uid': uid});
    }
  }

  /// A stream of decoded JSON messages from the server.  Each event
  /// emitted by the underlying `WebSocketChannel` is parsed as JSON
  /// into a `Map<String, dynamic>`.  Messages that cannot be parsed
  /// are ignored.
  Stream<Map<String, dynamic>> get messages {
    if (_channel == null) {
      // Return an empty stream if not connected.  Consumers should
      // check whether the connection is open before subscribing.
      return const Stream.empty();
    }
    return _channel!.stream
        .where((event) => event is String)
        .map((event) {
          try {
            final decoded = json.decode(event as String);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            }
            return <String, dynamic>{};
          } catch (e) {
            return <String, dynamic>{};
          }
        });
  }

  /// Send a JSON‑serializable [data] object to the server.  The
  /// underlying sink will encode the message to a string.
  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(data));
    }
  }

  /// Close the WebSocket connection if one is open.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}