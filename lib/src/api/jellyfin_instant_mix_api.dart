// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/{ItemType}/{id}/InstantMix` — server-side radio.
///
/// Jellyfin generates a "Mix" — a list of related audio items — from
/// any seed item (song, album, artist, playlist, genre). The mix
/// quality depends on the server's metadata + similar-artist
/// recommendations.
///
/// Maps the `InstantMix` OpenAPI tag. Each helper returns a
/// [JellyfinQueryResult] of [JellyfinItem] (same shape as
/// `items.list()`), so the result drops straight into a UI list.
///
/// Jellyfin 12 marks the music-genre and artist-by-name variants
/// obsolete: [fromItem] accepts any seed id (song, album, artist,
/// genre, playlist) and is the one to reach for.
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
      _request(
        '/Items/$itemId/InstantMix',
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/Songs/{songId}/InstantMix` — seeded by a song.
  Future<JellyfinQueryResult<JellyfinItem>> fromSong({
    required String songId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/Songs/$songId/InstantMix',
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/Albums/{albumId}/InstantMix`.
  Future<JellyfinQueryResult<JellyfinItem>> fromAlbum({
    required String albumId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/Albums/$albumId/InstantMix',
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/Artists/{artistId}/InstantMix` (modern variant — uses item id).
  Future<JellyfinQueryResult<JellyfinItem>> fromArtist({
    required String artistId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/Artists/$artistId/InstantMix',
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/MusicGenres/{name}/InstantMix` (by name).
  ///
  /// Obsolete in Jellyfin 12: resolve the genre with
  /// `genres.byName()` and pass its id to [fromItem].
  @Deprecated(
    'Obsolete in Jellyfin 12; resolve the genre id with genres.byName() '
    'and call fromItem() instead.',
  )
  Future<JellyfinQueryResult<JellyfinItem>> fromMusicGenre({
    required String name,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/MusicGenres/${Uri.encodeComponent(name)}/InstantMix',
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/MusicGenres/InstantMix?id={genreId}` (by id).
  ///
  /// Obsolete in Jellyfin 12: [fromItem] takes the same genre id.
  @Deprecated('Obsolete in Jellyfin 12; call fromItem(itemId: genreId).')
  Future<JellyfinQueryResult<JellyfinItem>> fromMusicGenreById({
    required String genreId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/MusicGenres/InstantMix',
        extra: {'id': genreId},
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/Artists/InstantMix?name={name}` — alternative name-keyed
  /// entry point for the artist mix (`GetInstantMixFromArtists2`).
  ///
  /// Hidden from the Jellyfin 12 OpenAPI document and may be removed
  /// without notice. Resolve the artist with `artists.byName()` and
  /// pass its id to [fromArtist] or [fromItem].
  @Deprecated(
    'Hidden from the Jellyfin 12 API; resolve the artist id and call '
    'fromArtist() or fromItem() instead.',
  )
  Future<JellyfinQueryResult<JellyfinItem>> fromArtistByName({
    required String name,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/Artists/InstantMix',
        extra: {'name': name},
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  /// `/Playlists/{playlistId}/InstantMix` — seeded by a playlist.
  Future<JellyfinQueryResult<JellyfinItem>> fromPlaylist({
    required String playlistId,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) =>
      _request(
        '/Playlists/$playlistId/InstantMix',
        limit: limit,
        fields: fields,
        enableImages: enableImages,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
      );

  // ─── Internal helper ──────────────────────────────────────────────

  Future<JellyfinQueryResult<JellyfinItem>> _request(
    String path, {
    Map<String, Object?> extra = const {},
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) async {
    final qp = <String, Object?>{
      'userId': _http.userId,
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      ...extra,
    };
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;

    return _http.requestJson(
      path,
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }
}
