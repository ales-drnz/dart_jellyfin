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
}
