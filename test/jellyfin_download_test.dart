// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dart_jellyfin/io.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late Directory dir;
  late JellyfinClient client;
  final body = List<int>.generate(300 * 1024, (i) => i % 251);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dl_test');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      if (req.uri.path == '/missing') {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.contentLength = body.length;
      final slow = req.uri.path == '/slow';
      for (var i = 0; i < body.length; i += 64 * 1024) {
        final end = i + 64 * 1024 > body.length ? body.length : i + 64 * 1024;
        req.response.add(body.sublist(i, end));
        await req.response.flush();
        if (slow) await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await req.response.close();
    });
    client = JellyfinClient(
      credentials: const JellyfinCredentials(
        client: 'c',
        device: 'd',
        deviceId: 'i',
        version: '1',
      ),
      baseUrl: 'http://127.0.0.1:${server.port}',
    );
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  test('streams to the file and reports progress', () async {
    final path = '${dir.path}/a/track.flac';
    final progress = <(int, int?)>[];
    final n = await client.downloadToFile(
      '/slow',
      path,
      absoluteUrl: false,
      onProgress: (r, t) => progress.add((r, t)),
    );
    expect(n, body.length);
    expect(await File(path).readAsBytes(), body);
    expect(File('$path.part').existsSync(), isFalse);
    expect(progress.last, (body.length, body.length));
    expect(progress.length, greaterThan(1));
  });

  test('a cancelled download leaves no file', () async {
    final path = '${dir.path}/b.flac';
    final token = JellyfinCancelToken();
    final call = client.downloadToFile(
      '/slow',
      path,
      absoluteUrl: false,
      cancelToken: token,
      onProgress: (r, _) {
        if (r >= 64 * 1024) token.cancel();
      },
    );
    await expectLater(
      call,
      throwsA(
        isA<JellyfinException>()
            .having((e) => e.isCancelled, 'cancelled', true),
      ),
    );
    expect(File(path).existsSync(), isFalse);
    expect(File('$path.part').existsSync(), isFalse);
  });

  test('a 404 throws and writes nothing', () async {
    final path = '${dir.path}/c.flac';
    await expectLater(
      client.downloadToFile('/missing', path, absoluteUrl: false),
      throwsA(
        isA<JellyfinException>().having((e) => e.isNotFound, 'notFound', true),
      ),
    );
    expect(File(path).existsSync(), isFalse);
  });
}
