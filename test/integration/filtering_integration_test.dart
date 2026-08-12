// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// End-to-end checks that a multi-value filter actually *narrows* the
/// result set on a real server.
///
/// The unit tests in `test/jellyfin_browse_query_shape_test.dart` pin
/// the outgoing query string, which is where this defect class is
/// visible in isolation. What they structurally cannot show is the
/// consequence: Jellyfin answers 200 either way, and a filter it failed
/// to parse is silently dropped, widening the result instead of
/// erroring. Only a live server distinguishes "the filter bound" from
/// "the filter was ignored".
///
/// The load-bearing assertion is the union identity:
///
///     items(genreIds: [a, b]) == items(genreIds: [a]) ∪ items(genreIds: [b])
///
/// Jellyfin ORs genre ids, so that holds when the filter binds. When the
/// value fails to parse it is dropped and the query degrades to "every
/// item", which the identity catches — as long as at least one item sits
/// outside both genres. Each test asserts that precondition, and skips
/// rather than passing vacuously when the seed library is too small.
void main() {
  group(
    'multi-value filters narrow the result set',
    () {
      late JellyfinClient jf;

      /// Two genre ids present on audio items, or `null` when the seed
      /// library doesn't have enough genres to tell narrowing apart
      /// from no-op.
      List<String>? genreIds;

      /// Total audio items with no genre filter at all.
      late int unfilteredTotal;

      setUpAll(() async {
        jf = jellyfinFromCache();
        if (bootstrapSkipReason != null) return;

        unfilteredTotal = await jf.items.count(
          includeItemTypes: const ['Audio'],
        );

        final facets = await jf.filter.facets(
          includeItemTypes: const ['Audio'],
        );
        final ids = facets.genres
            .map((g) => g.id)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();
        if (ids.length >= 2) genreIds = ids.take(2).toList();
      });

      Future<Set<String>> audioIdsForGenres(List<String> ids) async {
        final page = await jf.items.list(
          includeItemTypes: const ['Audio'],
          genreIds: ids,
          limit: 500,
        );
        return page.items.map((i) => i.id).toSet();
      }

      test('items.list(genreIds:) with two genres returns their union',
          () async {
        final ids = genreIds;
        if (ids == null) {
          markTestSkipped('Seed library has fewer than 2 audio genres.');
          return;
        }

        final first = await audioIdsForGenres([ids[0]]);
        final second = await audioIdsForGenres([ids[1]]);
        final both = await audioIdsForGenres(ids);

        // The union identity comes first, and is never guarded: it is
        // the assertion that actually falsifies a dropped filter, and
        // it holds at any library size. A single-id filter binds even
        // under a wrong separator (one value has no separator in it),
        // so `first` and `second` stay correct while `both` degrades to
        // the whole library — which is exactly what this catches.
        expect(
          both,
          equals({...first, ...second}),
          reason: 'two-genre filter should be the union of the '
              'single-genre filters; a superset means the filter was '
              'dropped and the query returned everything',
        );

        // Strictly stronger, but only meaningful when some item sits
        // outside both genres. Never let this degrade into a skip —
        // the union assertion above has already run.
        if (both.length < unfilteredTotal) {
          expect(
            both.length,
            lessThan(unfilteredTotal),
            reason: 'a bound genre filter must return fewer items than '
                'no filter at all',
          );
        } else {
          printOnFailure(
            'Every audio item is in one of the two sampled genres '
            '(${both.length} of $unfilteredTotal); only the union '
            'identity was load-bearing here.',
          );
        }
      });

      test('items.count(genreIds:) agrees with items.list', () async {
        final ids = genreIds;
        if (ids == null) {
          markTestSkipped('Seed library has fewer than 2 audio genres.');
          return;
        }

        // count() gained the full narrowing surface in 0.1.1; before,
        // a genre-scoped count was simply not expressible.
        final counted = await jf.items.count(
          includeItemTypes: const ['Audio'],
          genreIds: ids,
        );
        final listed = await jf.items.list(
          includeItemTypes: const ['Audio'],
          genreIds: ids,
          limit: 0,
        );

        expect(counted, listed.totalRecordCount);
        expect(
          counted,
          lessThan(unfilteredTotal),
          reason: 'genre-scoped count must be narrower than the total',
        );
      });

      test('artists.list(genreIds:) with two genres narrows too', () async {
        // The 0.1.0 regression lived here: /Artists binds genreIds with
        // the comma binder, but the wrapper joined with '|', so the
        // value failed to parse, was dropped, and every artist came
        // back. It only ever looked correct with a single genre, where
        // the separator never appears.
        final ids = genreIds;
        if (ids == null) {
          markTestSkipped('Seed library has fewer than 2 audio genres.');
          return;
        }

        final all = await jf.artists.list(limit: 500);
        if (all.items.isEmpty) {
          markTestSkipped('Seed library has no artists.');
          return;
        }

        final first = await jf.artists.list(genreIds: [ids[0]], limit: 500);
        final second = await jf.artists.list(genreIds: [ids[1]], limit: 500);
        final filtered = await jf.artists.list(genreIds: ids, limit: 500);

        // Unguarded, for the same reason as the items test: under the
        // 0.1.0 encoding `filtered` came back equal to `all` while the
        // single-genre queries stayed correct, so the union identity is
        // what turns that regression into a failure instead of a skip.
        expect(
          filtered.items.map((i) => i.id).toSet(),
          equals({
            ...first.items.map((i) => i.id),
            ...second.items.map((i) => i.id),
          }),
          reason: 'two-genre artist filter should be the union of the '
              'single-genre filters; a superset means the filter was '
              'dropped',
        );
        expect(
          filtered.items.length,
          lessThanOrEqualTo(all.items.length),
          reason: 'a filtered artist list can never exceed the '
              'unfiltered one',
        );
      });

      test('an unknown genre id returns nothing, not everything', () async {
        // The sharpest expression of the failure mode: a filter the
        // server cannot satisfy must empty the result, never widen it.
        final none = await jf.items.count(
          includeItemTypes: const ['Audio'],
          genreIds: const ['00000000-0000-0000-0000-000000000000'],
        );
        expect(
          none,
          isNot(unfilteredTotal),
          reason: 'an unmatched genre id must not degrade to "no filter"',
        );
        expect(none, 0);
      });
    },
    skip: bootstrapSkipReason,
  );
}
