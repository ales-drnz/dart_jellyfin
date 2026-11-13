// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The life of the `/socket` connection — opening, keep-alive, frames,
/// closing and the races between them — against a fake channel.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dart_jellyfin/src/jellyfin_connection.dart';
import 'package:test/test.dart';

import '_helpers/fake_web_socket.dart';

const _credentials = JellyfinCredentials(
  client: 'Finova',
  device: 'iPhone',
  deviceId: 'abc uuid',
  version: '1.2.3',
);

Matcher _throwsOfType(JellyfinErrorType type) =>
    throwsA(isA<JellyfinException>().having((e) => e.type, 'type', type));

void main() {
  late JellyfinConnection connection;
  late List<FakeWebSocketChannel> channels;
  late JellyfinNotificationsApi api;

  /// Whether a channel's handshake ends as soon as it is opened.
  late bool autoOpen;

  setUp(() {
    autoOpen = true;
    channels = [];
    connection = JellyfinConnection(
      credentials: _credentials,
      baseUrl: 'https://jf.example.test/',
    )..token = 'tok';
    api = JellyfinNotificationsApi(
      connection,
      connector: (uri) {
        final channel = FakeWebSocketChannel(uri);
        if (autoOpen) channel.open();
        channels.add(channel);
        return channel;
      },
    );
  });

  tearDown(() => connection.close());

  test('opens wss://…/socket with the token and the device id', () async {
    await api.connect();
    expect(
      channels.single.uri.toString(),
      'wss://jf.example.test/socket?ApiKey=tok&deviceId=abc+uuid',
    );
    expect(api.isConnected, isTrue);
  });

  test('an http base URL opens ws://', () async {
    connection.baseUrl = 'http://192.0.2.10:8096';
    await api.connect();
    expect(channels.single.uri.scheme, 'ws');
  });

  test('without a base URL or a token it is a state error', () async {
    connection.token = null;
    await expectLater(api.connect(), _throwsOfType(JellyfinErrorType.state));
    expect(channels, isEmpty);
  });

  test('is not connected until the handshake ends', () async {
    autoOpen = false;
    final connecting = api.connect();
    await pumpEventQueue();
    expect(api.isConnected, isFalse);
    channels.single.open();
    await connecting;
    expect(api.isConnected, isTrue);
  });

  test(
    'frames arrive typed; anything that is not a frame is skipped',
    () async {
      final stream = await api.connect();
      final events = <JellyfinEvent>[];
      stream.events().listen(events.add);
      channels.single
        ..serverSends('not json')
        ..serverSends('[1, 2]')
        ..serverSends(const [1, 2, 3])
        ..serverSends(jsonEncode({'MessageType': 'ServerRestarting'}))
        ..serverSends(jsonEncode({'MessageType': 'NeverHeardOf', 'Data': 1}));
      await pumpEventQueue();
      expect(events, hasLength(2));
      expect(events[0], isA<JellyfinServerRestartingEvent>());
      expect(events[1], isA<JellyfinUnknownEvent>());
    },
  );

  test('sends KeepAlive on the interval until closed', () async {
    await api.connect(keepAliveInterval: const Duration(milliseconds: 10));
    // ignore: close_sinks, closed by api.close() below
    final sink = channels.single.fakeSink;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(sink.sent, isNotEmpty);
    expect(jsonDecode(sink.sent.first! as String), {
      'MessageType': 'KeepAlive',
    });
    await api.close();
    final count = sink.sent.length;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(sink.sent, hasLength(count));
  });

  test('send and the feed helpers write their frames', () async {
    await api.connect();
    api
      ..startSessions(interval: const Duration(seconds: 3))
      ..stopSessions()
      ..send(messageType: 'X', data: 1);
    expect(channels.single.fakeSink.sent.map((f) => jsonDecode(f! as String)), [
      {'MessageType': 'SessionsStart', 'Data': '0,3000'},
      {'MessageType': 'SessionsStop'},
      {'MessageType': 'X', 'Data': 1},
    ]);
  });

  test('send before connect is a state error', () {
    expect(
      () => api.send(messageType: 'X'),
      _throwsOfType(JellyfinErrorType.state),
    );
  });

  test('close ends the stream and the socket', () async {
    final stream = await api.connect();
    final done = Completer<void>();
    stream.listen(null, onDone: done.complete);
    await api.close();
    await done.future;
    expect(channels.single.fakeSink.isClosed, isTrue);
    expect(api.isConnected, isFalse);
  });

  test('a socket the server drops ends the stream', () async {
    final stream = await api.connect();
    final done = Completer<void>();
    stream.listen(null, onDone: done.complete);
    await channels.single.serverCloses();
    await done.future;
    expect(api.isConnected, isFalse);
    // And the next connect opens a new socket.
    await api.connect();
    expect(channels, hasLength(2));
  });

  test('a socket error reaches the stream with its cause', () async {
    final stream = await api.connect();
    final errors = <Object>[];
    stream.listen(null, onError: errors.add);
    final cause = StateError('reset');
    channels.single.serverFails(cause);
    await pumpEventQueue();
    expect(
      errors.single,
      isA<JellyfinException>()
          .having((e) => e.type, 'type', JellyfinErrorType.connection)
          .having((e) => e.cause, 'cause', same(cause)),
    );
  });

  test('cancelling the last listener closes the socket', () async {
    final stream = await api.connect();
    final sub = stream.listen(null);
    await sub.cancel();
    await pumpEventQueue();
    expect(channels.single.fakeSink.isClosed, isTrue);
    expect(api.isConnected, isFalse);
  });

  test(
    'a second connect while the first is still opening is refused',
    () async {
      autoOpen = false;
      final first = api.connect();
      await expectLater(api.connect(), _throwsOfType(JellyfinErrorType.state));
      expect(channels, hasLength(1));
      channels.single.open();
      await first;
      expect(api.isConnected, isTrue);
    },
  );

  test(
    'a refused handshake closes the channel and leaves room for another',
    () async {
      autoOpen = false;
      final connecting = api.connect();
      await pumpEventQueue();
      channels.single.refuse(StateError('403'));
      await expectLater(
        connecting,
        _throwsOfType(JellyfinErrorType.connection),
      );
      expect(channels.single.fakeSink.isClosed, isTrue);
      expect(api.isConnected, isFalse);
      autoOpen = true;
      await api.connect();
      expect(api.isConnected, isTrue);
    },
  );

  test('a handshake that never ends times out', () async {
    autoOpen = false;
    await expectLater(
      api.connect(connectTimeout: const Duration(milliseconds: 30)),
      _throwsOfType(JellyfinErrorType.timeout),
    );
    expect(channels.single.fakeSink.isClosed, isTrue);
    expect(api.isConnected, isFalse);
  });

  test(
    'a close still in flight does not tear down the next connection',
    () async {
      await api.connect();
      final old = channels.single..holdClose = true;
      final closing = api.close();
      // The socket ends before close() returns, and the app reconnects.
      await old.serverCloses();
      await pumpEventQueue();
      final stream = await api.connect();
      final frames = <JellyfinNotification>[];
      stream.listen(frames.add);
      old.finishClose();
      await closing;
      await pumpEventQueue();
      expect(api.isConnected, isTrue);
      channels.last.serverSends(jsonEncode({'MessageType': 'KeepAlive'}));
      await pumpEventQueue();
      expect(frames, hasLength(1));
    },
  );

  test('JellyfinClient.close closes the socket', () async {
    final client = JellyfinClient(
      credentials: _credentials,
      baseUrl: 'https://jf.example.test',
    )..setSession(token: 'tok', userId: 'u');
    expect(
      client.withCancelToken(JellyfinCancelToken()).notifications,
      same(client.notifications),
    );
    client.close();
    expect(client.notifications.isConnected, isFalse);
  });
}
