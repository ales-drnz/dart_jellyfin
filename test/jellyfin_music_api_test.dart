// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Wire-contract and model tests for the music surface added in 0.3:
/// word-level lyrics, normalisation gain, artwork versions, image sizing,
/// the `fields` presets and the HLS audio URL.
library;

import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

/// 1 s in ticks.
const _s = 10000000;

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient client;

  setUp(() {
    adapter = CapturingAdapter();
    client = capturingClient(adapter);
  });

  group('lyrics', () {
    // The shape `GET /Audio/{id}/Lyrics` sends for an enhanced LRC.
    final payload = {
      'Metadata': {
        'Artist': 'A',
        'Title': 'T',
        'IsSynced': true,
        'Length': 180 * _s,
        'Offset': -500000,
      },
      'Lyrics': [
        {
          'Text': 'Hello world',
          'Start': 12 * _s,
          'Cues': [
            {'Position': 0, 'EndPosition': 5, 'Start': 12 * _s, 'End': 124e6},
            {
              'Position': 6,
              'EndPosition': 11,
              'Start': 124e6.toInt(),
              'End': 131e6.toInt(),
            },
          ],
        },
        {'Text': 'plain synced', 'Start': 15 * _s + 4560000},
        {'Text': 'unsynced'},
      ],
    };

    test('forItem keeps cues and metadata', () async {
      adapter.respond = (_) => CannedResponse.json(payload);
      final lyrics = (await client.lyrics.forItem(itemId: 't1'))!;
      expect(adapter.path, '/Audio/t1/Lyrics');
      expect(lyrics.hasCues, isTrue);
      expect(lyrics.isSynced, isTrue);
      final first = lyrics.lines.first;
      expect(first.cues, hasLength(2));
      expect(first.cues[1].position, 6);
      expect(first.cues[1].endPosition, 11);
      expect(first.cues[1].start, const Duration(milliseconds: 12400));
      expect(first.cues[1].end, const Duration(milliseconds: 13100));
      expect(lyrics.metadata!.title, 'T');
      expect(lyrics.metadata!.isSynced, isTrue);
      expect(lyrics.metadata!.offsetTicks, -500000);
      expect(lyrics.metadata!.lengthTicks, 180 * _s);
    });

    test('toLrc(enhanced: true) writes word timing and keeps the spaces', () {
      final lyrics = JellyfinLyrics.fromJson(payload);
      expect(
        lyrics.toLrc(enhanced: true).split('\n'),
        [
          '[00:12.00]<00:12.00>Hello <00:12.40>world<00:13.10>',
          '[00:15.45]plain synced',
          'unsynced',
        ],
      );
    });

    test('plain toLrc ignores the cues', () {
      final lyrics = JellyfinLyrics.fromJson(payload);
      expect(lyrics.toLrc().split('\n').first, '[00:12.00]Hello world');
    });

    test('out-of-order cues are skipped rather than slicing backwards', () {
      final line = JellyfinLyricLine.fromJson(const {
        'Text': 'ab cd',
        'Cues': [
          {'Position': 3, 'Start': 20000000},
          {'Position': 0, 'Start': 10000000},
        ],
      });
      // No line start of its own: the first cue's.
      expect(line.toLrcLine(enhanced: true), '[00:02.00]ab <00:02.00>cd');
    });

    test('timestamps truncate instead of rounding up', () {
      expect(JellyfinLyricLine.lrcTimestamp(15999999), '00:01.59');
      expect(JellyfinLyricLine.lrcTimestamp(61 * _s), '01:01.00');
    });

    test('audio.lyrics is null on 404 and rethrows other errors', () async {
      adapter.respond = (_) => CannedResponse(404, const []);
      expect(await client.audio.lyrics(itemId: 'none'), isNull);
      expect(adapter.path, '/Audio/none/Lyrics');

      adapter.respond = (_) => CannedResponse(500, const []);
      await expectLater(
        client.audio.lyrics(itemId: 't1'),
        throwsA(
          isA<JellyfinException>().having(
            (e) => e.type,
            'type',
            JellyfinErrorType.serverError,
          ),
        ),
      );
    });

    test('lyricsRaw decodes the body as UTF-8', () async {
      adapter.respond = (_) => CannedResponse(
            200,
            utf8.encode('{"Lyrics":[{"Text":"Perché sì"}]}'),
            contentType: 'application/json; charset=utf-8',
          );
      // ignore: deprecated_member_use_from_same_package
      expect(await client.audio.lyricsRaw(itemId: 't1'), contains('Perché sì'));
    });
  });

  group('playlist rename after an entry write', () {
    const settle = JellyfinPlaylistsApi.renameSettle;

    Future<Duration> timed(Future<void> Function() call) async {
      final sw = Stopwatch()..start();
      await call();
      return sw.elapsed;
    }

    test('waits out renameSettle after addItems', () async {
      adapter.respond = (_) => CannedResponse(204, const []);
      await client.playlists.addItems(playlistId: 'p', itemIds: ['a']);
      final took = await timed(
        () => client.playlists.rename(playlistId: 'p', name: 'n'),
      );
      expect(took, greaterThanOrEqualTo(settle * 0.9));
      expect(adapter.last!.method, 'POST');
      expect(adapter.path, '/Playlists/p');
    });

    test('create with ids, moveItem and update(ids:) count as writes',
        () async {
      adapter.respond = (r) => r.uri.path == '/Playlists'
          ? CannedResponse.json({'Id': 'new'})
          : CannedResponse(204, const []);
      await client.playlists.create(name: 'x', itemIds: ['a']);
      expect(
        await timed(
          () => client.playlists.update(playlistId: 'new', name: 'y'),
        ),
        greaterThanOrEqualTo(settle * 0.9),
      );
      await client.playlists.moveItem(
        playlistId: 'q',
        playlistItemId: 'a',
        newIndex: 0,
      );
      expect(
        await timed(() => client.playlists.rename(playlistId: 'q', name: 'n')),
        greaterThanOrEqualTo(settle * 0.9),
      );
    });

    test('no wait without a recent write to that playlist', () async {
      adapter.respond = (r) => r.uri.path == '/Playlists'
          ? CannedResponse.json({'Id': 'empty'})
          : CannedResponse(204, const []);
      // An empty create writes no entries.
      await client.playlists.create(name: 'x');
      await client.playlists.addItems(playlistId: 'other', itemIds: ['a']);
      final took = await timed(() async {
        await client.playlists.rename(playlistId: 'empty', name: 'n');
        await client.playlists.rename(playlistId: 'never', name: 'n');
      });
      expect(took, lessThan(settle * 0.5));
    });

    test('delete waits too', () async {
      adapter.respond = (_) => CannedResponse(204, const []);
      await client.playlists.addItems(playlistId: 'p', itemIds: ['a']);
      expect(
        await timed(() => client.playlists.delete(playlistId: 'p')),
        greaterThanOrEqualTo(settle * 0.9),
      );
      expect(adapter.last!.method, 'DELETE');
    });

    test('a second rename does not wait again', () async {
      adapter.respond = (_) => CannedResponse(204, const []);
      await client.playlists.removeItems(playlistId: 'p', entryIds: ['a']);
      await client.playlists.rename(playlistId: 'p', name: 'n');
      expect(
        await timed(() => client.playlists.rename(playlistId: 'p', name: 'm')),
        lessThan(settle * 0.5),
      );
    });
  });

  group('text bodies', () {
    const text = 'WEBVTT\n\n00:01.000 --> 00:02.000\nPerché sì, è già\n';

    Future<String?> fetch(List<int> body, {String contentType = 'text/vtt'}) {
      adapter.respond =
          (_) => CannedResponse(200, body, contentType: contentType);
      return client.subtitles.fetch(
        itemId: 'i',
        mediaSourceId: 'm',
        index: 2,
      );
    }

    test('UTF-8 keeps its accented characters', () async {
      expect(await fetch(utf8.encode(text)), text);
    });

    test('a UTF-8 BOM is consumed', () async {
      expect(await fetch([0xEF, 0xBB, 0xBF, ...utf8.encode(text)]), text);
    });

    test('UTF-16 with a BOM decodes, either byte order', () async {
      final units = text.codeUnits;
      final le = [
        0xFF,
        0xFE,
        for (final u in units) ...[u & 0xFF, u >> 8],
      ];
      final be = [
        0xFE,
        0xFF,
        for (final u in units) ...[u >> 8, u & 0xFF],
      ];
      expect(await fetch(le), text);
      expect(await fetch(be), text);
    });

    test('bytes that are not UTF-8 fall back to Latin-1', () async {
      expect(await fetch(latin1.encode(text)), text);
    });

    test('a declared Latin-1 charset is honoured', () async {
      // Valid UTF-8 too, so only the header can say it is Latin-1.
      final bytes = utf8.encode('è');
      expect(
        await fetch(bytes, contentType: 'text/plain; charset=ISO-8859-1'),
        latin1.decode(bytes),
      );
    });

    test('fetchFromPosition decodes the same way', () async {
      adapter.respond = (_) => CannedResponse(200, utf8.encode(text));
      final body = await client.subtitles.fetchFromPosition(
        itemId: 'i',
        mediaSourceId: 'm',
        index: 2,
        startPosition: const Duration(seconds: 1),
      );
      expect(body, text);
    });
  });

  group('items', () {
    test('normalisation gain and artwork version are read', () {
      final track = JellyfinItem.fromJson(const {
        'Id': 't',
        'Name': 'Track',
        'Type': 'Audio',
        'AlbumId': 'al',
        'ImageTags': <String, dynamic>{},
        'AlbumPrimaryImageTag': 'albumtag',
        'NormalizationGain': -7.25,
        'AlbumNormalizationGain': '-6.5',
      });
      expect(track.normalizationGain, -7.25);
      expect(track.albumNormalizationGain, -6.5);
      expect(track.primaryImageTag, isNull);
      expect(track.artworkItemId, 'al');
      expect(track.artworkVersion, 'albumtag');

      final album = JellyfinItem.fromJson(const {
        'Id': 'al',
        'Name': 'Album',
        'ImageTags': {'Primary': 'own'},
      });
      expect(album.artworkItemId, 'al');
      expect(album.artworkVersion, 'own');

      final bare = JellyfinItem.fromJson(const {'Id': 'x', 'Name': 'X'});
      expect(bare.artworkItemId, isNull);
      expect(bare.artworkVersion, isNull);
    });

    test('genre, album-artist and playlist entry ids are typed', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 't',
        'Name': 'Track',
        'GenreItems': [
          {'Name': 'Ambient', 'Id': 'g1'},
        ],
        'AlbumArtists': [
          {'Name': 'Test Artist', 'Id': 'a1'},
        ],
        'PlaylistItemId': 'e1',
      });
      expect(item.genreItems.single.id, 'g1');
      expect(item.genreItems.single.name, 'Ambient');
      expect(item.albumArtistItems.single.id, 'a1');
      expect(item.albumArtists, ['Test Artist']);
      expect(item.playlistItemId, 'e1');
    });

    test('browseFields is light and repeated on the wire', () async {
      await client.items.list(
        includeItemTypes: const [JellyfinItemKind.musicAlbum],
        fields: JellyfinItemsApi.browseFields,
        enableTotalRecordCount: false,
      );
      expect(adapter.query['fields'], JellyfinItemsApi.browseFields);
      expect(adapter.query['enableTotalRecordCount'], ['false']);
      for (final heavy in [
        'MediaSources',
        'MediaStreams',
        'Path',
        'Overview',
      ]) {
        expect(JellyfinItemsApi.browseFields, isNot(contains(heavy)));
      }
    });

    test('every preset value is a real ItemFields member', () {
      // AlbumPrimaryImageTag is not one: the server sends it regardless.
      const itemFields = {
        'Genres', 'DateCreated', 'ChildCount', 'SortName', //
        'PrimaryImageAspectRatio', 'Overview', 'MediaSources',
        'MediaStreams', 'ProviderIds', 'ParentId', 'Path', 'OriginalTitle',
      };
      for (final f in [
        ...JellyfinItemsApi.musicFields,
        ...JellyfinItemsApi.browseFields,
      ]) {
        expect(itemFields, contains(f));
      }
    });
  });

  group('images', () {
    test('url carries the box-fit sizing and encoding', () {
      final url = Uri.parse(
        client.images.url(
          itemId: 'al',
          tag: 'v1',
          maxWidth: 512,
          maxHeight: 512,
          quality: 85,
          format: JellyfinImagesApi.formatJpg,
        ),
      );
      expect(url.path, '/Items/al/Images/Primary');
      expect(url.queryParameters, {
        'tag': 'v1',
        'maxWidth': '512',
        'maxHeight': '512',
        'quality': '85',
        'format': 'Jpg',
      });
    });

    test('backgroundColor takes the hex forms the server parses', () {
      for (final c in ['fff', '#8fff', '000000', '#aBcDeF', 'FF000000']) {
        final url = Uri.parse(
          client.images.url(itemId: 'al', maxWidth: 64, backgroundColor: c),
        );
        expect(url.queryParameters['backgroundColor'], c);
      }
    });

    test('any other backgroundColor throws instead of losing the sizing', () {
      for (final c in ['', 'red', '00000', '1234567', '0x000000', '##000']) {
        expect(
          () => client.images.url(
            itemId: 'al',
            maxWidth: 64,
            backgroundColor: c,
          ),
          throwsArgumentError,
          reason: c,
        );
      }
    });

    test('fetch sends the same sizing and returns the bytes', () async {
      adapter.respond =
          (_) => CannedResponse(200, [1, 2, 3], contentType: 'image/jpeg');
      final bytes = await client.images.fetch(
        itemId: 'al',
        maxWidth: 256,
        maxHeight: 256,
        format: JellyfinImagesApi.formatJpg,
      );
      expect(bytes, [1, 2, 3]);
      expect(adapter.query['maxWidth'], ['256']);
      expect(adapter.query['format'], ['Jpg']);
    });

    test('fetch answers null on 404', () async {
      adapter.respond = (_) => CannedResponse(404, const []);
      expect(await client.images.fetch(itemId: 'none'), isNull);
    });

    test('entity images take maxWidth too', () {
      final url = Uri.parse(
        client.images.artistImageUrl(artistName: 'AC/DC', maxWidth: 300),
      );
      expect(url.path, '/Artists/AC%2FDC/Images/Primary/0');
      expect(url.queryParameters['maxWidth'], '300');
    });
  });

  group('HLS audio', () {
    test('the variant URL uses the auth device id and real param names', () {
      final url = Uri.parse(
        client.hls.audioVariantUrl(
          itemId: 't1',
          playSessionId: 'ps1',
          maxStreamingBitrate: 192000,
          audioBitRate: 192000,
          audioCodec: 'aac',
          segmentContainer: 'ts',
          segmentLength: 6,
          minSegments: 1,
          enableAutoStreamCopy: false,
          breakOnNonKeyFrames: true,
          context: 'Streaming',
        ),
      );
      expect(url.path, '/Audio/t1/main.m3u8');
      final q = url.queryParameters;
      expect(q['DeviceId'], client.credentials.deviceId);
      expect(q['ApiKey'], 'tok');
      expect(q['PlaySessionId'], 'ps1');
      expect(q['SegmentContainer'], 'ts');
      expect(q['SegmentLength'], '6');
      expect(q['MinSegments'], '1');
      expect(q['EnableAutoStreamCopy'], 'false');
      expect(q['BreakOnNonKeyFrames'], 'true');
      expect(q['Context'], 'Streaming');
      // Neither is read by this route.
      expect(q.containsKey('Container'), isFalse);
      expect(q.containsKey('UserId'), isFalse);
    });

    test('every signed audio URL carries the same device id', () {
      final dev = client.credentials.deviceId;
      for (final url in [
        client.hls.audioMasterUrl(itemId: 't1'),
        client.hls.audioVariantUrl(itemId: 't1'),
        client.audio.universalStreamUrl(itemId: 't1'),
        client.audio.directStreamUrl(itemId: 't1').$1,
      ]) {
        expect(Uri.parse(url).queryParameters['DeviceId'], dev, reason: url);
      }
    });

    test('playback reports send the enum wire values', () async {
      await client.playback.progress(
        itemId: 't1',
        position: const Duration(seconds: 3),
        isPaused: true,
        method: JellyfinPlayMethod.transcode,
        order: JellyfinPlaybackOrder.shuffle,
        repeat: JellyfinRepeatMode.one,
      );
      final body = adapter.last!.json! as Map<String, dynamic>;
      expect(body['PlayMethod'], 'Transcode');
      expect(body['PlaybackOrder'], 'Shuffle');
      expect(body['RepeatMode'], 'RepeatOne');
      expect(body['PositionTicks'], 30000000);

      await client.playback.start(itemId: 't1');
      expect((adapter.last!.json! as Map)['PlayMethod'], 'DirectPlay');

      // ignore: deprecated_member_use_from_same_package
      await client.playback.start(itemId: 't1', playMethod: 'DirectStream');
      expect((adapter.last!.json! as Map)['PlayMethod'], 'DirectStream');
      expect(
        () => client.playback.start(
          itemId: 't1',
          method: JellyfinPlayMethod.transcode,
          // ignore: deprecated_member_use_from_same_package
          playMethod: 'Transcode',
        ),
        throwsArgumentError,
      );
    });

    test('ping names the play session', () async {
      await client.playback.ping(playSessionId: 'ps1');
      expect(adapter.last!.method, 'POST');
      expect(adapter.path, '/Sessions/Playing/Ping');
      expect(adapter.query['playSessionId'], ['ps1']);
    });
  });
}
