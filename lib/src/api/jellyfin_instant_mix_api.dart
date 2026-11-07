// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';

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
/// [fromItem] accepts any seed id (song, album, artist, music genre,
/// playlist) and is the one to reach for. Jellyfin 12 made the
/// music-genre routes obsolete; 0.4.0 removed them.
///
/// {@category Search and lyrics}
class JellyfinInstantMixApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinInstantMixApi(this._http);

  /// `/Items/{itemId}/InstantMix` — works on any item kind the server
  /// understands as a seed (song, album, artist, mixed item id).
  ///
  /// A genre seeds a mix by its `MusicGenre` id — from a track's
  /// `genreItems`, `genres.list(parentId: musicLibraryId)` or
  /// `genres.musicGenre()`. The generic `Genre` id that
  /// `genres.byName()` and an unscoped `genres.list()` answer gets 200
  /// with an empty mix (12.4).
  ///
  /// An artist seeds a mix by its `MusicArtist` id — from a track's
  /// `artistItems` or `albumArtistItems`, or `items.list(includeItemTypes:
  /// [JellyfinItemKind.musicArtist])`. The `Person` id that
  /// `artists.list()` answers gets an empty mix (12.4).
  Future<JellyfinQueryResult<JellyfinItem>> fromItem({
    required String itemId,
    int? limit,
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) => _request(
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
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) => _request(
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
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) => _request(
    '/Albums/$albumId/InstantMix',
    limit: limit,
    fields: fields,
    enableImages: enableImages,
    enableUserData: enableUserData,
    imageTypeLimit: imageTypeLimit,
  );

  /// `/Artists/{artistId}/InstantMix` — seeded by an artist.
  ///
  /// [artistId] is a `MusicArtist` id: a track's `artistItems` or
  /// `albumArtistItems`, or `items.list(includeItemTypes:
  /// [JellyfinItemKind.musicArtist])`. The `Person` id that
  /// `artists.list()` answers gets an empty mix (12.4).
  Future<JellyfinQueryResult<JellyfinItem>> fromArtist({
    required String artistId,
    int? limit,
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) => _request(
    '/Artists/$artistId/InstantMix',
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
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) => _request(
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
    List<JellyfinItemField> fields = const [],
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
