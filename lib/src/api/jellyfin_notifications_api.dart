// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_events.dart';
import '../jellyfin_exception.dart';

/// `/socket` — server-push notifications stream.
///
/// Wraps the upstream WebSocket endpoint (not modelled as a normal
/// OpenAPI operation). After [connect] the server starts pushing
/// events: session updates, library refreshes, scheduled-task
/// progress, user-data changes, etc.
///
/// [connect] emits untyped [JellyfinNotification] frames; the
/// [JellyfinNotificationEvents.events] stream extension (or
/// [JellyfinNotification.event]) decodes them into typed [JellyfinEvent]s:
///
/// ```dart
/// final socket = await jf.notifications.connect();
/// socket.events().listen((event) {
///   switch (event) {
///     case JellyfinUserDataChangedEvent(:final changes):
///       for (final c in changes) favorites.set(c.itemId, c.isFavorite);
///     case JellyfinLibraryChangedEvent():
///       library.reload();
///     case _:
///   }
/// });
/// ```
///
/// Remote-control frames (`Play`, `Playstate`, `GeneralCommand`) reach the
/// socket of the session that owns the access token — the device that
/// signed in — not a session another client opened with the same token.
///
/// The transport speaks the upstream protocol:
///   * client sends `{"MessageType":"KeepAlive"}` every ~30 s
///   * client subscribes to specific channels with
///     `{"MessageType":"SessionsStart","Data":"0,1500"}` (interval in
///     ms) or similar
///   * server pushes `{"MessageType":"<type>","Data":{...}}` frames
///
/// Cancel the [Stream] subscription or call [close] to disconnect.
///
/// {@category Events and downloads}
class JellyfinNotificationsApi {
  final JellyfinConnection _http;
  final WebSocketChannel Function(Uri uri) _open;

  /// The open socket, or `null`.
  _Socket? _socket;

  /// Whether a [connect] is waiting for its handshake.
  bool _connecting = false;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  ///
  /// [connector] opens the socket; tests pass one that answers a fake
  /// channel.
  JellyfinNotificationsApi(
    this._http, {
    @visibleForTesting WebSocketChannel Function(Uri uri)? connector,
  }) : _open = connector ?? WebSocketChannel.connect;

  /// True while a socket is open.
  bool get isConnected => _socket != null;

