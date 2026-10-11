// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Read-only checks against any Jellyfin server, for trying the package on
/// a real library without the Docker stack:
///
///     JELLYFIN_URL=https://jf.example.com JELLYFIN_TOKEN=… \
///       dart test --tags live
///
/// Skipped when the variables are not set. Nothing is written: no
/// playlist, no favourite, no play report.
@Tags(['live'])
library;

import 'dart:io';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

final _url = Platform.environment['JELLYFIN_URL'];
final _token = Platform.environment['JELLYFIN_TOKEN'];
final _skip = _url == null || _token == null
    ? 'set JELLYFIN_URL and JELLYFIN_TOKEN to run against a real server'
    : null;

void main() {
  group(
    'live Jellyfin (read-only)',
    () {
      late JellyfinClient jf;
      late String musicId;

      setUpAll(() async {
        jf = JellyfinClient(
          credentials: const JellyfinCredentials(
            client: 'dart_jellyfin live tests',
            device: 'live-tests',
            deviceId: 'dart-jellyfin-live-tests',
            version: '0.3.0',
          ),
          baseUrl: _url,
          retryPolicy: const JellyfinRetryPolicy(),
        );
        // The token's user, so no user id has to be supplied.
        jf.setSession(token: _token!, userId: '');
        final me = await jf.request<Map<String, Object?>>('/Users/Me');
        jf.setSession(token: _token!, userId: me.data!['Id']! as String);
        final views = await jf.library.userViews();
        musicId = views.firstWhere((v) => v.isMusic).id;
      });

      tearDownAll(() => jf.close());

      test('albums page with browseFields', () async {
        final page = await jf.items.list(
          parentId: musicId,
          includeItemTypes: const [JellyfinItemKind.musicAlbum],
          fields: JellyfinItemsApi.browseFields,
          limit: 20,
        );
        expect(page.items, isNotEmpty);
        expect(page.items.every((a) => a.type == 'MusicAlbum'), isTrue);
      });

      test('artists of this library only', () async {
        final artists =
            await jf.artists.albumArtists(parentId: musicId, limit: 5);
        expect(artists.items, isNotEmpty);
      });

      test('a track with musicFields, its cover and lyrics', () async {
        final track = (await jf.items.list(
          parentId: musicId,
          includeItemTypes: const [JellyfinItemKind.audio],
          fields: JellyfinItemsApi.musicFields,
          limit: 1,
        ))
            .items
            .single;
        expect(track.mediaSources, isNotEmpty);
        final cover = track.artworkItemId;
        if (cover != null) {
          final bytes = await jf.images.fetch(
            itemId: cover,
            tag: track.artworkVersion,
            maxWidth: 256,
            maxHeight: 256,
            format: JellyfinImagesApi.formatJpg,
          );
          expect(bytes, isNotNull);
        }
        if (track.hasLyrics) {
          expect(await jf.lyrics.forItem(track.id), isNotNull);
        }
      });

      test('genres filter music and seed an instant mix', () async {
        final genres = await jf.genres.list(
          parentId: musicId,
          includeItemTypes: const [
            JellyfinItemKind.musicAlbum,
            JellyfinItemKind.audio,
          ],
          limit: 1,
        );
        if (genres.items.isEmpty) return markTestSkipped('no genres');
        final g = genres.items.single;
        final inGenre = await jf.items.list(
          parentId: musicId,
          includeItemTypes: const [JellyfinItemKind.audio],
          genreIds: [g.id],
          limit: 5,
          fields: JellyfinItemsApi.browseFields,
        );
        expect(inGenre.items.every((t) => t.genres.contains(g.name)), isTrue);
        final mix = await jf.instantMix.fromItem(itemId: g.id, limit: 5);
        expect(mix.items.every((i) => i.isAudio), isTrue);
      });

      test('counts', () async {
        final c = await jf.library.counts();
        expect(c.songCount, greaterThan(0));
      });
    },
    skip: _skip,
  );
}
