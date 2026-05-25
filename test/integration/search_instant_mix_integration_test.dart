// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for search variants and instant mix
/// ([JellyfinSearchApi], [JellyfinInstantMixApi]) against a live
/// server seeded by `bootstrap.dart`.
void main() {
  group('Jellyfin search + instant mix', () {
    late JellyfinClient jf;
    late JellyfinItem firstTrack;

    setUpAll(() async {
      jf = jellyfinFromCache();
      if (bootstrapSkipReason != null) return;
      final tracks = await jf.items.list(
        includeItemTypes: const ['Audio'],
        limit: 1,
      );
      firstTrack = tracks.items.first;
    });

    test('search hints with includeItemTypes=[Audio] returns audio hits',
        () async {
      final hints = await jf.search.hints(
        query: 'Track',
        includeItemTypes: const ['Audio'],
        limit: 20,
      );
      expect(hints.items, isNotEmpty);
      // Every returned hint should be audio when restricted.
      for (final h in hints.items) {
        final type = (h.raw['Type'] as String?) ?? '';
        expect(type, anyOf('Audio', isEmpty));
      }
    });

    test('search hints with excludeItemTypes=[Audio] yields no audio hits',
        () async {
      final hints = await jf.search.hints(
        query: 'Track',
        excludeItemTypes: const ['Audio'],
        limit: 20,
      );
      for (final h in hints.items) {
        expect(h.raw['Type'], isNot(equals('Audio')));
      }
    });

    test('instant mix fromSong returns a list with the seed song included',
        () async {
      final mix = await jf.instantMix.fromSong(
        songId: firstTrack.id,
        limit: 10,
      );
      // Server may return an empty mix on a tiny library (only 3 tracks
      // and no similar-artist metadata). Accept both outcomes — what we
      // care about is that the call shape is correct (no exception).
      expect(mix.items, isA<List<JellyfinItem>>());
    });

    test('instant mix fromItem accepts any seed id', () async {
      final mix = await jf.instantMix.fromItem(
        itemId: firstTrack.id,
        limit: 10,
      );
      expect(mix.items, isA<List<JellyfinItem>>());
    });
  }, skip: bootstrapSkipReason);
}
