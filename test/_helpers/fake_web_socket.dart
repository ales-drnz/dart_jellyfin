// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// A [WebSocketChannel] a test drives by hand: when the handshake ends,
/// what the server sends, when the socket closes.
library;

import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// The channel handed to `JellyfinNotificationsApi` in place of a socket.
class FakeWebSocketChannel implements WebSocketChannel {
  /// The URI the channel was opened with.
  final Uri uri;

  final Completer<void> _ready = Completer<void>();
  final StreamController<Object?> _incoming = StreamController<Object?>();

  /// What the client wrote.
  // ignore: close_sinks, closed by the code under test
  late final FakeWebSocketSink fakeSink = FakeWebSocketSink(this);

  /// When true, `sink.close()` neither ends the stream nor completes
  /// until [finishClose]: the test orders the two itself.
  bool holdClose = false;

  FakeWebSocketChannel(this.uri);

  /// Ends the handshake.
  void open() => _ready.complete();

  /// Fails the handshake.
  void refuse(Object error) => _ready.completeError(error);

  /// A text frame from the server.
  void serverSends(Object? frame) => _incoming.add(frame);

  /// A transport error from the socket.
  void serverFails(Object error) => _incoming.addError(error);

  /// The server (or the network) ends the socket.
  Future<void> serverCloses() => _incoming.close();

  /// Completes a held `sink.close()`.
  void finishClose() => fakeSink._closed.complete();

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<Object?> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => fakeSink;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The client's half of a [FakeWebSocketChannel].
class FakeWebSocketSink implements WebSocketSink {
  final FakeWebSocketChannel _channel;
  final Completer<void> _closed = Completer<void>();

  /// Every frame the client sent, oldest first.
  final List<Object?> sent = [];

  /// Whether the client closed the socket.
  bool isClosed = false;

  FakeWebSocketSink(this._channel);

  @override
  void add(Object? data) {
    if (isClosed) throw StateError('The sink is closed');
    sent.add(data);
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    if (isClosed) return _closed.future;
    isClosed = true;
    if (!_channel.holdClose) {
      unawaited(_channel._incoming.close());
      _closed.complete();
    }
    return _closed.future;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
