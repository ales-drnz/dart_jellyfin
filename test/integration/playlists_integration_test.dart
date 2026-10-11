// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for the full playlist lifecycle
/// ([JellyfinPlaylistsApi]) against a live server seeded by
/// `bootstrap.dart`.
///
/// Covers create -> add -> list -> rename -> move -> remove -> delete,
/// plus idempotency on the second create+delete round.
void main() {
  group(
    'Jellyfin playlists CRUD',
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

      test('create -> add -> rename -> list -> move -> remove -> delete',
          () async {
        final created = await jf.playlists.create(
          name: 'dart_jellyfin smoke playlist',
          itemIds: trackIds.take(2).toList(),
        );
        expect(created.id, isNotEmpty);

        try {
          // Append the remaining track.
          if (trackIds.length > 2) {
            await jf.playlists.addItems(
              playlistId: created.id,
              itemIds: [trackIds[2]],
            );
          }

          // Rename right after the entry write, then verify by fetching as an item
          // (Jellyfin's `/Playlists/{id}` returns a PlaylistDto without a
          // Name field; the rename surfaces on the `/Items/{id}` view).
          // Jellyfin 12.2 loses a rename sent within ~0.5 s of a write that
          // changed the entries; rename() waits that out itself, which is
          // what this proves — no delay here.
          final sent = Stopwatch()..start();
          await jf.playlists.rename(
            playlistId: created.id,
            name: 'dart_jellyfin smoke playlist (renamed)',
          );
          expect(sent.elapsed, greaterThan(const Duration(milliseconds: 500)));
          // A lost rename reads back fine at first; the old name returns
          // when the server saves the entry change, within about a second.
          // So look again after that.
          expect((await jf.items.byId(created.id))!.name, contains('renamed'));
          await Future<void>.delayed(const Duration(seconds: 2));
          expect((await jf.items.byId(created.id))!.name, contains('renamed'));

          var entries = await jf.playlists.items(playlistId: created.id);
          expect(entries.items.length, greaterThanOrEqualTo(2));
          expect(entries.items.length, trackIds.length);

          // Reorder: move the last entry to position 0.
          final lastEntry = entries.items.last;
          final lastEntryId = lastEntry.playlistItemId;
          expect(
            lastEntryId,
            isNotNull,
            reason: 'Each entry must carry a PlaylistItemId',
          );
          await jf.playlists.moveItem(
            playlistId: created.id,
            playlistItemId: lastEntryId!,
            newIndex: 0,
          );
          entries = await jf.playlists.items(playlistId: created.id);
          expect(entries.items.first.playlistItemId, lastEntryId);

          // Remove the (now-first) entry.
          await jf.playlists.removeItems(
            playlistId: created.id,
            entryIds: [lastEntryId],
          );
          entries = await jf.playlists.items(playlistId: created.id);
          expect(entries.items.length, trackIds.length - 1);
        } finally {
          await jf.playlists.delete(created.id);
        }

        // A deleted playlist is a 404 on 12.2.
        await expectLater(
          jf.playlists.byId(created.id),
          throwsA(
            isA<JellyfinException>()
                .having((e) => e.type, 'type', JellyfinErrorType.notFound),
          ),
        );
      });

      test('a second delete fails with notFound', () async {
        final created = await jf.playlists.create(
          name: 'dart_jellyfin idempotency probe',
        );
        await jf.playlists.delete(created.id);

        await expectLater(
          jf.playlists.delete(created.id),
          throwsA(
            isA<JellyfinException>()
                .having((e) => e.type, 'type', JellyfinErrorType.notFound),
          ),
        );
      });
    },
    skip: bootstrapSkipReason,
  );
}
