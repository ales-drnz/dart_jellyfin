// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The sub-API methods that return the typed admin, metadata, live TV and
/// account models, against canned answers.
library;

import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

void main() {
  group('sub-API methods', () {
    late CapturingAdapter adapter;
    late JellyfinClient client;

    setUp(() {
      adapter = CapturingAdapter();
      client = capturingClient(adapter);
    });

    test('apiKey.list lifts the Items of the envelope', () async {
      adapter.respond = (_) => CannedResponse.json({
        'Items': [
          {'AccessToken': 'k1', 'AppName': 'ci', 'IsActive': true},
        ],
        'TotalRecordCount': 1,
      });
      final keys = await client.apiKey.list();
      expect(adapter.path, '/Auth/Keys');
      expect(keys.single.accessToken, 'k1');
    });

    test('liveTv.timers and seriesTimers answer typed pages', () async {
      adapter.respond = (_) => CannedResponse.json({
        'Items': [
          {'Id': 'x1', 'Name': 'News'},
        ],
        'TotalRecordCount': 1,
      });
      expect((await client.liveTv.timers()).items.single.id, 'x1');
      expect((await client.liveTv.seriesTimers()).items.single.name, 'News');
    });

    test('an empty body is an empty model, not a failure', () async {
      adapter.respond = (_) => CannedResponse(200, const []);
      expect((await client.system.storage()).libraries, isEmpty);
      expect((await client.branding.configuration()).customCss, isNull);
      expect(await client.localization.countries(), isEmpty);
      expect(
        await client.playlists.userAccess(playlistId: 'p', userId: 'u'),
        isNull,
      );
    });

    test('an object answer of the wrong shape is a parse error', () async {
      adapter.respond = (_) => CannedResponse.json(['not', 'an object']);
      for (final call in [
        client.system.storage,
        client.system.utcTime,
        client.library.counts,
      ]) {
        await expectLater(
          call(),
          throwsA(
            isA<JellyfinException>().having(
              (e) => e.type,
              'type',
              JellyfinErrorType.parse,
            ),
          ),
        );
      }
    });

    test('a list answer of the wrong shape is a parse error', () async {
      adapter.respond = (_) => CannedResponse.json({'not': 'a list'});
      await expectLater(
        client.localization.cultures(),
        throwsA(
          isA<JellyfinException>().having(
            (e) => e.type,
            'type',
            JellyfinErrorType.parse,
          ),
        ),
      );
    });

    test('videos.additionalParts answers a page of items', () async {
      adapter.respond = (_) => CannedResponse.json({
        'Items': [
          {'Id': 'part2', 'Name': 'CD2', 'Type': 'Movie'},
        ],
        'TotalRecordCount': 1,
      });
      final parts = await client.videos.additionalParts(itemId: 'm1');
      expect(parts.items.single.id, 'part2');
      expect(parts.totalRecordCount, 1);
    });

    test('subtitles.getRemote answers the subtitle text', () async {
      adapter.respond = (_) => CannedResponse(
        200,
        utf8.encode('1\n00:00:01,000 --> 00:00:02,000\nPerché sì\n'),
        contentType: 'text/plain; charset=utf-8',
      );
      expect(
        await client.subtitles.getRemote(id: 'os-1'),
        contains('Perché sì'),
      );
      expect(adapter.path, '/Providers/Subtitles/Subtitles/os-1');
      adapter.respond = (_) =>
          CannedResponse.json({'title': 'Not Found'}, status: 404);
      expect(await client.subtitles.getRemote(id: 'none'), isNull);
    });

    test('collection.create answers the new id', () async {
      adapter.respond = (_) => CannedResponse.json({'Id': 'box1'});
      final created = await client.collection.create(name: 'Saga');
      expect(created.id, 'box1');
      expect(adapter.last!.method, 'POST');
    });

    test('collection.create without an id is a parse error', () async {
      for (final body in [
        <int>[],
        utf8.encode('{}'),
        utf8.encode('{"Id":""}'),
      ]) {
        adapter.respond = (_) => CannedResponse(200, body);
        await expectLater(
          client.collection.create(name: 'Saga'),
          throwsA(
            isA<JellyfinException>().having(
              (e) => e.type,
              'type',
              JellyfinErrorType.parse,
            ),
          ),
          reason: utf8.decode(body),
        );
      }
    });
  });
}
