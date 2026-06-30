// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for the remaining sub-APIs that don't need a tuner or
/// secondary client: [JellyfinQuickConnectApi], [JellyfinHlsApi],
/// [JellyfinTrickplayApi], [JellyfinSubtitlesApi],
/// [JellyfinLocalizationApi], [JellyfinClientLogApi].
void main() {
  group(
    'Jellyfin remaining APIs',
    () {
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

      test('quickConnect.enabled returns a boolean', () async {
        final ok = await jf.quickConnect.enabled();
        expect(ok, isA<bool>());
      });

      test('quickConnect.initiate produces a Code + Secret (if enabled)',
          () async {
        // Many fresh servers ship with Quick Connect disabled — the
        // initiate call then returns 401. We treat that as expected.
        try {
          final state = await jf.quickConnect.initiate();
          expect(state.code, isNotEmpty);
          expect(state.secret, isNotEmpty);
        } on JellyfinException catch (e) {
          expect(
            e.type,
            anyOf(JellyfinErrorType.auth, JellyfinErrorType.badRequest),
          );
        }
      });

      test('hls.audioMasterUrl builds a signed playlist URL', () {
        final url = jf.hls.audioMasterUrl(itemId: trackId);
        expect(url, contains('/Audio/$trackId/master.m3u8'));
        expect(url, contains('api_key='));
      });

      test('hls.audioVariantUrl builds a signed playlist URL', () {
        final url = jf.hls.audioVariantUrl(itemId: trackId);
        expect(url, contains('/Audio/$trackId/main.m3u8'));
        expect(url, contains('api_key='));
      });

      test('trickplay.tileUrl + hlsPlaylistUrl build signed image URLs', () {
        final tile = jf.trickplay.tileUrl(
          itemId: trackId,
          width: 320,
          index: 0,
        );
        expect(tile, contains('/Videos/$trackId/Trickplay/320/0.jpg'));
        expect(tile, contains('api_key='));

        final pl = jf.trickplay.hlsPlaylistUrl(
          itemId: trackId,
          mediaSourceId: trackId,
          width: 320,
        );
        expect(pl, contains('tiles.m3u8'));
        expect(pl, contains('api_key='));
      });

      test('subtitles.streamUrl builds a signed sidecar URL', () {
        final url = jf.subtitles.streamUrl(
          itemId: trackId,
          mediaSourceId: trackId,
          index: 0,
        );
        expect(url, contains('/Subtitles/0/Stream.vtt'));
        expect(url, contains('api_key='));
      });

      test('subtitles.fallbackFonts returns a (typically empty) list',
          () async {
        final fonts = await jf.subtitles.fallbackFonts();
        expect(fonts, isA<List<Map<String, dynamic>>>());
      });

      test('localization.cultures returns the supported audio language list',
          () async {
        final cs = await jf.localization.cultures();
        expect(cs, isNotEmpty);
      });

      test('localization.countries returns the country list', () async {
        final cs = await jf.localization.countries();
        expect(cs, isNotEmpty);
      });

      test('localization.options + parentalRatings return server tables',
          () async {
        final opts = await jf.localization.options();
        expect(opts, isNotEmpty);
        final pr = await jf.localization.parentalRatings();
        expect(pr, isA<List<Map<String, dynamic>>>());
      });

      test('clientLog.upload accepts a small text log without throwing',
          () async {
        final body = Uint8List.fromList(
          utf8.encode('dart_jellyfin integration smoke client log\n'),
        );
        await jf.clientLog.upload(body: body);
      });
    },
    skip: bootstrapSkipReason,
  );
}
