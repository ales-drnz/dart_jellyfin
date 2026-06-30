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

      test('create -> add -> list -> rename -> move -> remove -> delete',
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

          var entries = await jf.playlists.items(playlistId: created.id);
          expect(entries.items.length, greaterThanOrEqualTo(2));
          expect(entries.items.length, trackIds.length);

          // Rename, then verify by fetching as an item (Jellyfin's
          // `/Playlists/{id}` returns a PlaylistDto without a Name field;
          // the rename surfaces on the `/Items/{id}` view).
          await jf.playlists.rename(
            playlistId: created.id,
            name: 'dart_jellyfin smoke playlist (renamed)',
          );
          final fetched = await jf.items.byId(created.id);
          expect(fetched, isNotNull);
          expect(fetched!.name, contains('renamed'));

          // Reorder: move the last entry to position 0.
          final lastEntry = entries.items.last;
          final lastEntryId = lastEntry.raw['PlaylistItemId'] as String?;
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
          final newFirstEntryId = entries.items.first.raw['PlaylistItemId'];
          expect(newFirstEntryId, lastEntryId);

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

        // After delete, byId should return null or 404 -> null fallback.
        // Some Jellyfin builds return 404 (which the client throws on);
        // accept either outcome.
        try {
          final gone = await jf.playlists.byId(created.id);
          expect(gone, isNull);
        } on JellyfinException catch (e) {
          expect(
            e.type,
            anyOf(JellyfinErrorType.notFound, JellyfinErrorType.badRequest),
          );
        }
      });

      test('double-delete is idempotent (or fails cleanly with notFound)',
          () async {
        final created = await jf.playlists.create(
          name: 'dart_jellyfin idempotency probe',
        );
        await jf.playlists.delete(created.id);

        try {
          await jf.playlists.delete(created.id);
        } on JellyfinException catch (e) {
          expect(
            e.type,
            anyOf(JellyfinErrorType.notFound, JellyfinErrorType.badRequest),
          );
        }
      });
    },
    skip: bootstrapSkipReason,
  );
}
