// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/{ItemType}/{id}/InstantMix` — server-side radio.
///
/// Jellyfin generates a "Mix" — a list of related audio items — from
/// any seed item (song, album, artist, playlist, genre). The mix
/// quality depends on the server's metadata + similar-artist
/// recommendations.
///
/// Maps the `InstantMix` OpenAPI tag (8 operations). Each helper
/// returns a [JellyfinQueryResult] of [JellyfinItem] (same shape as
/// `items.list()`), so the result drops straight into a UI list.
class JellyfinInstantMixApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinInstantMixApi(this._http);

  /// `/Items/{itemId}/InstantMix` — works on any item kind the server
  /// understands as a seed (song, album, artist, mixed item id).
  Future<JellyfinQueryResult<JellyfinItem>> fromItem({
    required String itemId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/Items/$itemId/InstantMix',
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/Songs/{songId}/InstantMix` — seeded by a song.
  Future<JellyfinQueryResult<JellyfinItem>> fromSong({
    required String songId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/Songs/$songId/InstantMix',
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/Albums/{albumId}/InstantMix`.
  Future<JellyfinQueryResult<JellyfinItem>> fromAlbum({
    required String albumId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/Albums/$albumId/InstantMix',
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/Artists/{artistId}/InstantMix` (modern variant — uses item id).
  Future<JellyfinQueryResult<JellyfinItem>> fromArtist({
    required String artistId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/Artists/$artistId/InstantMix',
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/MusicGenres/{name}/InstantMix` (by name).
  Future<JellyfinQueryResult<JellyfinItem>> fromMusicGenre({
    required String name,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/MusicGenres/$name/InstantMix',
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/MusicGenres/InstantMix?id={genreId}` (by id).
  Future<JellyfinQueryResult<JellyfinItem>> fromMusicGenreById({
    required String genreId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/MusicGenres/InstantMix',
          extra: {'id': genreId},
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/Artists/InstantMix?name={name}` — alternative name-keyed
  /// entry point for the artist mix (`GetInstantMixFromArtists2`).
  Future<JellyfinQueryResult<JellyfinItem>> fromArtistByName({
    required String name,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/Artists/InstantMix',
          extra: {'name': name},
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  /// `/Playlists/{playlistId}/InstantMix` — seeded by a playlist.
  Future<JellyfinQueryResult<JellyfinItem>> fromPlaylist({
    required String playlistId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request('/Playlists/$playlistId/InstantMix',
          limit: limit,
          fields: fields,
          enableImages: enableImages,
          enableUserData: enableUserData,
          imageTypeLimit: imageTypeLimit);

  // ─── Internal helper ──────────────────────────────────────────────

  Future<JellyfinQueryResult<JellyfinItem>> _request(
    String path, {
    Map<String, dynamic> extra = const {},
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) async {
    final qp = <String, dynamic>{
      'userId': _http.userId,
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      ...extra,
    };
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;

    final res = await _http.request<Map<String, dynamic>>(
      path,
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }
}
