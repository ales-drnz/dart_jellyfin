// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Query-shape assertions for `JellyfinLiveTvApi`. These run without a
/// live server: a capturing Dio [HttpClientAdapter] intercepts each
/// request and records the path + query parameters the wrapper emits,
/// so we can pin down serialization (param names, defaults, omissions)
/// independently of the network.
///
/// They guard the `LiveTv` query contract against regressions:
///   * `channels()` only emits `sortBy` when non-empty, and any value
///     it emits is a valid `ItemSortBy` enum member.
///   * `recordingsSeries()` serializes `status` / `channelId` /
///     `isInProgress` / `seriesTimerId` (the post-rename shape) and has
///     no `isActive` / `isLibraryItem` knobs.
///   * `recordings()` has no `groupId` knob.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// `ItemSortBy` enum members accepted by `/LiveTv/Channels?sortBy=`.
/// Mirrors the upstream Jellyfin `ItemSortBy` enum; kept here so the
/// channels() sort assertion is self-contained.
const _itemSortBy = <String>{
  'Default',
  'AiredEpisodeOrder',
  'Album',
  'AlbumArtist',
  'Artist',
  'DateCreated',
  'OfficialRating',
  'DatePlayed',
  'PremiereDate',
  'StartDate',
  'SortName',
  'Name',
  'Random',
  'Runtime',
  'CommunityRating',
  'ProductionYear',
  'PlayCount',
  'CriticRating',
  'IsFolder',
  'IsUnplayed',
  'IsPlayed',
  'SeriesSortName',
  'VideoBitRate',
  'AirTime',
  'Studio',
  'IsFavoriteOrLiked',
  'DateLastContentAdded',
  'SeriesDatePlayed',
  'ParentIndexNumber',
  'IndexNumber',
  'SimilarityScore',
  'SearchScore',
};

/// Captures the [RequestOptions] of the last request and replies with a
/// canned empty `QueryResult`, so the wrapper's parsing succeeds.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({'Items': <dynamic>[], 'TotalRecordCount': 0}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late JellyfinClient client;

  setUp(() {
    adapter = _CapturingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    client = JellyfinClient(
      credentials: const JellyfinCredentials(
        client: 'Finova',
        device: 'iPhone',
        deviceId: 'abc-uuid',
        version: '1.2.3',
      ),
      baseUrl: 'https://jf.example.test',
      dio: dio,
    );
    client.connect('https://jf.example.test');
    client.setSession(token: 'tok', userId: 'user-1');
  });

  group('JellyfinLiveTvApi.channels', () {
    test('omits sortBy by default', () async {
      await client.liveTv.channels();
      final qp = adapter.last!.queryParameters;
      expect(Uri.parse(adapter.last!.path).path, '/LiveTv/Channels');
      expect(qp.containsKey('sortBy'), isFalse);
      // The native server ordering still travels with sortOrder.
      expect(qp['sortOrder'], 'Ascending');
    });

    test('serialized sortBy is a valid ItemSortBy enum member', () async {
      await client.liveTv
          .channels(sortBy: const ['SortName'], descending: true);
      final qp = adapter.last!.queryParameters;
      expect(qp.containsKey('sortBy'), isTrue);
      final emitted = (qp['sortBy'] as String).split(',');
      for (final s in emitted) {
        expect(
          _itemSortBy.contains(s),
          isTrue,
          reason: '"$s" is not an ItemSortBy enum member',
        );
      }
      expect(qp['sortOrder'], 'Descending');
    });
  });

  group('JellyfinLiveTvApi.recordingsSeries', () {
    test('serializes status/channelId/isInProgress/seriesTimerId', () async {
      await client.liveTv.recordingsSeries(
        channelId: 'ch-1',
        status: 'Completed',
        isInProgress: false,
        seriesTimerId: 'st-1',
      );
      final qp = adapter.last!.queryParameters;
      expect(Uri.parse(adapter.last!.path).path, '/LiveTv/Recordings/Series');
      expect(qp['channelId'], 'ch-1');
      expect(qp['status'], 'Completed');
      expect(qp['isInProgress'], false);
      expect(qp['seriesTimerId'], 'st-1');
      // The dropped legacy knobs must never be serialized.
      expect(qp.containsKey('isActive'), isFalse);
      expect(qp.containsKey('isLibraryItem'), isFalse);
    });
  });

  group('JellyfinLiveTvApi.recordings', () {
    test('does not serialize a groupId param', () async {
      await client.liveTv.recordings(channelId: 'ch-1');
      final qp = adapter.last!.queryParameters;
      expect(Uri.parse(adapter.last!.path).path, '/LiveTv/Recordings');
      expect(qp['channelId'], 'ch-1');
      expect(qp.containsKey('groupId'), isFalse);
    });
  });
}
