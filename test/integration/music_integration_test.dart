// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// The 0.3 music surface against a live server seeded by `bootstrap.dart`
/// (one music library: one album, three tracks in two genres). Each test
/// leaves the server as it found it.
void main() {
  group(
    'Jellyfin music surface',
    () {
      late JellyfinClient jf;
      late String musicId;
      late JellyfinItem album;
      late List<JellyfinItem> tracks;

      setUpAll(() async {
        jf = jellyfinFromCache();
        if (bootstrapSkipReason != null) return;
        final views = await jf.library.userViews();
        musicId = views.firstWhere((v) => v.isMusic).id;
        album = (await jf.items.list(
          parentId: musicId,
          includeItemTypes: const [JellyfinItemKind.musicAlbum],
          fields: JellyfinItemsApi.browseFields,
        ))
            .items
            .first;
        tracks = (await jf.items.list(
          parentId: album.id,
          includeItemTypes: const [JellyfinItemKind.audio],
          fields: JellyfinItemsApi.musicFields,
          sortBy: const ['IndexNumber'],
        ))
            .items;
      });

      test('/Genres ids are the /MusicGenres ids and filter music', () async {
        final genres = await jf.genres.list(
          parentId: musicId,
          includeItemTypes: const [
            JellyfinItemKind.musicAlbum,
            JellyfinItemKind.audio,
          ],
        );
        // ignore: deprecated_member_use
        final legacy = await jf.musicGenres.list(parentId: musicId);
        expect(
          genres.items.map((g) => g.id).toSet(),
          legacy.items.map((g) => g.id).toSet(),
        );
        final all = await jf.items.count(
          includeItemTypes: const [JellyfinItemKind.audio],
        );
        for (final g in genres.items) {
          final inGenre = await jf.items.list(
            includeItemTypes: const [JellyfinItemKind.audio],
            genreIds: [g.id],
            fields: JellyfinItemsApi.browseFields,
          );
          expect(inGenre.items, isNotEmpty, reason: g.name);
          expect(inGenre.totalRecordCount, lessThan(all), reason: g.name);
          expect(
            inGenre.items.every((t) => t.genres.contains(g.name)),
            isTrue,
            reason: g.name,
          );
        }
      });

      test('instant mix from a genre id answers that genre\'s tracks',
          () async {
        final genre = (await jf.genres.list(
          parentId: musicId,
          includeItemTypes: const [JellyfinItemKind.audio],
        ))
            .items
            .first;
        final mix = await jf.instantMix.fromItem(
          itemId: genre.id,
          limit: 50,
          fields: JellyfinItemsApi.browseFields,
        );
        expect(mix.items, isNotEmpty);
        expect(mix.items.every((i) => i.isAudio), isTrue);
        expect(mix.items.every((i) => i.genres.contains(genre.name)), isTrue);
      });

      test('a track carries its album cover version without any field',
          () async {
        final bare = await jf.items.list(
          parentId: album.id,
          includeItemTypes: const [JellyfinItemKind.audio],
          limit: 1,
        );
        final track = bare.items.single;
        if (album.primaryImageTag == null) {
          markTestSkipped('the seeded album has no cover');
          return;
        }
        expect(track.artworkItemId, album.id);
        expect(track.artworkVersion, album.primaryImageTag);
      });

      test('maxWidth + format=Jpg come back as a fitted JPEG', () async {
        if (album.primaryImageTag == null) {
          markTestSkipped('the seeded album has no cover');
          return;
        }
        final res = await jf.requestBytes(
          jf.images.url(
            itemId: album.id,
            tag: album.artworkVersion,
            maxWidth: 64,
            maxHeight: 64,
            quality: 85,
            format: JellyfinImagesApi.formatJpg,
          ),
        );
        expect(res.contentType, 'image/jpeg');
        final (w, h) = _jpegSize(res.data!);
        expect(w <= 64 && h <= 64, isTrue, reason: '${w}x$h');
        expect(w == 64 || h == 64, isTrue, reason: '${w}x$h');
      });

      test('enableTotalRecordCount: false counts only the page', () async {
        final counted = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.audio],
          limit: 1,
        );
        final uncounted = await jf.items.list(
          includeItemTypes: const [JellyfinItemKind.audio],
          limit: 1,
          enableTotalRecordCount: false,
        );
        expect(counted.totalRecordCount, tracks.length);
        expect(uncounted.totalRecordCount, 1);
      });

      test('enhanced lyrics keep their word cues', () async {
        final track = tracks.first;
        final lrc = utf8.encode(
          '[00:01.00]<00:01.00>Hello <00:01.50>world<00:02.00>\n'
          '[00:02.50]second line\n',
        );
        try {
          await jf.lyrics.upload(
            itemId: track.id,
            fileName: 'probe.lrc',
            body: lrc,
          );
          // Right after an upload the server may answer 404 for a moment
          // while it re-attaches the file; the upload's own answer is the
          // lyric already.
          JellyfinLyrics? read;
          for (var i = 0; i < 20 && read == null; i++) {
            read = await jf.lyrics.forItem(track.id);
            if (read == null) {
              await Future<void>.delayed(const Duration(milliseconds: 500));
            }
          }
          final lyrics = read!;
          expect(lyrics.lines.first.text, 'Hello world');
          if (!lyrics.hasCues) {
            markTestSkipped('this server parsed no word cues from the LRC');
            return;
          }
          expect(lyrics.lines.first.cues.map((c) => c.position), [0, 6]);
          expect(
            lyrics.toLrc(enhanced: true).split('\n').first,
            startsWith('[00:01.00]<00:01.00>Hello <00:01.50>world'),
          );
        } finally {
          await jf.lyrics.delete(track.id);
        }
      });

      test('an HLS transcode lands on this client\'s session', () async {
        final track = tracks.first;
        const ps = 'it-hls-probe';
        final url = jf.hls.audioVariantUrl(
          itemId: track.id,
          playSessionId: ps,
          audioCodec: 'aac',
          audioBitRate: 128000,
          maxStreamingBitrate: 128000,
          segmentContainer: 'ts',
          segmentLength: 6,
          minSegments: 1,
          enableAutoStreamCopy: false,
        );
        final playlist = await jf.request<String>(
          url,
          absoluteUrl: true,
          responseType: JellyfinResponseType.plain,
        );
        final segment = playlist.data!
            .split('\n')
            .firstWhere((l) => l.isNotEmpty && !l.startsWith('#'));
        await jf.requestBytes(
          '/Audio/${track.id}/$segment',
          absoluteUrl: false,
        );
        try {
          await jf.playback.start(
            itemId: track.id,
            playSessionId: ps,
            playMethod: 'Transcode',
          );
          await jf.playback.ping(playSessionId: ps);
          // The server attaches the job to the session within ~10 s.
          var attached = false;
          for (var i = 0; i < 20 && !attached; i++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            final sessions = await jf.sessions.list(
              deviceId: jf.credentials.deviceId,
            );
            attached = sessions.any((s) => s.raw['TranscodingInfo'] != null);
          }
          expect(
            attached,
            isTrue,
            reason: 'the job is filed under the auth header device id',
          );
        } finally {
          await jf.playback.stopped(
            itemId: track.id,
            position: Duration.zero,
            playSessionId: ps,
          );
        }
      });
    },
    skip: bootstrapSkipReason,
  );
}

/// Width and height from a JPEG's SOF marker.
(int, int) _jpegSize(List<int> b) {
  var i = 2;
  while (i + 9 < b.length) {
    if (b[i] != 0xFF) {
      i++;
      continue;
    }
    final marker = b[i + 1];
    final len = (b[i + 2] << 8) | b[i + 3];
    if (marker >= 0xC0 && marker <= 0xC3) {
      final h = (b[i + 5] << 8) | b[i + 6];
      final w = (b[i + 7] << 8) | b[i + 8];
      return (w, h);
    }
    i += 2 + len;
  }
  throw StateError('no SOF marker');
}
