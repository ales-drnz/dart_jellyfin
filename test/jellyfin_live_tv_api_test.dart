// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Query-shape assertions for `JellyfinLiveTvApi`. These run without a
/// live server: a capturing `http.Client` intercepts each
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

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

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

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient client;

  setUp(() {
    adapter = CapturingAdapter();
    client = capturingClient(adapter);
  });

  group('JellyfinLiveTvApi.channels', () {
    test('omits sortBy by default', () async {
      await client.liveTv.channels();
      final qp = adapter.last!.uri.queryParameters;
      expect(adapter.last!.uri.path, '/LiveTv/Channels');
      expect(qp.containsKey('sortBy'), isFalse);
      // The native server ordering still travels with sortOrder.
      expect(qp['sortOrder'], 'Ascending');
    });

    test('serialized sortBy is a valid ItemSortBy enum member', () async {
      await client.liveTv.channels(
          sortBy: const [JellyfinSortField.sortName], descending: true);
      final query = adapter.last!.uri.queryParametersAll;
      expect(query.containsKey('sortBy'), isTrue);
      for (final s in query['sortBy']!) {
        expect(
          _itemSortBy.contains(s),
          isTrue,
          reason: '"$s" is not an ItemSortBy enum member',
        );
      }
      expect(adapter.last!.uri.queryParameters['sortOrder'], 'Descending');
    });

    test('multi-column sortBy is repeated, never delimiter-joined', () async {
      await client.liveTv.channels(sortBy: const [
        JellyfinSortField.sortName,
        JellyfinSortField.playCount
      ]);
      final query = adapter.last!.uri.queryParametersAll;
      expect(query['sortBy'], ['SortName', 'PlayCount']);
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
      final qp = adapter.last!.uri.queryParameters;
      expect(adapter.last!.uri.path, '/LiveTv/Recordings/Series');
      expect(qp['channelId'], 'ch-1');
      expect(qp['status'], 'Completed');
      expect(qp['isInProgress'], 'false');
      expect(qp['seriesTimerId'], 'st-1');
      // The dropped legacy knobs must never be serialized.
      expect(qp.containsKey('isActive'), isFalse);
      expect(qp.containsKey('isLibraryItem'), isFalse);
    });
  });

  group('JellyfinLiveTvApi.recordings', () {
    test('does not serialize a groupId param', () async {
      await client.liveTv.recordings(channelId: 'ch-1');
      final qp = adapter.last!.uri.queryParameters;
      expect(adapter.last!.uri.path, '/LiveTv/Recordings');
      expect(qp['channelId'], 'ch-1');
      expect(qp.containsKey('groupId'), isFalse);
    });
  });
}
