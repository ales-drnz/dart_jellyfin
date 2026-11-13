// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'dart:io';

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

      test('musicArtists lists the MusicArtist items of the library', () async {
        final artists = await jf.artists.musicArtists(parentId: musicId);
        expect(artists.items, isNotEmpty);
        expect(artists.items.map((a) => a.type).toSet(), {'MusicArtist'});

        // The same ids as /Items answers for MusicArtist, not person ids.
        final items = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.musicArtist],
        );
        final itemIds = {for (final i in items.items) i.id};
        expect(artists.items.map((a) => a.id), everyElement(isIn(itemIds)));
        final persons = await jf.artists.list(parentId: musicId);
        expect(
          {
            for (final a in artists.items) a.id,
          }.intersection({for (final p in persons.items) p.id}),
          isEmpty,
        );

        final albumArtists = await jf.artists.musicAlbumArtists(
          parentId: musicId,
        );
        expect(albumArtists.items, isNotEmpty);
        expect(albumArtists.items.map((a) => a.type).toSet(), {'MusicArtist'});
      });

      test('musicArtists is scoped by parentId, /Items is not', () async {
        final views = await jf.library.userViews();
        final other = views.where((v) => !v.isMusic).toList();
        if (other.isEmpty) {
          skipOrFailOnCi('the stack has no library besides Music');
          return;
        }
        final elsewhere = await jf.artists.musicArtists(
          parentId: other.first.id,
        );
        expect(elsewhere.items, isEmpty);
        final unscoped = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.musicArtist],
          parentId: other.first.id,
        );
        expect(unscoped.items, isNotEmpty);
      });

      test('musicArtists sorts and reads the artist\'s favourite', () async {
        final up = await jf.artists.musicArtists(
          parentId: musicId,
          sortBy: const [JellyfinSortField.sortName],
        );
        final down = await jf.artists.musicArtists(
          parentId: musicId,
          sortBy: const [JellyfinSortField.sortName],
          descending: true,
        );
        expect(
          down.items.map((a) => a.id).toList(),
          up.items.map((a) => a.id).toList().reversed.toList(),
        );

        final artist = up.items.first;
        await jf.userData.markFavorite(itemId: artist.id);
        try {
          final favourites = await jf.artists.musicArtists(
            parentId: musicId,
            isFavorite: true,
          );
          expect(favourites.items.map((a) => a.id), [artist.id]);
        } finally {
          await jf.userData.unmarkFavorite(itemId: artist.id);
        }
      });

      test('musicArtists keeps two music libraries apart', () async {
        // A second music library with an artist of its own, made here and
        // removed afterwards. `/Items` lists both libraries' artists for
        // either `parentId`; `/Artists` only that library's.
        const name = 'Music 2';
        const dir =
            'test/integration/seed/jellyfin/Music2/Other Artist/'
            'Other Album';
        final ffmpeg = await Process.run('ffmpeg', [
          '-version',
        ]).then((r) => r.exitCode == 0, onError: (_) => false);
        if (!ffmpeg) {
          skipOrFailOnCi('needs ffmpeg to seed the second library');
          return;
        }
        await Directory(dir).create(recursive: true);
        final made = await Process.run('ffmpeg', [
          '-y',
          '-loglevel',
          'error',
          '-f',
          'lavfi',
          '-i',
          'anullsrc=channel_layout=stereo:sample_rate=44100',
          '-t',
          '3',
          '-c:a',
          'libmp3lame',
          '-b:a',
          '128k',
          '-metadata',
          'title=Other Track',
          '-metadata',
          'artist=Other Artist',
          '-metadata',
          'album_artist=Other Artist',
          '-metadata',
          'album=Other Album',
          '$dir/01 - Other Track.mp3',
        ]);
        expect(made.exitCode, 0, reason: '${made.stderr}');
        await jf.libraryStructure.add(
          name: name,
          collectionType: 'music',
          paths: const ['/media/Music2'],
          refreshLibrary: true,
        );
        try {
          String? secondId;
          JellyfinQueryResult<JellyfinItem>? second;
          final deadline = DateTime.now().add(const Duration(seconds: 90));
          while (DateTime.now().isBefore(deadline)) {
            final views = await jf.library.userViews();
            secondId = views.where((v) => v.name == name).firstOrNull?.id;
            if (secondId != null) {
              second = await jf.artists.musicArtists(parentId: secondId);
              if (second.items.isNotEmpty) break;
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          }
          expect(second?.items.map((a) => a.name), ['Other Artist']);

          final first = await jf.artists.musicArtists(parentId: musicId);
          final firstNames = first.items.map((a) => a.name).toList();
          expect(firstNames, contains('Test Artist'));
          expect(firstNames, isNot(contains('Other Artist')));

          // The defect musicArtists is there for.
          final items = await jf.items.list(
            includeItemTypes: const [JellyfinItemKind.musicArtist],
            parentId: musicId,
          );
          expect(
            items.items.map((a) => a.name),
            containsAll(['Test Artist', 'Other Artist']),
          );
        } finally {
          await jf.libraryStructure.remove(name: name, refreshLibrary: true);
          await Directory(
            'test/integration/seed/jellyfin/Music2',
          ).delete(recursive: true);
        }
      });

      test('a musicArtists id seeds an instant mix', () async {
        final artists = await jf.artists.musicArtists(parentId: musicId);
        final mix = await jf.instantMix.fromArtist(
          artistId: artists.items.first.id,
        );
        expect(mix.items, isNotEmpty);
      });
    });
  }, skip: bootstrapSkipReason);
}
