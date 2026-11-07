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
  group('Jellyfin library', () {
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
        includeItemTypes: const [JellyfinItemKind.audio],
        limit: 50,
      );
      expect(result.totalRecordCount, greaterThanOrEqualTo(3));
      expect(result.items, isNotEmpty);
      // Bootstrap seeds three "Track N" files via ffmpeg.
      expect(result.items.any((i) => i.name.contains('Track')), isTrue);
    });

    test('items.count for Audio matches items.list totalRecordCount', () async {
      final count = await jf.items.count(
        includeItemTypes: const [JellyfinItemKind.audio],
      );
      final result = await jf.items.list(
        includeItemTypes: const [JellyfinItemKind.audio],
        limit: 0,
      );
      expect(count, result.totalRecordCount);
    });

    test('items.byId on a real audio item returns a populated DTO', () async {
      final list = await jf.items.list(
        includeItemTypes: const [JellyfinItemKind.audio],
        limit: 1,
      );
      final id = list.items.first.id;
      final item = await jf.items.byId(itemId: id);
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
      expect(artists.items.any((a) => a.name.contains('Test Artist')), isTrue);
    });

    test('an artist person filters items and resolves by name', () async {
      final artist = await jf.artists.byName(name: 'Test Artist');
      expect(artist, isNotNull);
      expect(artist!.type, 'Person');
      final tracks = await jf.items.list(
        includeItemTypes: const [JellyfinItemKind.audio],
        artistIds: [artist.id],
      );
      expect(tracks.items, isNotEmpty);
      expect(await jf.artists.byName(name: 'No Such Artist'), isNull);
      expect((await jf.artists.byName(name: 'test artist'))!.id, artist.id);
    });

    test('artists.byName ignores a person who is no artist', () async {
      const actor = 'dart_jellyfin Test Actor';
      // Credit the actor on a throwaway collection.
      final box = await jf.collection.create(name: 'dart_jellyfin actor probe');
      try {
        final dto = (await jf.request<Map<String, Object?>>(
          '/Items/${box.id}',
          queryParameters: {'userId': jf.userId},
        )).data!;
        await jf.request<void>(
          '/Items/${box.id}',
          method: 'POST',
          data: {
            ...dto,
            'People': [
              {'Name': actor, 'Type': 'Actor'},
            ],
          },
        );
        // /Persons/{name} answers the actor, artists.byName does not.
        expect((await jf.persons.byName(name: actor))!.type, 'Person');
        expect(await jf.artists.byName(name: actor), isNull);
      } finally {
        await jf.library.deleteItem(itemId: box.id);
      }
    });

    group('artists in the music library', () {
      late String musicId;

      setUpAll(() async {
        final views = await jf.library.userViews();
        musicId = views.firstWhere((v) => v.isMusic).id;
      });

      test('the total counts every artist, not the page', () async {
        final all = await jf.artists.list(parentId: musicId);
        expect(all.items, isNotEmpty);
        expect(all.totalRecordCount, all.items.length);

        // A page past the last artist is empty, yet keeps the total.
        final past = await jf.artists.list(
          parentId: musicId,
          startIndex: all.items.length,
        );
        expect(past.items, isEmpty);
        expect(past.totalRecordCount, all.items.length);

        final first = await jf.artists.albumArtists(
          parentId: musicId,
          limit: 1,
        );
        final albumArtists = await jf.artists.albumArtists(parentId: musicId);
        expect(first.items, hasLength(1));
        expect(first.totalRecordCount, albumArtists.items.length);
      });

      test('the names match the obsolete /Artists routes', () async {
        Future<List<String>> obsolete(String path) async {
          final r = await jf.request<Map<String, Object?>>(
            path,
            queryParameters: {'userId': jf.userId, 'parentId': musicId},
          );
          return [
            for (final i in r.data!['Items']! as List)
              (i as Map<String, Object?>)['Name']! as String,
          ]..sort();
        }

        List<String> names(JellyfinQueryResult<JellyfinItem> r) =>
            [for (final i in r.items) i.name]..sort();

        expect(
          names(await jf.artists.list(parentId: musicId)),
          await obsolete('/Artists'),
        );
        expect(
          names(await jf.artists.albumArtists(parentId: musicId)),
          await obsolete('/Artists/AlbumArtists'),
        );
      });
    });
  }, skip: bootstrapSkipReason);
}
