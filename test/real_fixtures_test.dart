// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The typed models against real, anonymised Jellyfin 12.2 responses
/// (`test/fixtures/real/`, captured from the integration stack with tokens,
/// server ids and user names replaced). A field the server renames or
/// retypes fails here, offline.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/real/$name.json').readAsStringSync());

Map<String, Object?> _map(String name) =>
    _fixture(name)! as Map<String, Object?>;

JellyfinQueryResult<JellyfinItem> _items(String name) =>
    JellyfinQueryResult.fromJson(_map(name), JellyfinItem.fromJson);

void main() {
  test('albums with browseFields', () {
    final page = _items('items_albums_browse');
    final album = page.items.first;
    expect(page.totalRecordCount, greaterThanOrEqualTo(1));
    expect(album.type, JellyfinItemKind.musicAlbum);
    expect(album.childCount, 3);
    expect(album.genres, isNotEmpty);
    expect(album.genreItems.map((g) => g.name), album.genres);
    expect(album.dateCreated, isNotNull);
    expect(album.primaryImageTag, isNotNull);
    expect(album.artworkVersion, album.primaryImageTag);
    expect(album.albumArtistItems.map((a) => a.name), album.albumArtists);
    expect(album.albumArtistItems.every((a) => a.id.isNotEmpty), isTrue);
    expect(album.mediaSources, isEmpty, reason: 'not in browseFields');
  });

  test('tracks with musicFields', () {
    final tracks = _items('items_album_tracks_music').items;
    expect(tracks, hasLength(3));
    final t = tracks.first;
    expect(t.isAudio, isTrue);
    expect(t.indexNumber, 1);
    expect(t.durationMs, greaterThan(0));
    expect(t.mediaSources.single.mediaStreams.any((s) => s.isAudio), isTrue);
    expect(t.albumId, isNotNull);
    expect(t.artworkItemId, t.albumId);
    expect(t.artworkVersion, isNotNull);
    expect(t.genreItems, isNotEmpty);
  });

  test('album artists, genres, instant mix', () {
    final artists = _items('artists_album_artists').items;
    expect(artists, isNotEmpty);
    expect(artists.every((a) => a.type == 'MusicArtist'), isTrue);
    final genres = _items('genres_music').items;
    expect(genres.map((g) => g.name), containsAll(['Ambient']));
    expect(_items('instant_mix_genre').items.every((i) => i.isAudio), isTrue);
  });

  test('item counts arrive flat on the item, People typed', () {
    final artists = _items('artists_item_counts').items;
    final artist = artists.firstWhere((a) => (a.songCount ?? 0) > 0);
    expect(artist.albumCount, 1);
    expect(artist.songCount, 3);
    expect(artist.recursiveItemCount, 3);
    expect(artist.movieCount, 0);
    expect(artist.raw.containsKey('ItemCounts'), isFalse);
    final genre = _items('genres_music').items.first;
    expect(genre.albumCount, 1);
    expect(genre.songCount, 1);

    final album = _items('items_album_people').items.single;
    expect(album.recursiveItemCount, 3);
    expect(album.people, isNotEmpty);
    expect(
      album.people.where((p) => p.type == 'AlbumArtist').map((p) => p.name),
      album.albumArtists,
    );
    expect(album.people.every((p) => p.id.isNotEmpty), isTrue);
  });

  test('playlist entries carry their entry id (the item id on 12.2)', () {
    final entries = _items('playlist_items').items;
    expect(entries, hasLength(2));
    expect(entries.every((e) => e.playlistItemId == e.id), isTrue);
  });

  test('enhanced lyrics keep their cues', () {
    final lyrics = JellyfinLyrics.fromJson(_map('lyrics_enhanced'));
    expect(lyrics.hasCues, isTrue);
    expect(lyrics.lines.first.cues.map((c) => c.endPosition), [6, 11]);
    expect(
      lyrics.toLrc(enhanced: true).split('\n').first,
      '[00:01.00]<00:01.00>Hello <00:01.50>world<00:02.00>',
    );
  });

  test('counts, scheduled tasks, item images', () {
    final counts = JellyfinItemCounts.fromJson(_map('items_counts'));
    expect(counts.songCount, 3);
    final tasks = [
      for (final t in _fixture('scheduled_tasks')! as List<Object?>)
        JellyfinScheduledTask.fromJson(t! as Map<String, Object?>),
    ];
    expect(tasks.map((t) => t.key), contains('AudioNormalization'));
    final images = [
      for (final i in _fixture('item_images')! as List<Object?>)
        JellyfinImageInfo.fromJson(i! as Map<String, Object?>),
    ];
    expect(images.first.type, 'Primary');
    expect(images.first.width, greaterThan(0));
  });
}
