// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for the browse / playback-adjacent surface
/// ([JellyfinAudioApi], [JellyfinVideosApi], [JellyfinMediaInfoApi],
/// [JellyfinUserDataApi], [JellyfinDisplayPreferencesApi],
/// [JellyfinUserViewsApi], [JellyfinMusicGenresApi],
/// [JellyfinGenresApi], [JellyfinSuggestionsApi],
/// [JellyfinLyricsApi]).
void main() {
  group(
    'Jellyfin browse / playback APIs',
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

      test('audio.universalStreamUrl builds a signed playback URL', () {
        final url = jf.audio.universalStreamUrl(itemId: trackId);
        expect(url, contains('/Audio/$trackId/universal'));
        expect(url, contains('api_key='));
        expect(url, contains('UserId='));
        expect(url, contains('DeviceId='));
      });

      test('audio.directStreamUrl returns url + extension tuple', () {
        final (url, ext) = jf.audio.directStreamUrl(
          itemId: trackId,
          container: 'mp3',
        );
        expect(url, contains('/Audio/$trackId/stream.mp3'));
        expect(url, contains('Static=true'));
        expect(ext, 'mp3');
      });

      test('mediaInfo.info returns PlaybackInfo for an audio item', () async {
        final info = await jf.mediaInfo.info(itemId: trackId);
        expect(info.mediaSources, isNotEmpty);
        expect(info.playSessionId, isNotEmpty);
      });

      test('userData favorite + played round trip', () async {
        // Mark favourite, verify, then unmark.
        final fav = await jf.userData.markFavorite(trackId);
        expect(fav.isFavorite, isTrue);

        final unfav = await jf.userData.unmarkFavorite(trackId);
        expect(unfav.isFavorite, isFalse);

        // Same for played.
        final played = await jf.userData.markPlayed(trackId);
        expect(played.played, isTrue);
        final unplayed = await jf.userData.markUnplayed(trackId);
        expect(unplayed.played, isFalse);

        // get() reflects current state.
        final current = await jf.userData.get(trackId);
        expect(current.isFavorite, isFalse);
        expect(current.played, isFalse);
      });

      test('displayPreferences read + write round trip', () async {
        const id = 'usersettings';
        const client = 'dart_jellyfin_integration_tests';

        // Read current value to compare against.
        final initial = await jf.displayPreferences.get(
          displayPreferencesId: id,
          client: client,
        );
        expect(initial, isA<JellyfinDisplayPreferences>());

        // Write a known value.
        const written = JellyfinDisplayPreferences(
          id: id,
          client: client,
          sortBy: 'SortName',
          sortOrder: 'Descending',
          customPrefs: {'dart_jellyfin_probe': 'v1'},
        );
        await jf.displayPreferences.update(
          displayPreferencesId: id,
          client: client,
          preferences: written,
        );

        // Read it back.
        final round = await jf.displayPreferences.get(
          displayPreferencesId: id,
          client: client,
        );
        expect(round.sortBy, 'SortName');
        expect(round.sortOrder, 'Descending');
        expect(round.customPrefs['dart_jellyfin_probe'], 'v1');
      });

      test('userViews.list returns the configured views', () async {
        final views = await jf.userViews.list();
        expect(views.items, isNotEmpty);
        expect(views.items.any((v) => v.name == 'Music'), isTrue);
      });

      test('musicGenres.list returns a (possibly empty) page', () async {
        final genres = await jf.musicGenres.list(limit: 20);
        expect(genres.items, isA<List<JellyfinItem>>());
      });

      test('genres.list returns a (possibly empty) page', () async {
        final genres = await jf.genres.list(limit: 20);
        expect(genres.items, isA<List<JellyfinItem>>());
      });

      test('suggestions.list returns a (possibly empty) page', () async {
        final s = await jf.suggestions.list(limit: 10);
        expect(s.items, isA<List<JellyfinItem>>());
      });

      test('lyrics.forItem accepts a missing-lyrics response gracefully',
          () async {
        // Our seed uses ffmpeg-generated silence with no lyrics; the API
        // should return null (or an empty payload) rather than throw.
        final ly = await jf.lyrics.forItem(trackId);
        expect(ly, anyOf(isNull, isA<JellyfinLyrics>()));
      });
    },
    skip: bootstrapSkipReason,
  );
}
