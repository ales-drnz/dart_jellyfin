// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/UserViews` and library-level helpers.
class JellyfinLibraryApi {
  final JellyfinConnection _http;

  JellyfinLibraryApi(this._http);

  /// The libraries visible to the current user.
  Future<List<JellyfinView>> userViews() async {
    final userId = _requireUser();
    final res = await _http.request<Map<String, dynamic>>(
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
    String? excludeArtistIds,
    int? limit,
    List<String> fields = const [],
    String? userId,
  }) =>
      _similar('/Items/$itemId/Similar',
          excludeArtistIds: excludeArtistIds,
          limit: limit,
          fields: fields,
          userId: userId);

  Future<JellyfinQueryResult<JellyfinItem>> similarAlbums({
    required String itemId,
    int? limit,
    List<String> fields = const [],
  }) =>
      _similar('/Albums/$itemId/Similar', limit: limit, fields: fields);

  Future<JellyfinQueryResult<JellyfinItem>> similarArtists({
    required String itemId,
    int? limit,
    List<String> fields = const [],
  }) =>
      _similar('/Artists/$itemId/Similar', limit: limit, fields: fields);

  Future<JellyfinQueryResult<JellyfinItem>> similarMovies({
    required String itemId,
    int? limit,
    List<String> fields = const [],
  }) =>
      _similar('/Movies/$itemId/Similar', limit: limit, fields: fields);

  Future<JellyfinQueryResult<JellyfinItem>> similarShows({
    required String itemId,
    int? limit,
    List<String> fields = const [],
  }) =>
      _similar('/Shows/$itemId/Similar', limit: limit, fields: fields);

  Future<JellyfinQueryResult<JellyfinItem>> similarTrailers({
    required String itemId,
    int? limit,
    List<String> fields = const [],
  }) =>
      _similar('/Trailers/$itemId/Similar', limit: limit, fields: fields);

  /// `GET /Items/{itemId}/Ancestors` — every parent above this item,
  /// from grandparent up to the root library.
  Future<List<JellyfinItem>> ancestors({required String itemId}) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    final res = await _http.request<List<dynamic>>(
      '/Items/$itemId/Ancestors',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinItem.fromJson(e),
    ];
  }

  /// `GET /Items/{itemId}/CriticReviews` — list of critic reviews
  /// returned as raw maps (the upstream `BaseItemDto` envelope is
  /// review-shaped, not item-shaped).
  Future<List<Map<String, dynamic>>> criticReviews({required String itemId}) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Items/$itemId/CriticReviews',
    );
    final raw = res.data?['Items'];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `GET /Items/{itemId}/ThemeMedia` — title-screen theme media
  /// (songs and videos) plus inherited ones, returned together.
  Future<Map<String, dynamic>> themeMedia({
    required String itemId,
    bool inheritFromParent = false,
  }) async {
    final qp = <String, dynamic>{'inheritFromParent': inheritFromParent};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    final res = await _http.request<Map<String, dynamic>>(
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
  Future<Map<String, dynamic>> counts({
    String? userId,
    bool? isFavorite,
  }) async {
    final qp = <String, dynamic>{};
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    final res = await _http.request<Map<String, dynamic>>(
      '/Items/Counts',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  /// `GET /Library/MediaFolders` — every media folder configured on
  /// the server (admin's source-of-truth list, broader than user
  /// views).
  Future<JellyfinQueryResult<JellyfinItem>> mediaFolders({
    bool? isHidden,
  }) async {
    final qp = <String, dynamic>{};
    if (isHidden != null) qp['isHidden'] = isHidden;
    final res = await _http.request<Map<String, dynamic>>(
      '/Library/MediaFolders',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Library/PhysicalPaths` — every physical path the server
  /// scans. Admin-only.
  Future<List<String>> physicalPaths() async {
    final res = await _http.request<List<dynamic>>('/Library/PhysicalPaths');
    final list = res.data ?? const [];
    return [for (final e in list) if (e is String) e];
  }

  /// `GET /Libraries/AvailableOptions` — server-side library options
  /// catalog (typed sources, metadata fetchers, …). Used by admin UIs
  /// when configuring a virtual folder.
  Future<Map<String, dynamic>> availableOptions({String? libraryContentType}) async {
    final qp = <String, dynamic>{};
    if (libraryContentType != null) {
      qp['libraryContentType'] = libraryContentType;
    }
    final res = await _http.request<Map<String, dynamic>>(
      '/Libraries/AvailableOptions',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  /// `POST /Library/Media/Updated` — notify the server that one or
  /// more media files have changed on disk. Admin-only.
  Future<void> notifyMediaUpdated(List<Map<String, dynamic>> updatesInfo) async {
    await _http.request<void>(
      '/Library/Media/Updated',
      method: 'POST',
      data: {'Updates': updatesInfo},
    );
  }

  /// `POST /Library/Movies/Added` and `/Updated` — notify the server
  /// of movie file events. Admin-only.
  Future<void> notifyMoviesAdded(List<Map<String, dynamic>> updatesInfo) =>
      _notify('/Library/Movies/Added', updatesInfo);
  Future<void> notifyMoviesUpdated(List<Map<String, dynamic>> updatesInfo) =>
      _notify('/Library/Movies/Updated', updatesInfo);

  /// `POST /Library/Series/Added` and `/Updated` — notify the server
  /// of series file events. Admin-only.
  Future<void> notifySeriesAdded(List<Map<String, dynamic>> updatesInfo) =>
      _notify('/Library/Series/Added', updatesInfo);
  Future<void> notifySeriesUpdated(List<Map<String, dynamic>> updatesInfo) =>
      _notify('/Library/Series/Updated', updatesInfo);

  // ---------------------------------------------------------------------------
  // Item lifecycle
  // ---------------------------------------------------------------------------

  /// `DELETE /Items/{itemId}` — remove an item (and any files on
  /// disk if the user's policy allows). Admin or owner.
  Future<void> deleteItem(String itemId) async {
    await _http.request<void>(
      '/Items/$itemId',
      method: 'DELETE',
    );
  }

  /// `DELETE /Items?ids=...` — bulk delete.
  Future<void> deleteItems(List<String> ids) async {
    await _http.request<void>(
      '/Items',
      method: 'DELETE',
      queryParameters: {'ids': ids.join(',')},
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<JellyfinQueryResult<JellyfinItem>> _similar(
    String path, {
    String? excludeArtistIds,
    int? limit,
    List<String> fields = const [],
    String? userId,
  }) async {
    final qp = <String, dynamic>{};
    final uid = userId ?? _http.userId;
    if (uid != null) qp['userId'] = uid;
    if (excludeArtistIds != null) qp['excludeArtistIds'] = excludeArtistIds;
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    final res = await _http.request<Map<String, dynamic>>(
      path,
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  Future<JellyfinQueryResult<JellyfinItem>> _themeBucket(
      String path, bool inheritFromParent) async {
    final qp = <String, dynamic>{'inheritFromParent': inheritFromParent};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    final res = await _http.request<Map<String, dynamic>>(
      path,
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  Future<void> _notify(String path, List<Map<String, dynamic>> updates) async {
    await _http.request<void>(
      path,
      method: 'POST',
      data: {'Updates': updates},
    );
  }

  String _requireUser() {
    final id = _http.userId;
    if (id == null) {
      throw const JellyfinException(
        'No user. Call JellyfinClient.setSession() with a userId first.',
        type: JellyfinErrorType.state,
      );
    }
    return id;
  }
}
