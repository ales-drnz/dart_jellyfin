// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Regression tests for the sub-API fixes of 0.4.2: what goes on the wire
/// and what comes back, through a capturing `http.Client`.
library;

import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient jf;

  setUp(() {
    adapter = CapturingAdapter();
    jf = capturingClient(adapter);
  });

  group('mediaInfo.bitrateTestBytesLength', () {
    test('reads the octet-stream body as bytes', () async {
      adapter.respond = (_) => CannedResponse(
        200,
        Uint8List(2048),
        contentType: 'application/octet-stream',
      );
      expect(await jf.mediaInfo.bitrateTestBytesLength(size: 2048), 2048);
      expect(adapter.path, '/Playback/BitrateTest');
      expect(adapter.query['size'], ['2048']);
    });
  });

  group('userData.update', () {
    test('without userData or raw sends no flag', () async {
      adapter.body = '{}';
      await jf.userData.update(itemId: 'item-1');
      expect(adapter.last!.json, <String, Object?>{});
    });

    test('with userData sends its favourite and played flags', () async {
      adapter.body = '{}';
      await jf.userData.update(
        itemId: 'item-1',
        userData: const JellyfinUserData(
          isFavorite: true,
          played: false,
          playCount: 3,
        ),
      );
      final body = adapter.last!.json! as Map<String, Object?>;
      expect(body['IsFavorite'], true);
      expect(body['Played'], false);
      expect(body['PlayCount'], 3);
    });
  });

  group('a client without a session user sends no bare userId', () {
    setUp(() => jf.clearSession());

    Future<void> expectNoUserId(Future<Object?> Function() call) async {
      await call();
      expect(adapter.rawQuery, isNot(contains('userId')));
    }

    test('liveTv.channels', () => expectNoUserId(() => jf.liveTv.channels()));
    test('liveTv.programs', () => expectNoUserId(() => jf.liveTv.programs()));
    test(
      'liveTv.recommendedPrograms',
      () => expectNoUserId(() => jf.liveTv.recommendedPrograms()),
    );
    test(
      'liveTv.recordings',
      () => expectNoUserId(() => jf.liveTv.recordings()),
    );
    test(
      'instantMix.fromItem',
      () => expectNoUserId(() => jf.instantMix.fromItem(itemId: 'i')),
    );
    test(
      'videos.additionalParts',
      () => expectNoUserId(() => jf.videos.additionalParts(itemId: 'i')),
    );
    test('mediaInfo.info', () async {
      adapter.body = '{}';
      await expectNoUserId(() => jf.mediaInfo.info(itemId: 'i'));
    });
    test('mediaInfo.postedInfo leaves UserId out of the body', () async {
      adapter.body = '{}';
      await jf.mediaInfo.postedInfo(
        itemId: 'i',
        deviceProfile: const JellyfinDeviceProfile(),
      );
      final body = adapter.last!.json! as Map<String, Object?>;
      expect(body.containsKey('UserId'), isFalse);
    });
  });

  test('with a session user the same calls send it', () async {
    await jf.liveTv.channels();
    expect(adapter.query['userId'], ['user-1']);
    await jf.videos.additionalParts(itemId: 'i');
    expect(adapter.query['userId'], ['user-1']);
  });

  group('search.hints', () {
    test('falls back to the session user', () async {
      await jf.search.hints(query: 'x');
      expect(adapter.query['userId'], ['user-1']);
    });

    test('an explicit userId wins', () async {
      await jf.search.hints(query: 'x', userId: 'other');
      expect(adapter.query['userId'], ['other']);
    });
  });

  group('user.authenticateWithQuickConnect', () {
    test('an answer without an AccessToken is an auth error', () async {
      adapter.respond = (_) => CannedResponse.json({
        'User': {'Id': 'u', 'Name': 'n'},
      });
      await expectLater(
        jf.user.authenticateWithQuickConnect(secret: 's'),
        throwsA(
          isA<JellyfinException>().having(
            (e) => e.type,
            'type',
            JellyfinErrorType.auth,
          ),
        ),
      );
    });

    test('an answer with one is returned', () async {
      adapter.respond = (_) => CannedResponse.json({
        'AccessToken': 'tok-2',
        'User': {'Id': 'u', 'Name': 'n'},
      });
      final auth = await jf.user.authenticateWithQuickConnect(secret: 's');
      expect(auth.accessToken, 'tok-2');
    });
  });

  group('an answer without the id it was asked for is a parse error', () {
    final parseError = throwsA(
      isA<JellyfinException>().having(
        (e) => e.type,
        'type',
        JellyfinErrorType.parse,
      ),
    );

    setUp(() => adapter.body = '{}');

    test('playlists.create', () async {
      await expectLater(jf.playlists.create(name: 'p'), parseError);
      adapter.body = '{"Id": 7}';
      await expectLater(jf.playlists.create(name: 'p'), completes);
      adapter.body = '{"Id": "pl-1"}';
      expect((await jf.playlists.create(name: 'p')).id, 'pl-1');
    });

    test('user.create and user.currentUser', () async {
      await expectLater(jf.user.create(name: 'n'), parseError);
      await expectLater(jf.user.currentUser(), parseError);
      adapter.body = '{"Id": "u-1", "Name": "n"}';
      expect((await jf.user.create(name: 'n')).id, 'u-1');
      expect((await jf.user.currentUser()).id, 'u-1');
    });

    test('quickConnect.initiate', () async {
      await expectLater(jf.quickConnect.initiate(), parseError);
      adapter.body = '{"Secret": "s", "Code": "123456"}';
      expect((await jf.quickConnect.initiate()).code, '123456');
    });

    test('quickConnect.state with no body', () async {
      adapter.body = '';
      await expectLater(jf.quickConnect.state(secret: 's'), parseError);
    });
  });

  group('signed URL builders', () {
    final stateError = throwsA(
      isA<JellyfinException>().having(
        (e) => e.type,
        'type',
        JellyfinErrorType.state,
      ),
    );

    test('without a session they are a state error, not a broken URL', () {
      jf.clearSession();
      expect(() => jf.items.downloadUrl(itemId: 'i'), stateError);
      expect(() => jf.items.fileUrl(itemId: 'i'), stateError);
      expect(
        () => jf.plugins.imageUrl(pluginId: 'p', version: '1.0'),
        stateError,
      );
      expect(
        () =>
            jf.videos.attachmentUrl(videoId: 'v', mediaSourceId: 'm', index: 0),
        stateError,
      );
    });

    test('without a base URL they are a state error', () {
      jf.disconnect();
      expect(() => jf.items.downloadUrl(itemId: 'i'), stateError);
    });

    test('the token is percent-encoded', () {
      jf.setSession(token: 'to k+&x', userId: 'user-1');
      const signed = '?ApiKey=to+k%2B%26x';
      expect(
        jf.items.downloadUrl(itemId: 'i'),
        'https://jf.example.test/Items/i/Download$signed',
      );
      expect(
        jf.items.fileUrl(itemId: 'i'),
        'https://jf.example.test/Items/i/File$signed',
      );
      expect(
        jf.liveTv.liveRecordingStreamUrl(recordingId: 'r'),
        'https://jf.example.test/LiveTv/LiveRecordings/r/stream$signed',
      );
      expect(Uri.parse(jf.items.downloadUrl(itemId: 'i')).queryParameters, {
        'ApiKey': 'to k+&x',
      });
    });

    test('a font name with a space or a slash stays one path segment', () {
      expect(
        jf.subtitles.fallbackFontUrl(name: 'Noto Sans/CJK.ttf'),
        'https://jf.example.test/FallbackFont/Fonts/Noto%20Sans%2FCJK.ttf'
        '?ApiKey=tok',
      );
    });
  });

  group('free-text path segments are percent-encoded', () {
    setUp(() => adapter.respond = (_) => CannedResponse(204, const []));

    test('sessions commands', () async {
      await jf.sessions.sendCommand(sessionId: 's', command: 'Go Home/x');
      expect(
        adapter.last!.uri.toString(),
        contains('/Sessions/s/Command/Go%20Home%2Fx'),
      );
    });

    test('an API key', () async {
      await jf.apiKey.revoke(key: 'a/b c');
      expect(adapter.last!.uri.toString(), endsWith('/Auth/Keys/a%2Fb%20c'));
    });

    test('a subtitle language and a plugin version', () async {
      adapter.respond = null;
      adapter.body = '[]';
      await jf.subtitles.searchRemote(itemId: 'i', language: 'pt/BR');
      expect(adapter.last!.uri.path, endsWith('/Subtitles/pt%2FBR'));
      adapter.respond = (_) => CannedResponse(204, const []);
      await jf.plugins.uninstallVersion(pluginId: 'p', version: '1.0 beta');
      expect(adapter.last!.uri.toString(), endsWith('/Plugins/p/1.0%20beta'));
    });
  });

  group('a read of one thing answers null on a 404', () {
    setUp(() => adapter.respond = (_) => CannedResponse(404, const []));

    test('playlists.byId', () async {
      expect(await jf.playlists.byId(playlistId: 'gone'), isNull);
    });
    test('liveTv.channel, recording and program', () async {
      expect(await jf.liveTv.channel(channelId: 'gone'), isNull);
      expect(await jf.liveTv.recording(recordingId: 'gone'), isNull);
      expect(await jf.liveTv.program(programId: 'gone'), isNull);
    });
    test('scheduledTasks.byId', () async {
      expect(await jf.scheduledTasks.byId(taskId: 'gone'), isNull);
    });
    test('devices.info', () async {
      expect(await jf.devices.info(id: 'gone'), isNull);
    });
    test('syncPlay.group', () async {
      expect(await jf.syncPlay.group(id: 'gone'), isNull);
    });
    test('lyrics.previewRemote', () async {
      expect(await jf.lyrics.previewRemote(lyricId: 'gone'), isNull);
    });

    test('any other error is still thrown', () async {
      adapter.respond = (_) => CannedResponse(500, const []);
      await expectLater(
        jf.playlists.byId(playlistId: 'p'),
        throwsA(isA<JellyfinException>()),
      );
      adapter.respond = (_) => CannedResponse(403, const []);
      await expectLater(
        jf.devices.info(id: 'd'),
        throwsA(
          isA<JellyfinException>().having((e) => e.isAuthError, 'auth', isTrue),
        ),
      );
    });

    test('and an answer is read as before', () async {
      adapter.respond = null;
      adapter.body = '{"Id": "p1", "Name": "Mix", "Type": "Playlist"}';
      expect((await jf.playlists.byId(playlistId: 'p1'))!.name, 'Mix');
      expect((await jf.liveTv.program(programId: 'p1'))!.id, 'p1');
      adapter.body = '';
      expect(await jf.playlists.byId(playlistId: 'p1'), isNull);
    });
  });

  group('userId: sent when the session has one, left out otherwise', () {
    final calls = <String, Future<Object?> Function(JellyfinClient)>{
      'items.list': (jf) => jf.items.list(),
      'items.count': (jf) => jf.items.count(),
      'items.byId': (jf) => jf.items.byId(itemId: 'i'),
      'items.resume': (jf) => jf.items.resume(),
      'items.root': (jf) => jf.items.root(),
      'items.intros': (jf) => jf.items.intros(itemId: 'i'),
      'items.localTrailers': (jf) => jf.items.localTrailers(itemId: 'i'),
      'items.specialFeatures': (jf) => jf.items.specialFeatures(itemId: 'i'),
      'items.latest': (jf) => jf.items.latest(),
      'library.userViews': (jf) => jf.library.userViews(),
      'playlists.items': (jf) => jf.playlists.items(playlistId: 'p'),
      'playlists.addItems': (jf) =>
          jf.playlists.addItems(playlistId: 'p', itemIds: ['a']),
    };

    for (final MapEntry(key: name, value: call) in calls.entries) {
      test(name, () async {
        // These three answer a bare list.
        const lists = {
          'items.localTrailers',
          'items.specialFeatures',
          'items.latest',
        };
        if (lists.contains(name)) adapter.body = '[]';
        await call(jf);
        expect(adapter.query['userId'], ['user-1'], reason: 'with a user');
        // A token alone: the server acts for the user it belongs to.
        final tokenOnly = capturingClient(adapter)..clearSession();
        await call(tokenOnly);
        expect(adapter.rawQuery, isNot(contains('userId')));
      });
    }

    test('playlists.create puts it in the body, or leaves it out', () async {
      adapter.body = '{"Id": "pl"}';
      await jf.playlists.create(name: 'n');
      expect((adapter.last!.json! as Map)['UserId'], 'user-1');
      jf.clearSession();
      await jf.playlists.create(name: 'n');
      expect((adapter.last!.json! as Map).containsKey('UserId'), isFalse);
    });

    test('audio.universalStreamUrl signs with the token alone', () {
      final connection = capturingClient(adapter);
      expect(
        Uri.parse(
          connection.audio.universalStreamUrl(itemId: 'i'),
        ).queryParameters['UserId'],
        'user-1',
      );
    });
  });
}
