// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_server_models.dart';
import '../jellyfin_vocabulary.dart';

/// `/UserViews` and library-level helpers.
class JellyfinLibraryApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinLibraryApi(this._http);

  /// The libraries visible to the current user.
  Future<List<JellyfinView>> userViews() async {
    final userId = _http.requireUserId();
    final res = await _http.request<Map<String, Object?>>(
      '/UserViews',
      queryParameters: {'userId': userId},
    );
    final result = JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinView.fromJson,
    );
    return result.items;
  }

  /// Trigger a library-wide refresh scan (admin only).
  Future<void> refresh() async {
    await _http.request<void>('/Library/Refresh', method: 'POST');
  }

  // ---------------------------------------------------------------------------
  // Item-level reads
  // ---------------------------------------------------------------------------

  /// `GET /Items/{itemId}/Similar` — generic "items similar to this".
  /// Works on any item kind. For type-specific variants see
  /// [similarAlbums], [similarArtists], [similarMovies],
  /// [similarShows], [similarTrailers].
  Future<JellyfinQueryResult<JellyfinItem>> similarItems({
    required String itemId,
    List<String> excludeArtistIds = const [],
    int? limit,
    List<JellyfinItemField> fields = const [],
    String? userId,
  }) =>
      _similar(
        '/Items/$itemId/Similar',
        excludeArtistIds: excludeArtistIds,
        limit: limit,
        fields: fields,
        userId: userId,
      );

  /// `GET /Albums/{itemId}/Similar` — albums the server considers related.
  Future<JellyfinQueryResult<JellyfinItem>> similarAlbums({
    required String itemId,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) =>
      _similar('/Albums/$itemId/Similar', limit: limit, fields: fields);

  /// `GET /Artists/{itemId}/Similar` — related artists.
  Future<JellyfinQueryResult<JellyfinItem>> similarArtists({
    required String itemId,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) =>
      _similar('/Artists/$itemId/Similar', limit: limit, fields: fields);

  /// `GET /Movies/{itemId}/Similar` — related movies.
  Future<JellyfinQueryResult<JellyfinItem>> similarMovies({
    required String itemId,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) =>
      _similar('/Movies/$itemId/Similar', limit: limit, fields: fields);

  /// `GET /Shows/{itemId}/Similar` — related TV series.
  Future<JellyfinQueryResult<JellyfinItem>> similarShows({
    required String itemId,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) =>
      _similar('/Shows/$itemId/Similar', limit: limit, fields: fields);

  /// `GET /Trailers/{itemId}/Similar` — related trailers.
  Future<JellyfinQueryResult<JellyfinItem>> similarTrailers({
    required String itemId,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) =>
      _similar('/Trailers/$itemId/Similar', limit: limit, fields: fields);

  /// `GET /Items/{itemId}/Ancestors` — every parent above this item,
  /// from grandparent up to the root library.
  Future<List<JellyfinItem>> ancestors({required String itemId}) async {
    final qp = <String, Object?>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    return _http.requestJson(
      '/Items/$itemId/Ancestors',
      queryParameters: qp.isEmpty ? null : qp,
      listOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Items/{itemId}/Collections` — every collection (box set)
  /// that includes this item. Powers an "Included in" section on an
  /// item page. Added in Jellyfin 12.0.
  ///
  /// [fields] takes `ItemFields` values to attach to each collection;
  /// [startIndex] and [limit] page the result. The current user id is
  /// sent automatically so the collections carry user data.
  Future<JellyfinQueryResult<JellyfinItem>> collections({
    required String itemId,
    int? startIndex,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) async {
    final qp = <String, Object?>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields;
    return _http.requestJson(
      '/Items/$itemId/Collections',
      queryParameters: qp.isEmpty ? null : qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Items/{itemId}/ThemeMedia` — title-screen theme media
  /// (songs and videos) plus inherited ones, returned together.
  Future<Map<String, Object?>> themeMedia({
    required String itemId,
    bool inheritFromParent = false,
  }) async {
    final qp = <String, Object?>{'inheritFromParent': inheritFromParent};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    final res = await _http.request<Map<String, Object?>>(
      '/Items/$itemId/ThemeMedia',
      queryParameters: qp,
    );
    return res.data ?? const {};
  }

  /// `GET /Items/{itemId}/ThemeSongs` — theme songs only.
  Future<JellyfinQueryResult<JellyfinItem>> themeSongs({
    required String itemId,
    bool inheritFromParent = false,
  }) =>
      _themeBucket('/Items/$itemId/ThemeSongs', inheritFromParent);

  /// `GET /Items/{itemId}/ThemeVideos` — theme videos only.
  Future<JellyfinQueryResult<JellyfinItem>> themeVideos({
    required String itemId,
    bool inheritFromParent = false,
  }) =>
      _themeBucket('/Items/$itemId/ThemeVideos', inheritFromParent);

  // ---------------------------------------------------------------------------
  // Library-level reads / writes
  // ---------------------------------------------------------------------------

  /// `GET /Items/Counts` — quick tally of items across all libraries.
  Future<JellyfinItemCounts> counts({
    String? userId,
    bool? isFavorite,
  }) {
    final qp = <String, Object?>{};
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    return _http.requestJson(
      '/Items/Counts',
      queryParameters: qp.isEmpty ? null : qp,
      (json) => JellyfinItemCounts.fromJson(
        json is Map<String, Object?> ? json : const <String, Object?>{},
      ),
    );
  }

  /// `GET /Library/MediaFolders` — every media folder configured on
  /// the server (admin's source-of-truth list, broader than user
  /// views).
  Future<JellyfinQueryResult<JellyfinItem>> mediaFolders({
    bool? isHidden,
  }) async {
    final qp = <String, Object?>{};
    if (isHidden != null) qp['isHidden'] = isHidden;
    return _http.requestJson(
      '/Library/MediaFolders',
      queryParameters: qp.isEmpty ? null : qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Library/PhysicalPaths` — every physical path the server
  /// scans. Admin-only.
  Future<List<String>> physicalPaths() async {
    final res = await _http.request<List<Object?>>('/Library/PhysicalPaths');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is String) e,
    ];
  }

  /// `GET /Libraries/AvailableOptions` — server-side library options
  /// catalog (typed sources, metadata fetchers, …). Used by admin UIs
  /// when configuring a virtual folder.
  Future<Map<String, Object?>> availableOptions({
    String? libraryContentType,
  }) async {
    final qp = <String, Object?>{};
    if (libraryContentType != null) {
      qp['libraryContentType'] = libraryContentType;
    }
    final res = await _http.request<Map<String, Object?>>(
      '/Libraries/AvailableOptions',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  /// `POST /Library/Media/Updated` — notify the server that one or
  /// more media files have changed on disk. Admin-only.
  Future<void> notifyMediaUpdated(
    List<Map<String, Object?>> updatesInfo,
  ) async {
    await _http.request<void>(
      '/Library/Media/Updated',
      method: 'POST',
      data: {'Updates': updatesInfo},
    );
  }

  /// `POST /Library/Movies/Added` — notify the server that a movie was
  /// added, identified by its optional `tmdbId`/`imdbId`. The endpoint
  /// takes only query parameters and no body. Admin-only.
  Future<void> notifyMoviesAdded({String? tmdbId, String? imdbId}) =>
      _notifyExternal(
        '/Library/Movies/Added',
        tmdbId: tmdbId,
        imdbId: imdbId,
      );

  /// `POST /Library/Movies/Updated` — counterpart of [notifyMoviesAdded].
  Future<void> notifyMoviesUpdated({String? tmdbId, String? imdbId}) =>
      _notifyExternal(
        '/Library/Movies/Updated',
        tmdbId: tmdbId,
        imdbId: imdbId,
      );

  /// `POST /Library/Series/Added` — notify the server that a series was
  /// added, identified by its optional `tvdbId`. The endpoint takes only
  /// query parameters and no body. Admin-only.
  Future<void> notifySeriesAdded({String? tvdbId}) =>
      _notifyExternal('/Library/Series/Added', tvdbId: tvdbId);

  /// `POST /Library/Series/Updated` — counterpart of [notifySeriesAdded].
  Future<void> notifySeriesUpdated({String? tvdbId}) =>
      _notifyExternal('/Library/Series/Updated', tvdbId: tvdbId);

  // ---------------------------------------------------------------------------
  // Item lifecycle
  // ---------------------------------------------------------------------------

  /// `DELETE /Items/{itemId}` — remove an item (and any files on
  /// disk if the user's policy allows). Admin or owner.
  Future<void> deleteItem({
    required String itemId,
  }) async {
    await _http.request<void>(
      '/Items/$itemId',
      method: 'DELETE',
    );
  }

  /// `DELETE /Items?ids=...` — bulk delete.
  Future<void> deleteItems({
    required List<String> ids,
  }) async {
    await _http.request<void>(
      '/Items',
      method: 'DELETE',
      queryParameters: {'ids': ids},
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<JellyfinQueryResult<JellyfinItem>> _similar(
    String path, {
    List<String> excludeArtistIds = const [],
    int? limit,
    List<JellyfinItemField> fields = const [],
    String? userId,
  }) async {
    final qp = <String, Object?>{};
    final uid = userId ?? _http.userId;
    if (uid != null) qp['userId'] = uid;
    if (excludeArtistIds.isNotEmpty) {
      qp['excludeArtistIds'] = excludeArtistIds;
    }
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields;
    return _http.requestJson(
      path,
      queryParameters: qp.isEmpty ? null : qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  Future<JellyfinQueryResult<JellyfinItem>> _themeBucket(
    String path,
    bool inheritFromParent,
  ) async {
    final qp = <String, Object?>{'inheritFromParent': inheritFromParent};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    return _http.requestJson(
      path,
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  Future<void> _notifyExternal(
    String path, {
    String? tmdbId,
    String? imdbId,
    String? tvdbId,
  }) async {
    final qp = <String, Object?>{};
    if (tmdbId != null) qp['tmdbId'] = tmdbId;
    if (imdbId != null) qp['imdbId'] = imdbId;
    if (tvdbId != null) qp['tvdbId'] = tvdbId;
    await _http.request<void>(
      path,
      method: 'POST',
      queryParameters: qp.isEmpty ? null : qp,
    );
  }
}
