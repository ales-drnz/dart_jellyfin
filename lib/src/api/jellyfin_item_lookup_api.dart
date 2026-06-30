// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Items/RemoteSearch/*` and `/Items/{id}/ExternalIdInfos` —
/// metadata-provider lookup.
///
/// Wraps the `ItemLookup` OpenAPI tag (11 operations). These power
/// the "Identify" UI in Jellyfin Web: given a partial title (and
/// optional year, IMDB/TMDB id, …), ask configured metadata
/// providers for candidate matches, then apply one to the item.
///
/// The search bodies are passed through as raw maps — the upstream
/// shape varies per item kind (`{SearchInfo: {Name, Year, …},
/// ItemId, IncludeDisabledProviders}`) and is documented at
/// <https://api.jellyfin.org>.
class JellyfinItemLookupApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinItemLookupApi(this._http);

  /// `GET /Items/{itemId}/ExternalIdInfos` — providers that can
  /// supply external ids for this item kind (IMDB, TMDB, MusicBrainz,
  /// …). Each entry is a raw map describing one provider.
  Future<List<Map<String, dynamic>>> externalIdInfos(String itemId) async {
    final res = await _http.request<List<dynamic>>(
      '/Items/$itemId/ExternalIdInfos',
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `POST /Items/RemoteSearch/Apply/{itemId}` — write the selected
  /// remote search result back onto the item (downloads images,
  /// updates external ids, replaces metadata).
  ///
  /// [body] is the chosen `RemoteSearchResult` map (one of the
  /// entries from a `searchXxx()` call), wrapped per upstream
  /// expectation: `{... search result fields ..., ReplaceAllImages,
  /// ApplyTo, ...}`.
  Future<void> applySearchResult({
    required String itemId,
    required Map<String, dynamic> body,
    bool replaceAllImages = true,
  }) async {
    await _http.request<void>(
      '/Items/RemoteSearch/Apply/$itemId',
      method: 'POST',
      queryParameters: {'replaceAllImages': replaceAllImages},
      data: body,
    );
  }

  /// `POST /Items/RemoteSearch/Movie` — metadata search for a movie
  /// item. [body] is the upstream `MovieInfoRemoteSearchQuery`.
  Future<List<Map<String, dynamic>>> searchMovies(Map<String, dynamic> body) =>
      _search('/Items/RemoteSearch/Movie', body);

  /// `POST /Items/RemoteSearch/Series`.
  Future<List<Map<String, dynamic>>> searchSeries(Map<String, dynamic> body) =>
      _search('/Items/RemoteSearch/Series', body);

  /// `POST /Items/RemoteSearch/Trailer`.
  Future<List<Map<String, dynamic>>> searchTrailers(
    Map<String, dynamic> body,
  ) =>
      _search('/Items/RemoteSearch/Trailer', body);

  /// `POST /Items/RemoteSearch/MusicAlbum`.
  Future<List<Map<String, dynamic>>> searchMusicAlbums(
    Map<String, dynamic> body,
  ) =>
      _search('/Items/RemoteSearch/MusicAlbum', body);

  /// `POST /Items/RemoteSearch/MusicArtist`.
  Future<List<Map<String, dynamic>>> searchMusicArtists(
    Map<String, dynamic> body,
  ) =>
      _search('/Items/RemoteSearch/MusicArtist', body);

  /// `POST /Items/RemoteSearch/MusicVideo`.
  Future<List<Map<String, dynamic>>> searchMusicVideos(
    Map<String, dynamic> body,
  ) =>
      _search('/Items/RemoteSearch/MusicVideo', body);

  /// `POST /Items/RemoteSearch/Person`.
  Future<List<Map<String, dynamic>>> searchPersons(Map<String, dynamic> body) =>
      _search('/Items/RemoteSearch/Person', body);

  /// `POST /Items/RemoteSearch/Book`.
  Future<List<Map<String, dynamic>>> searchBooks(Map<String, dynamic> body) =>
      _search('/Items/RemoteSearch/Book', body);

  /// `POST /Items/RemoteSearch/BoxSet`.
  Future<List<Map<String, dynamic>>> searchBoxSets(Map<String, dynamic> body) =>
      _search('/Items/RemoteSearch/BoxSet', body);

  Future<List<Map<String, dynamic>>> _search(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _http.request<List<dynamic>>(
      path,
      method: 'POST',
      data: body,
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
