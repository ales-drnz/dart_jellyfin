// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for the library browsing surface
/// ([JellyfinLibraryApi], [JellyfinItemsApi], [JellyfinSearchApi])
/// against a live server seeded by `bootstrap.dart`.
void main() {
  group(
    'Jellyfin library',
    () {
      late JellyfinClient jf;

      setUpAll(() {
        jf = jellyfinFromCache();
      });

      test('userViews returns at least the seeded Music library', () async {
        final views = await jf.library.userViews();
        expect(views, isNotEmpty);
        expect(views.any((v) => v.name == 'Music'), isTrue);
      });

      test('mediaFolders returns the configured media folders', () async {
        final folders = await jf.library.mediaFolders();
        expect(folders.totalRecordCount, greaterThan(0));
      });

      test('items.list returns the seeded audio tracks', () async {
        final result = await jf.items.list(
          includeItemTypes: const ['Audio'],
          limit: 50,
        );
        expect(result.totalRecordCount, greaterThanOrEqualTo(3));
        expect(result.items, isNotEmpty);
        // Bootstrap seeds three "Track N" files via ffmpeg.
        expect(
          result.items.any((i) => i.name.contains('Track')),
          isTrue,
        );
      });

      test('items.count for Audio matches items.list totalRecordCount',
          () async {
        final count = await jf.items.count(includeItemTypes: const ['Audio']);
        final result = await jf.items.list(
          includeItemTypes: const ['Audio'],
          limit: 0,
        );
        expect(count, result.totalRecordCount);
      });

      test('items.byId on a real audio item returns a populated DTO', () async {
        final list = await jf.items.list(
          includeItemTypes: const ['Audio'],
          limit: 1,
        );
        final id = list.items.first.id;
        final item = await jf.items.byId(id);
        expect(item, isNotNull);
        expect(item!.id, id);
        expect(item.type, anyOf('Audio', JellyfinItemKind.audio));
      });

      test('search.hints finds the seeded Track items', () async {
        final hints = await jf.search.hints(query: 'Track');
        expect(hints.items, isNotEmpty);
      });

      test('artists.list returns the seeded "Test Artist"', () async {
        final artists = await jf.artists.list(limit: 20);
        expect(
          artists.items.any((a) => a.name.contains('Test Artist')),
          isTrue,
        );
      });
    },
    skip: bootstrapSkipReason,
  );
}