  /// Open the `/socket` WebSocket and start emitting
  /// [JellyfinNotification]s. Throws [JellyfinException] of type
  /// [JellyfinErrorType.state] when no base URL or token has been
  /// configured or a socket is already open or opening,
  /// [JellyfinErrorType.connection] if the socket cannot be opened, and
  /// [JellyfinErrorType.timeout] when the handshake takes longer than
  /// [connectTimeout].
  ///
  /// Awaits the socket handshake before returning, so the returned stream
  /// is live and [isConnected] is only `true` (and the keep-alive timer
  /// only armed) once the connection is actually open.
  ///
  /// [keepAliveInterval] is how often this client sends a `KeepAlive`
  /// frame; it does not change any timeout on the server. The server
  /// closes the socket after ~60 s of silence, so keep it well under
  /// that — the default 30 s is.
  ///
  /// The stream ends when the socket does, whoever closed it: there is no
  /// automatic reconnection. Call [connect] again from the stream's
  /// `onDone` to reopen it.
  Future<Stream<JellyfinNotification>> connect({
    Duration keepAliveInterval = const Duration(seconds: 30),
    Duration connectTimeout = const Duration(seconds: 15),
  }) async {
    if (_socket != null || _connecting) {
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
    final wsUrl = _toWs(
      '$base/socket?ApiKey=${Uri.encodeQueryComponent(token)}'
      '&deviceId=${Uri.encodeQueryComponent(_http.credentials.deviceId)}',
    );

    _connecting = true;
    WebSocketChannel? channel;
    try {
      channel = _open(Uri.parse(wsUrl));
      await channel.ready.timeout(connectTimeout);
    } catch (e, st) {
      // A channel that never opened still holds a socket attempt.
      unawaited(channel?.sink.close().catchError((Object _) {}));
      throw JellyfinException(
        e is TimeoutException
            ? 'WebSocket handshake timed out'
            : 'WebSocket connection failed: $e',
        type: e is TimeoutException
            ? JellyfinErrorType.timeout
            : JellyfinErrorType.connection,
        cause: e,
        stackTrace: st,
      );
    } finally {
      _connecting = false;
    }

    final socket = _Socket(channel);
    _socket = socket;
    socket.controller.onCancel = () {
      // The last listener left: nobody reads the socket any more.
      if (!socket.controller.hasListener) unawaited(_release(socket));
    };
    socket.subscription = channel.stream.listen(
      (message) {
        if (message is String) {
          final notif = _decode(message);
          if (notif != null) socket.controller.add(notif);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        socket.controller.addError(
          JellyfinException(
            'WebSocket error: $error',
            type: JellyfinErrorType.connection,
            cause: error,
            stackTrace: stackTrace,
          ),
          stackTrace,
        );
      },
      onDone: () => unawaited(_release(socket, closeChannel: false)),
      cancelOnError: false,
    );
    socket.keepAlive = Timer.periodic(keepAliveInterval, (_) {
      try {
        channel!.sink.add(jsonEncode({'MessageType': 'KeepAlive'}));
      } catch (_) {
        // socket already closed; the onDone handler will clean up.
      }
    });

    return socket.controller.stream;
  }

  /// Send an arbitrary frame (e.g. `SessionsStart`, `ScheduledTasksInfoStart`).
  /// See <https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json>
  /// for the upstream message catalog.
  void send({required String messageType, Object? data}) {
    final socket = _socket;
    if (socket == null) {
      throw const JellyfinException(
        'Not connected. Call connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    socket.channel.sink.add(
      jsonEncode({'MessageType': messageType, 'Data': ?data}),
    );
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

  /// Subscribe to new activity-log entries, which arrive as
  /// `JellyfinActivityLogEvent`. Admin only.
  void startActivityLog({Duration interval = const Duration(seconds: 1)}) {
    send(
      messageType: 'ActivityLogEntryStart',
      data: '0,${interval.inMilliseconds}',
    );
  }

  /// Stop the activity-log subscription.
  void stopActivityLog() {
    send(messageType: 'ActivityLogEntryStop');
  }

  /// Disconnect the socket and release resources. Does nothing when no
  /// socket is open.
  Future<void> close() async {
    final socket = _socket;
    if (socket != null) await _release(socket);
  }

  /// Lets go of [socket] — and of nothing else: a socket opened after it
  /// is not touched, however late this one finishes closing.
  Future<void> _release(_Socket socket, {bool closeChannel = true}) async {
    if (identical(_socket, socket)) _socket = null;
    socket.dispose();
    if (closeChannel) {
      try {
        await socket.channel.sink.close();
      } catch (_) {
        // Already closed, or closing failed: there is nothing left to free.
      }
    }
  }

  JellyfinNotification? _decode(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, Object?>) {
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
final class JellyfinNotification {
  /// Upstream `MessageType` (e.g. `'Sessions'`, `'LibraryChanged'`,
  /// `'UserDataChanged'`, `'ScheduledTasksInfo'`, `'KeepAlive'`).
  final String messageType;

  /// Payload of the frame. Most types carry a Map; the sessions
  /// stream carries a list, the keep-alive carries nothing.
  final Object? data;

  /// Raw frame, useful when the message type is not yet promoted to
  /// a typed [JellyfinEvent].
  final Map<String, Object?> raw;

  /// Build a [JellyfinNotification] from its decomposed fields.
  const JellyfinNotification({
    required this.messageType,
    required this.data,
    required this.raw,
  });

  /// Parse a Jellyfin websocket frame (`{MessageType, Data}`).
  factory JellyfinNotification.fromJson(Map<String, Object?> json) =>
      JellyfinNotification(
        messageType: json['MessageType']?.toString() ?? 'Unknown',
        data: json['Data'],
        raw: json,
      );

  /// This frame as a typed [JellyfinEvent]; a [JellyfinUnknownEvent] for a
  /// type without one or a payload of an unexpected shape. Never throws.
  JellyfinEvent get event => JellyfinEvent.fromNotification(this);

  @override
  String toString() => 'JellyfinNotification($messageType)';
}

/// Typed decoding of a [JellyfinNotificationsApi.connect] stream.
///
/// {@category Events and downloads}
extension JellyfinNotificationEvents on Stream<JellyfinNotification> {
  /// Every frame as a [JellyfinEvent]: user-data and library changes,
  /// sessions, remote-control commands, refresh and task progress,
  /// keep-alives; [JellyfinUnknownEvent] for the rest.
  Stream<JellyfinEvent> events() => map((n) => n.event);
}

/// One open socket with what serves it.
final class _Socket {
  final WebSocketChannel channel;
  final StreamController<JellyfinNotification> controller =
      StreamController<JellyfinNotification>.broadcast();
  StreamSubscription<Object?>? subscription;
  Timer? keepAlive;

  _Socket(this.channel);

  /// Stops the keep-alive, the reading and the stream handed to the app.
  void dispose() {
    keepAlive?.cancel();
    unawaited(subscription?.cancel());
    if (!controller.isClosed) unawaited(controller.close());
  }
}
