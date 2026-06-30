// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for the content / browse APIs that aren't yet covered
/// elsewhere: [JellyfinCollectionApi], [JellyfinMediaSegmentsApi],
/// [JellyfinStudiosApi], [JellyfinYearsApi], [JellyfinPersonsApi],
/// [JellyfinFilterApi], [JellyfinTrailersApi], [JellyfinChannelsApi],
/// [JellyfinTvShowsApi], [JellyfinMoviesApi], [JellyfinArtistsApi]
/// (album-artists variant), [JellyfinItemLookupApi].
void main() {
  group(
    'Jellyfin content APIs',
    () {
      late JellyfinClient jf;
      late List<String> trackIds;

      setUpAll(() async {
        jf = jellyfinFromCache();
        if (bootstrapSkipReason != null) return;
        final tracks = await jf.items.list(
          includeItemTypes: const ['Audio'],
          limit: 3,
        );
        trackIds = [for (final t in tracks.items) t.id];
      });

      test('collection create -> add -> remove lifecycle', () async {
        final created = await jf.collection.create(
          name: 'dart_jellyfin smoke collection',
          ids: trackIds.take(2).toList(),
        );
        final collectionId = created['Id'] as String?;
        expect(collectionId, isNotNull);

        if (trackIds.length > 2) {
          await jf.collection.addItems(
            collectionId: collectionId!,
            ids: [trackIds[2]],
          );
        }
        await jf.collection.removeItems(
          collectionId: collectionId!,
          ids: trackIds.take(1).toList(),
        );
      });

      test('mediaSegments.forItem returns a (typically empty) query result',
          () async {
        final segs = await jf.mediaSegments.forItem(itemId: trackIds.first);
        expect(segs.items, isA<List<JellyfinMediaSegment>>());
      });

      test('studios.list returns a page (typically empty for music)', () async {
        final s = await jf.studios.list(limit: 10);
        expect(s.items, isA<List<JellyfinItem>>());
      });

      test('years.list returns a (possibly empty) page', () async {
        final y = await jf.years.list(limit: 10);
        expect(y.items, isA<List<JellyfinItem>>());
      });

      test('persons.list returns a (possibly empty) page', () async {
        final p = await jf.persons.list(limit: 10);
        expect(p.items, isA<List<JellyfinItem>>());
      });

      test('filter.facets returns the Filters2 facet payload', () async {
        final f = await jf.filter.facets(
          includeItemTypes: const ['Audio'],
        );
        expect(f, isA<JellyfinQueryFilters>());
      });

      test('filter.legacy returns the legacy filter payload', () async {
        final f = await jf.filter.legacy(
          includeItemTypes: const ['Audio'],
        );
        expect(f, isA<JellyfinQueryFiltersLegacy>());
      });

      test('trailers.list is callable (500 on music-only libraries is OK)',
          () async {
        // Jellyfin returns 500 from /Trailers on libraries that don't
        // have a Trailers collection type configured. We just want to
        // confirm the call shape works; both success and serverError
        // mean the endpoint is reachable.
        try {
          final t = await jf.trailers.list(limit: 10);
          expect(t.items, isA<List<JellyfinItem>>());
        } on JellyfinException catch (e) {
          expect(e.type, JellyfinErrorType.serverError);
        }
      });

      test('channels.list returns a (typically empty) page', () async {
        final c = await jf.channels.list(limit: 10);
        expect(c.items, isA<List<JellyfinItem>>());
      });

      test('tvShows.nextUp returns a (typically empty) page', () async {
        final n = await jf.tvShows.nextUp(limit: 10);
        expect(n.items, isA<List<JellyfinItem>>());
      });

      test('movies.recommendations returns a (typically empty) list', () async {
        final r = await jf.movies.recommendations();
        expect(r, isA<List<JellyfinMovieRecommendation>>());
      });

      test('artists.albumArtists returns the seeded artists', () async {
        final a = await jf.artists.albumArtists(limit: 20);
        expect(a.items, isA<List<JellyfinItem>>());
        // Bootstrap seeds "Test Artist" as the album artist.
        expect(
          a.items.any((x) => x.name.contains('Test Artist')),
          isTrue,
        );
      });

      test('itemLookup.externalIdInfos returns the configured external sources',
          () async {
        final infos = await jf.itemLookup.externalIdInfos(trackIds.first);
        expect(infos, isA<List<Map<String, dynamic>>>());
      });
    },
    skip: bootstrapSkipReason,
  );
}
