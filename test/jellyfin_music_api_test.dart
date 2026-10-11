// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Wire-contract and model tests for the music surface added in 0.3:
/// word-level lyrics, normalisation gain, artwork versions, image sizing,
/// the `fields` presets and the HLS audio URL.
library;

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
      final lyrics = (await client.lyrics.forItem('t1'))!;
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

    test('browseFields is light and repeated on the wire', () async {
      await client.items.list(
        includeItemTypes: const ['MusicAlbum'],
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

    test('ping names the play session', () async {
      await client.playback.ping(playSessionId: 'ps1');
      expect(adapter.last!.method, 'POST');
      expect(adapter.path, '/Sessions/Playing/Ping');
      expect(adapter.query['playSessionId'], ['ps1']);
    });
  });
}
