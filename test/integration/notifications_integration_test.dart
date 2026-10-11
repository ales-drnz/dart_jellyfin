// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Typed events ([JellyfinEvent]) from the `/socket` stream of a live
/// server seeded by `bootstrap.dart`.
void main() {
  group(
    'Jellyfin notifications: typed events',
    () {
      late JellyfinClient jf;
      late String trackId;

      setUpAll(() async {
        jf = jellyfinFromCache();
        if (bootstrapSkipReason != null) return;
        final tracks = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.audio],
          limit: 1,
        );
        trackId = tracks.items.first.id;
      });

      tearDown(() async {
        await jf.notifications.close();
      });

      test('a favourite toggle arrives as JellyfinUserDataChangedEvent',
          () async {
        final before = await jf.userData.get(itemId: trackId);
        final socket = await jf.notifications.connect();
        final changed = socket
            .events()
            .whereType<JellyfinUserDataChangedEvent>()
            .map((e) => e.forItem(trackId))
            .firstWhere((c) => c != null && c.isFavorite != before.isFavorite)
            .timeout(const Duration(seconds: 20));

        try {
          await jf.userData.setFavorite(
            itemId: trackId,
            isFavorite: !before.isFavorite,
          );
          final change = (await changed)!;
          expect(change.itemId, trackId);
          expect(change.isFavorite, !before.isFavorite);
          expect(change.played, before.played);
          expect(change.playCount, before.playCount);
        } finally {
          await jf.userData.setFavorite(
            itemId: trackId,
            isFavorite: before.isFavorite,
          );
        }
        final after = await jf.userData.get(itemId: trackId);
        expect(after.isFavorite, before.isFavorite);
      });

      test('the first frame is ForceKeepAlive with the server timeout',
          () async {
        final socket = await jf.notifications.connect();
        final first = await socket
            .events()
            .whereType<JellyfinKeepAliveEvent>()
            .first
            .timeout(const Duration(seconds: 20));
        expect(first.isForced, isTrue);
        expect(first.timeout, greaterThan(Duration.zero));
      });
    },
    skip: bootstrapSkipReason,
  );
}

extension<T> on Stream<T> {
  Stream<S> whereType<S>() => where((e) => e is S).cast<S>();
}
