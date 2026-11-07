// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_admin_models.dart';
import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_parsing.dart';

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
  /// …), with the `ProviderIds` key each one fills.
  Future<List<JellyfinExternalIdInfo>> externalIdInfos({
    required String itemId,
  }) => _http.requestJson(
    '/Items/$itemId/ExternalIdInfos',
    listOf(JellyfinExternalIdInfo.fromJson),
  );

  /// `POST /Items/RemoteSearch/Apply/{itemId}` — write the selected
  /// remote search result back onto the item (downloads images,
  /// updates external ids, replaces metadata).
  ///
  /// [body] is the chosen [JellyfinRemoteSearchResult.raw] (one of the
  /// entries from a `searchXxx()` call), wrapped per upstream
  /// expectation: `{... search result fields ..., ReplaceAllImages,
  /// ApplyTo, ...}`.
  Future<void> applySearchResult({
    required String itemId,
    required Map<String, Object?> body,
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
  Future<List<JellyfinRemoteSearchResult>> searchMovies(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/Movie', body);

  /// `POST /Items/RemoteSearch/Series`. [body] is the upstream
  /// `SeriesInfoRemoteSearchQuery`. Jellyfin 13.0 reads
  /// `SearchInfo.DisplayOrder`, the episode order group to match
  /// (`aired`, `dvd`, …); 12.x ignores it.
  Future<List<JellyfinRemoteSearchResult>> searchSeries(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/Series', body);

  /// `POST /Items/RemoteSearch/Trailer`.
  Future<List<JellyfinRemoteSearchResult>> searchTrailers(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/Trailer', body);

  /// `POST /Items/RemoteSearch/MusicAlbum`.
  Future<List<JellyfinRemoteSearchResult>> searchMusicAlbums(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/MusicAlbum', body);

  /// `POST /Items/RemoteSearch/MusicArtist`.
  Future<List<JellyfinRemoteSearchResult>> searchMusicArtists(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/MusicArtist', body);

  /// `POST /Items/RemoteSearch/MusicVideo`.
  Future<List<JellyfinRemoteSearchResult>> searchMusicVideos(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/MusicVideo', body);

  /// `POST /Items/RemoteSearch/Person`.
  Future<List<JellyfinRemoteSearchResult>> searchPersons(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/Person', body);

  /// `POST /Items/RemoteSearch/Book`.
  Future<List<JellyfinRemoteSearchResult>> searchBooks(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/Book', body);

  /// `POST /Items/RemoteSearch/BoxSet`.
  Future<List<JellyfinRemoteSearchResult>> searchBoxSets(
    Map<String, Object?> body,
  ) => _search('/Items/RemoteSearch/BoxSet', body);

  Future<List<JellyfinRemoteSearchResult>> _search(
    String path,
    Map<String, Object?> body,
  ) => _http.requestJson(
    path,
    method: 'POST',
    data: body,
    listOf(JellyfinRemoteSearchResult.fromJson),
  );
}
