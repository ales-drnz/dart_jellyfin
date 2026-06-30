// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Artists*` — artist-aware browsing.
///
/// Wraps the `Artists` OpenAPI tag (3 operations). Where
/// [JellyfinItemsApi.list] queries items generically, this sub-API
/// targets the artist endpoints, which respect the server's
/// canonical artist deduplication (an artist appears once even if
/// they're credited on many tracks).
class JellyfinArtistsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinArtistsApi(this._http);

  /// `/Artists` — every artist (album artists, featured artists,
  /// composers, etc.).
  ///
  /// [sortBy] takes one or more `ItemSortBy` values (e.g. `SortName`,
  /// `DateCreated`); [descending] flips the sort order to `Descending`.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    double? minCommunityRating,
    List<String> sortBy = const [],
    bool descending = false,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> filters = const [],
    bool? isFavorite,
    List<String> mediaTypes = const [],
    List<String> genres = const [],
    List<String> genreIds = const [],
    List<String> officialRatings = const [],
    List<String> tags = const [],
    List<int> years = const [],
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) =>
      _browse(
        '/Artists',
        parentId: parentId,
        searchTerm: searchTerm,
        startIndex: startIndex,
        limit: limit,
        minCommunityRating: minCommunityRating,
        sortBy: sortBy,
        descending: descending,
        fields: fields,
        includeItemTypes: includeItemTypes,
        excludeItemTypes: excludeItemTypes,
        filters: filters,
        isFavorite: isFavorite,
        mediaTypes: mediaTypes,
        genres: genres,
        genreIds: genreIds,
        officialRatings: officialRatings,
        tags: tags,
        years: years,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
        enableImageTypes: enableImageTypes,
      );

  /// `/Artists/AlbumArtists` — only artists with at least one album
  /// credited. The right call for an "Artists" library tab in a music
  /// UI.
  ///
  /// [sortBy] takes one or more `ItemSortBy` values (e.g. `SortName`,
  /// `DateCreated`); [descending] flips the sort order to `Descending`.
  Future<JellyfinQueryResult<JellyfinItem>> albumArtists({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    double? minCommunityRating,
    List<String> sortBy = const [],
    bool descending = false,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> filters = const [],
    bool? isFavorite,
    List<String> mediaTypes = const [],
    List<String> genres = const [],
    List<String> genreIds = const [],
    List<String> officialRatings = const [],
    List<String> tags = const [],
    List<int> years = const [],
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) =>
      _browse(
        '/Artists/AlbumArtists',
        parentId: parentId,
        searchTerm: searchTerm,
        startIndex: startIndex,
        limit: limit,
        minCommunityRating: minCommunityRating,
        sortBy: sortBy,
        descending: descending,
        fields: fields,
        includeItemTypes: includeItemTypes,
        excludeItemTypes: excludeItemTypes,
        filters: filters,
        isFavorite: isFavorite,
        mediaTypes: mediaTypes,
        genres: genres,
        genreIds: genreIds,
        officialRatings: officialRatings,
        tags: tags,
        years: years,
        enableUserData: enableUserData,
        imageTypeLimit: imageTypeLimit,
        enableImageTypes: enableImageTypes,
      );

  /// `/Artists/{name}` — lookup by exact artist name. Returns null on
  /// 404 (no artist matches the name).
  Future<JellyfinItem?> byName(String name) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    try {
      final res = await _http.request<Map<String, dynamic>>(
        '/Artists/${Uri.encodeComponent(name)}',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final data = res.data;
      if (data == null) return null;
      return JellyfinItem.fromJson(data);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
  }

  Future<JellyfinQueryResult<JellyfinItem>> _browse(
    String path, {
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    double? minCommunityRating,
    List<String> sortBy = const [],
    bool descending = false,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> filters = const [],
    bool? isFavorite,
    List<String> mediaTypes = const [],
    List<String> genres = const [],
    List<String> genreIds = const [],
    List<String> officialRatings = const [],
    List<String> tags = const [],
    List<int> years = const [],
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, dynamic>{
      'startIndex': startIndex,
      'enableUserData': enableUserData,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (limit != null) qp['limit'] = limit;
    if (minCommunityRating != null) {
      qp['minCommunityRating'] = minCommunityRating;
    }
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy.join(',');
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes.join(',');
    }
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes.join(',');
    if (genres.isNotEmpty) qp['genres'] = genres.join('|');
    if (genreIds.isNotEmpty) qp['genreIds'] = genreIds.join('|');
    if (officialRatings.isNotEmpty) {
      qp['officialRatings'] = officialRatings.join('|');
    }
    if (tags.isNotEmpty) qp['tags'] = tags.join('|');
    if (years.isNotEmpty) qp['years'] = years.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

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
