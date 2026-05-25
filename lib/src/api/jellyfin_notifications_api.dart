// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// `/socket` — server-push notifications stream.
///
/// Wraps the upstream WebSocket endpoint (not modelled as a normal
/// OpenAPI operation). After [connect] the server starts pushing
/// events: session updates, library refreshes, scheduled-task
/// progress, user-data changes, etc.
///
/// The transport speaks the upstream protocol:
///   * client sends `{"MessageType":"KeepAlive"}` every ~30 s
///   * client subscribes to specific channels with
///     `{"MessageType":"SessionsStart","Data":"0,1500"}` (interval in
///     ms) or similar
///   * server pushes `{"MessageType":"<type>","Data":{...}}` frames
///
/// Cancel the [Stream] subscription or call [close] to disconnect.
class JellyfinNotificationsApi {
  final JellyfinConnection _http;

  WebSocketChannel? _channel;
  StreamController<JellyfinNotification>? _controller;
  Timer? _keepAlive;
  StreamSubscription<dynamic>? _socketSub;

  JellyfinNotificationsApi(this._http);

  /// True while a socket is open.
  bool get isConnected => _channel != null;

  /// Open the `/socket` WebSocket and start emitting
  /// [JellyfinNotification]s. Throws [JellyfinException] when no
  /// base URL or token has been configured.
  ///
  /// [keepAliveInterval] sets the server-side timeout. The server
  /// closes the socket after ~60 s of silence; the default 30 s
  /// keep-alive is safely under that.
  Stream<JellyfinNotification> connect({
    Duration keepAliveInterval = const Duration(seconds: 30),
  }) {
    if (_channel != null) {
      throw const JellyfinException(
        'Already connected. Call close() before re-connecting.',
        type: JellyfinErrorType.state,
      );
    }
    final base = _http.baseUrl;
    final token = _http.token;
    if (base == null || token == null) {
      throw const JellyfinException(
        'No base URL or token. Call connect() and setSession() first.',
        type: JellyfinErrorType.state,
      );
    }
    final wsUrl = _toWs('$base/socket?api_key=$token'
        '&deviceId=${Uri.encodeQueryComponent(_http.credentials.deviceId)}');

    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    final controller = StreamController<JellyfinNotification>.broadcast(
      onCancel: () {
        // Idempotent — close() releases the underlying channel.
        if (!(_controller?.hasListener ?? false)) {
          close();
        }
      },
    );

    _channel = channel;
    _controller = controller;

    _socketSub = channel.stream.listen(
      (message) {
        if (message is String) {
          final notif = _decode(message);
          if (notif != null) controller.add(notif);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        controller.addError(
          JellyfinException(
            'WebSocket error: $error',
            type: JellyfinErrorType.connection,
          ),
          stackTrace,
        );
      },
      onDone: () {
        controller.close();
        _cleanup();
      },
      cancelOnError: false,
    );

    _keepAlive = Timer.periodic(keepAliveInterval, (_) {
      try {
        channel.sink.add(jsonEncode({'MessageType': 'KeepAlive'}));
      } catch (_) {
        // socket already closed; the onDone handler will clean up.
      }
    });

    return controller.stream;
  }

  /// Send an arbitrary frame (e.g. `SessionsStart`, `ScheduledTasksInfoStart`).
  /// See <https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json>
  /// for the upstream message catalog.
  void send({required String messageType, Object? data}) {
    final ch = _channel;
    if (ch == null) {
      throw const JellyfinException(
        'Not connected. Call connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    ch.sink.add(jsonEncode({
      'MessageType': messageType,
      if (data != null) 'Data': data,
    }));
  }

  /// Subscribe to the sessions channel. Convenience for
  /// `send('SessionsStart', '0,$intervalMs')`.
  void startSessions({Duration interval = const Duration(seconds: 2)}) {
    send(messageType: 'SessionsStart', data: '0,${interval.inMilliseconds}');
  }

  /// Stop the sessions subscription.
  void stopSessions() {
    send(messageType: 'SessionsStop');
  }

  /// Subscribe to scheduled-task progress.
  void startScheduledTasks({Duration interval = const Duration(seconds: 1)}) {
    send(
      messageType: 'ScheduledTasksInfoStart',
      data: '0,${interval.inMilliseconds}',
    );
  }

  /// Stop the scheduled-task subscription.
  void stopScheduledTasks() {
    send(messageType: 'ScheduledTasksInfoStop');
  }

  /// Disconnect the socket and release resources.
  Future<void> close() async {
    await _channel?.sink.close();
    _cleanup();
  }

  void _cleanup() {
    _keepAlive?.cancel();
    _keepAlive = null;
    _socketSub?.cancel();
    _socketSub = null;
    _channel = null;
    if (!(_controller?.isClosed ?? true)) {
      _controller?.close();
    }
    _controller = null;
  }

  JellyfinNotification? _decode(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        return JellyfinNotification.fromJson(decoded);
      }
    } catch (_) {
      // Swallow malformed frames; consumers can still see the raw
      // socket via the JellyfinException if they need it.
    }
    return null;
  }

  String _toWs(String httpUrl) {
    if (httpUrl.startsWith('https://')) {
      return 'wss://${httpUrl.substring(8)}';
    }
    if (httpUrl.startsWith('http://')) {
      return 'ws://${httpUrl.substring(7)}';
    }
    return httpUrl;
  }
}

/// One frame received from the Jellyfin `/socket` WebSocket.
class JellyfinNotification {
  /// Upstream `MessageType` (e.g. `'Sessions'`, `'LibraryChanged'`,
  /// `'UserDataChanged'`, `'ScheduledTasksInfo'`, `'KeepAlive'`).
  final String messageType;

  /// Payload of the frame. Most types carry a Map; the sessions
  /// stream carries a list, the keep-alive carries nothing.
  final Object? data;

  /// Raw frame, useful when the message type is not yet promoted to
  /// a typed accessor.
  final Map<String, dynamic> raw;

  const JellyfinNotification({
    required this.messageType,
    required this.data,
    required this.raw,
  });

  factory JellyfinNotification.fromJson(Map<String, dynamic> json) =>
      JellyfinNotification(
        messageType: json['MessageType']?.toString() ?? 'Unknown',
        data: json['Data'],
        raw: json,
      );

  @override
  String toString() => 'JellyfinNotification($messageType)';
}
