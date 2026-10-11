// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The typed server and housekeeping models, decoded from bodies captured
/// from Jellyfin 12.2, and the requests their endpoints send.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient client;

  setUp(() {
    adapter = CapturingAdapter();
    client = capturingClient(adapter);
  });

  test('system.endpointInfo and utcTime', () async {
    adapter.respond = (r) => r.uri.path == '/System/Endpoint'
        ? CannedResponse.json({'IsLocal': false, 'IsInNetwork': true})
        : CannedResponse.json({
            'RequestReceptionTime': '2026-10-11T09:19:23.3266717Z',
            'ResponseTransmissionTime': '2026-10-11T09:19:23.3266717Z',
          });
    final ep = await client.system.endpointInfo();
    expect(ep.isLocal, isFalse);
    expect(ep.isInNetwork, isTrue);
    final t = await client.system.utcTime();
    expect(adapter.path, '/GetUtcTime');
    expect(
      t.requestReceptionTime,
      DateTime.utc(2026, 10, 11, 9, 19, 23, 326, 671),
    );
  });

  test('library.counts', () async {
    adapter.respond = (_) => CannedResponse.json({
          'SongCount': 3,
          'AlbumCount': 1,
          'ArtistCount': 1,
          'BoxSetCount': 1,
          'ItemCount': 11,
        });
    final c = await client.library.counts();
    expect(adapter.path, '/Items/Counts');
    expect(adapter.query['userId'], ['user-1']);
    expect(
      (c.songCount, c.albumCount, c.artistCount, c.movieCount),
      (3, 1, 1, 0),
    );
    expect(c.itemCount, 11);
  });

  test('scheduledTasks.list', () async {
    adapter.respond = (_) => CannedResponse.json([
          {
            'Name': 'Audio Normalization',
            'State': 'Idle',
            'Id': 'ec2f',
            'LastExecutionResult': {
              'StartTimeUtc': '2026-09-08T15:42:55.7174742Z',
              'EndTimeUtc': '2026-09-08T15:42:55.7218297Z',
              'Status': 'Completed',
            },
            'Description': 'Scans files for audio normalization data.',
            'Category': 'Library',
            'IsHidden': false,
            'Key': 'AudioNormalization',
          },
        ]);
    final tasks = await client.scheduledTasks.list(isHidden: false);
    expect(adapter.query['isHidden'], ['false']);
    final t = tasks.single;
    expect(t.key, 'AudioNormalization');
    expect(t.isRunning, isFalse);
    expect(t.lastExecutionResult!.status, 'Completed');
    expect(t.lastExecutionResult!.endTime!.isUtc, isTrue);
  });

  test('devices.list unwraps the query result', () async {
    adapter.respond = (_) => CannedResponse.json({
          'Items': [
            {
              'Name': 'probe',
              'Id': 'bootstrap-dart-jellyfin',
              'LastUserName': 'test_admin',
              'AppName': 'dart_jellyfin_bootstrap',
              'AppVersion': '1',
              'DateLastActivity': '2026-10-11T09:16:27.7026206Z',
            },
          ],
          'TotalRecordCount': 1,
        });
    final d = (await client.devices.list()).single;
    expect(d.id, 'bootstrap-dart-jellyfin');
    expect(d.appName, 'dart_jellyfin_bootstrap');
    expect(d.dateLastActivity, isNotNull);
  });

  test('activityLog.entries keeps the total', () async {
    adapter.respond = (_) => CannedResponse.json({
          'Items': [
            {
              'Id': 120,
              'Name': 'test_admin has finished playing Test Artist - Track 1',
              'Type': 'AudioPlaybackStopped',
              'ItemId': 'b545',
              'Date': '2026-10-11T09:18:21.8522232Z',
              'Severity': 'Information',
            },
          ],
          'TotalRecordCount': 120,
        });
    final page = await client.activityLog.entries(limit: 1);
    expect(adapter.query['limit'], ['1']);
    expect(page.totalRecordCount, 120);
    expect(page.items.single.type, 'AudioPlaybackStopped');
    expect(page.items.single.itemId, 'b545');
  });

  test('images.listItemImages', () async {
    adapter.respond = (_) => CannedResponse.json([
          {
            'ImageType': 'Primary',
            'ImageTag': 'e8ee',
            'BlurHash': 'e9SPX',
            'Height': 700,
            'Width': 700,
            'Size': 191845,
          },
        ]);
    final img = (await client.images.listItemImages('al')).single;
    expect(adapter.path, '/Items/al/Images');
    expect(
      (img.type, img.tag, img.width, img.size),
      ('Primary', 'e8ee', 700, 191845),
    );
  });

  test('lyrics.searchRemote, syncPlay.list, playlists.users', () async {
    adapter.respond = (r) => switch (r.uri.path) {
          '/Audio/t/RemoteSearch/Lyrics' => CannedResponse.json([
              {
                'Id': 'r1',
                'ProviderName': 'LrcLib',
                'Lyrics': {
                  'Lyrics': [
                    {'Text': 'x', 'Start': 0},
                  ],
                },
              },
            ]),
          '/SyncPlay/List' => CannedResponse.json([
              {
                'GroupId': 'g',
                'GroupName': 'Room',
                'State': 'Playing',
                'Participants': ['a', 'b'],
                'LastUpdatedAt': '2026-10-11T09:00:00Z',
              },
            ]),
          _ => CannedResponse.json([
              {'UserId': 'u2', 'CanEdit': true},
            ]),
        };
    final remote = (await client.lyrics.searchRemote('t')).single;
    expect(remote.providerName, 'LrcLib');
    expect(remote.lyrics!.lines.single.text, 'x');
    final group = (await client.syncPlay.list()).single;
    expect(group.participants, ['a', 'b']);
    expect(group.state, 'Playing');
    final perm = (await client.playlists.users('p')).single;
    expect(adapter.path, '/Playlists/p/Users');
    expect((perm.userId, perm.canEdit), ('u2', true));
  });
}
