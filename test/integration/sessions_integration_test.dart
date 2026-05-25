// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for sessions + playback reporting
/// ([JellyfinSessionsApi], [JellyfinPlaybackApi]) against a live
/// server seeded by `bootstrap.dart`.
void main() {
  group('Jellyfin sessions + playback', () {
    late JellyfinClient jf;
    late String trackId;

    setUpAll(() async {
      jf = jellyfinFromCache();
      if (bootstrapSkipReason != null) return;
      final tracks = await jf.items.list(
        includeItemTypes: const ['Audio'],
        limit: 1,
      );
      trackId = tracks.items.first.id;
    });

    test('sessions.list returns the current session', () async {
      // postCapabilities first so this client registers in the
      // server's session table — otherwise an admin-only call to
      // /Sessions may still return the empty list on a fresh server.
      await jf.sessions.postCapabilities();
      final sessions = await jf.sessions.list();
      expect(sessions, isA<List<JellyfinSession>>());
      // The token used by the test fixture should now own a session.
      expect(
        sessions.any((s) => (s.client ?? '').isNotEmpty),
        isTrue,
      );
    });

    test('playback start -> progress -> stopped round trip', () async {
      const playSessionId = 'dart-jellyfin-it-playback';
      await jf.playback.start(
        itemId: trackId,
        playSessionId: playSessionId,
      );
      await jf.playback.progress(
        itemId: trackId,
        position: const Duration(seconds: 5),
        isPaused: false,
        playSessionId: playSessionId,
      );
      await jf.playback.progress(
        itemId: trackId,
        position: const Duration(seconds: 10),
        isPaused: true,
        playSessionId: playSessionId,
      );
      await jf.playback.stopped(
        itemId: trackId,
        position: const Duration(seconds: 12),
        playSessionId: playSessionId,
      );
      // No throw -> success. Jellyfin returns 204 on each report.
    });

    test('reportViewing is accepted by the server', () async {
      await jf.sessions.reportViewing(itemId: trackId);
    });
  }, skip: bootstrapSkipReason);
}
