// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

void main() {
  group('JellyfinAuthHeader', () {
    const c = JellyfinCredentials(
      client: 'Finova',
      device: 'iPhone',
      deviceId: 'abc-uuid',
      version: '1.2.3',
    );

    test('builds without token', () {
      expect(
        JellyfinAuthHeader.build(c),
        'MediaBrowser Client="Finova", Device="iPhone", DeviceId="abc-uuid", Version="1.2.3"',
      );
    });

    test('builds with token appended', () {
      expect(
        JellyfinAuthHeader.build(c, token: 'tok'),
        'MediaBrowser Client="Finova", Device="iPhone", DeviceId="abc-uuid", Version="1.2.3", Token="tok"',
      );
    });

    test('percent-encodes values containing + , and "', () {
      const tricky = JellyfinCredentials(
        client: 'Finova',
        device: 'iPhone 15, "Pro"',
        deviceId: 'abc-uuid',
        version: '1.0.0+42',
      );
      expect(
        JellyfinAuthHeader.build(tricky),
        'MediaBrowser Client="Finova", Device="iPhone%2015%2C%20%22Pro%22", '
        'DeviceId="abc-uuid", Version="1.0.0%2B42"',
      );
    });
  });

  group('JellyfinErrorType', () {
    test('fromHttpStatus mapping', () {
      expect(JellyfinErrorType.fromHttpStatus(401), JellyfinErrorType.auth);
      expect(JellyfinErrorType.fromHttpStatus(404), JellyfinErrorType.notFound);
      expect(
        JellyfinErrorType.fromHttpStatus(500),
        JellyfinErrorType.serverError,
      );
      expect(
        JellyfinErrorType.fromHttpStatus(418),
        JellyfinErrorType.badRequest,
      );
    });
  });

  group('JellyfinQueryResult.fromJson', () {
    test('lifts Items + TotalRecordCount', () {
      final json = {
        'Items': [
          {'Id': 'a', 'Name': 'Alpha', 'Type': 'MusicAlbum'},
          {'Id': 'b', 'Name': 'Beta', 'Type': 'MusicAlbum'},
        ],
        'TotalRecordCount': 42,
        'StartIndex': 0,
      };
      final r = JellyfinQueryResult.fromJson(json, JellyfinItem.fromJson);
      expect(r.totalRecordCount, 42);
      expect(r.startIndex, 0);
      expect(r.items, hasLength(2));
      expect(r.items.first.id, 'a');
      expect(r.items.first.name, 'Alpha');
      expect(r.items.first.type, JellyfinItemKind.musicAlbum);
    });

    test('SearchHints key override', () {
      final json = {
        'SearchHints': [
          {'Id': 'x', 'Name': 'X', 'Type': 'Audio'},
        ],
        'TotalRecordCount': 1,
      };
      final r = JellyfinQueryResult.fromJson(
        json,
        JellyfinSearchHint.fromJson,
        itemsKey: 'SearchHints',
      );
      expect(r.items.single.name, 'X');
    });
  });

  group('JellyfinItem.fromJson', () {
    test('parses an Audio item with media sources', () {
      final json = {
        'Id': '12345',
        'Name': 'Test Track',
        'Type': 'Audio',
        'MediaType': 'Audio',
        'Album': 'Test Album',
        'AlbumId': '999',
        'AlbumArtist': 'Test Artist',
        'AlbumArtists': [
          {'Id': '111', 'Name': 'Test Artist'},
        ],
        'Artists': ['Test Artist', 'Featured Artist'],
        'ArtistItems': [
          {'Id': '111', 'Name': 'Test Artist'},
        ],
        'IndexNumber': 3,
        'ParentIndexNumber': 1,
        'ProductionYear': 2024,
        'RunTimeTicks': 2400000000, // 240s
        'Container': 'flac',
        'HasLyrics': true,
        'Genres': ['Rock', 'Indie'],
        'ImageTags': {'Primary': 'abc123'},
        'AlbumPrimaryImageTag': 'def456',
        'ImageBlurHashes': {
          'Primary': {'abc123': 'LjF...'},
        },
        'UserData': {
          'IsFavorite': true,
          'PlayCount': 5,
          'Played': true,
        },
        'MediaSources': [
          {
            'Id': 'src1',
            'Path': '/data/track.flac',
            'Container': 'flac',
            'Bitrate': 900000,
            'SupportsDirectPlay': true,
            'SupportsTranscoding': true,
            'MediaStreams': [
              {'Type': 'Audio', 'Codec': 'flac', 'BitRate': 900000},
            ],
          },
        ],
      };
      final item = JellyfinItem.fromJson(json);
      expect(item.id, '12345');
      expect(item.name, 'Test Track');
      expect(item.type, JellyfinItemKind.audio);
      expect(item.isAudio, isTrue);
      expect(item.album, 'Test Album');
      expect(item.albumArtist, 'Test Artist');
      expect(item.artists, ['Test Artist', 'Featured Artist']);
      expect(item.albumArtists, ['Test Artist']);
      expect(item.indexNumber, 3);
      expect(item.parentIndexNumber, 1);
      expect(item.productionYear, 2024);
      expect(item.runTimeTicks, 2400000000);
      expect(item.durationMs, 240000);
      expect(item.hasLyrics, isTrue);
      expect(item.genres, ['Rock', 'Indie']);
      expect(item.imageTags['Primary'], 'abc123');
      expect(item.albumPrimaryImageTag, 'def456');
      expect(item.imageBlurHashes['Primary'], 'LjF...');
      expect(item.userData?.isFavorite, isTrue);
      expect(item.isFavorite, isTrue);
      expect(item.userData?.played, isTrue);
      expect(item.userData?.playCount, 5);
      expect(item.mediaSources.single.bitrate, 900000);
      expect(item.mediaSources.single.supportsTranscoding, isTrue);
      expect(item.mediaSources.single.mediaStreams.single.isAudio, isTrue);
    });
  });

  group('JellyfinLyrics', () {
    test('parses synced lyrics + renders to LRC', () {
      final json = {
        'Lyrics': [
          {'Start': 0, 'Text': 'Intro'},
          {'Start': 30000000, 'Text': 'Verse one'}, // 3 seconds
          {'Start': 615000000, 'Text': 'Chorus'}, // 1:01.50
        ],
      };
      final ly = JellyfinLyrics.fromJson(json);
      expect(ly.isSynced, isTrue);
      expect(ly.lines, hasLength(3));
      expect(ly.lines[1].text, 'Verse one');
      expect(ly.lines[1].toLrcLine(), '[00:03.00]Verse one');
      expect(ly.lines[2].toLrcLine(), '[01:01.50]Chorus');
      expect(ly.toLrc(), startsWith('[00:00.00]Intro'));
      expect(ly.toPlainText(), 'Intro\nVerse one\nChorus');
    });

    test('plain (unsynced) lyrics fall back to text only', () {
      final json = {
        'Lyrics': [
          {'Text': 'Plain line 1'},
          {'Text': 'Plain line 2'},
        ],
      };
      final ly = JellyfinLyrics.fromJson(json);
      expect(ly.isSynced, isFalse);
      expect(ly.lines.first.toLrcLine(), 'Plain line 1');
    });
  });

  group('JellyfinView', () {
    test('detects collection types', () {
      final music = JellyfinView.fromJson({
        'Id': 'm',
        'Name': 'My Music',
        'CollectionType': 'music',
      });
      expect(music.isMusic, isTrue);
      expect(music.isMovies, isFalse);

      final movies = JellyfinView.fromJson({
        'Id': 'v',
        'Name': 'Movies',
        'CollectionType': 'movies',
      });
      expect(movies.isMovies, isTrue);
    });
  });

  group('0.4.0 additions', () {
    test('Trickplay is typed by media source and width', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'v1',
        'Name': 'Film',
        'Trickplay': {
          'src1': {
            '320': {
              'Width': 320,
              'Height': 180,
              'TileWidth': 10,
              'TileHeight': 10,
              'ThumbnailCount': 250,
              'Interval': 10000,
              'Bandwidth': 12345,
            },
            'bad': {'Width': 1},
            '160': 'not an object',
          },
          'src2': 'not an object',
        },
      });
      expect(item.trickplay.keys, ['src1']);
      final info = item.trickplay['src1']![320]!;
      expect(item.trickplay['src1']!.keys, [320]);
      expect(info.width, 320);
      expect(info.height, 180);
      expect(info.thumbnailsPerTile, 100);
      expect(info.interval, const Duration(seconds: 10));
      expect(info.bandwidth, 12345);
      expect(info.thumbnailAt(const Duration(seconds: 25)), 2);
      expect(info.tileIndexAt(const Duration(minutes: 20)), 1);
      expect(info.thumbnailAt(const Duration(hours: 9)), 249);
      expect(info.tileIndexAt(const Duration(hours: 9)), 2);
      expect(JellyfinItem.fromJson(const {'Id': 'a'}).trickplay, isEmpty);
    });

    test('trickplay info with no interval points at the first tile', () {
      final info = JellyfinTrickplayInfo.fromJson(const {'Width': 320});
      expect(info.thumbnailAt(const Duration(minutes: 5)), 0);
      expect(info.tileIndexAt(const Duration(minutes: 5)), 0);
    });

    test('a session lists its queue by id', () {
      final s = JellyfinSession.fromJson(const {
        'Id': 's1',
        'NowPlayingQueue': [
          {'Id': 'i1', 'PlaylistItemId': 'p1'},
          {'Id': 'i1', 'PlaylistItemId': 'p2'},
          'skipped',
        ],
        'PlaylistItemId': 'p2',
      });
      expect(s.nowPlayingQueue.map((q) => q.playlistItemId), ['p1', 'p2']);
      expect(s.nowPlayingQueue.first.itemId, 'i1');
      expect(s.playlistItemId, 'p2');
      expect(
        JellyfinSession.fromJson(const {'Id': 's'}).nowPlayingQueue,
        isEmpty,
      );
    });

    test('item counts read AudioBookCount when 13.0 sends it', () {
      final v12 = JellyfinItemCounts.fromJson(const {
        'SongCount': 3,
        'TrailerCount': 1,
        'ProgramCount': 2,
      });
      expect(v12.audioBookCount, isNull);
      expect(v12.trailerCount, 1);
      expect(v12.programCount, 2);
      final v13 = JellyfinItemCounts.fromJson(const {'AudioBookCount': 4});
      expect(v13.audioBookCount, 4);
      expect(v13.trailerCount, 0);
    });
  });
}
