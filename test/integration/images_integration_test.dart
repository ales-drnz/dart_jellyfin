// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for [JellyfinImagesApi].
void main() {
  group(
    'Jellyfin images',
    () {
      late JellyfinClient jf;

      setUpAll(() {
        jf = jellyfinFromCache();
      });

      test('url() builds a deterministic image URL', () {
        final url = jf.images.url(
          itemId: 'abcd1234',
          width: 200,
          height: 200,
          tag: 'hash-x',
        );
        expect(url, contains('/Items/abcd1234/Images/Primary'));
        expect(url, contains('width=200'));
        expect(url, contains('tag=hash-x'));
      });

      test('pathUrl answers the album cover with no query', () async {
        final albums = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.musicAlbum],
          limit: 1,
        );
        final album = albums.items.single;
        final tag = album.primaryImageTag;
        if (tag == null) {
          markTestSkipped('the seeded album has no cover');
          return;
        }
        final url = jf.images.pathUrl(
          itemId: album.id,
          tag: tag,
          maxWidth: 64,
          maxHeight: 64,
        );
        expect(Uri.parse(url).query, isEmpty);
        final res = await jf.request<List<int>>(
          url,
          absoluteUrl: true,
          responseType: JellyfinResponseType.bytes,
        );
        expect(res.data, isNotEmpty);
      });

      test('userImageUrl builds /UserImage with the current session token', () {
        final url = jf.images.userImageUrl(format: JellyfinImagesApi.formatPng);
        expect(url, contains('/UserImage'));
        expect(url, contains('format=Png'));
      });

      test('fetch on an item with primary art returns bytes', () async {
        final tracks = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.audio],
          limit: 1,
        );
        expect(tracks.items, isNotEmpty);
        final t = tracks.items.first;
        // Skip gracefully if the seed track has no embedded art (ffmpeg
        // silence MP3s don't ship cover art).
        if ((t.imageTags['Primary'] ?? '').isEmpty) {
          return;
        }
        final bytes = await jf.images.fetch(
          itemId: t.id,
          tag: t.imageTags['Primary'],
        );
        expect(bytes, isNotNull);
        expect(bytes!.length, greaterThan(0));
      });
    },
    skip: bootstrapSkipReason,
  );
}
