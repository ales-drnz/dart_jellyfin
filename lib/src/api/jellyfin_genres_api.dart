// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import 'jellyfin_lookup_helpers.dart';

/// `/Genres*` — generic genres across the library.
///
/// Wraps the `Genres` OpenAPI tag (2 operations). For music-specific
/// genres see [JellyfinMusicGenresApi].
class JellyfinGenresApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinGenresApi(this._http);

  /// `GET /Genres` — list genres, scoped to [parentId] and filtered
  /// by item kind.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    bool? isFavorite,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<String> sortBy = const [],
  }) =>
      _browse(
        '/Genres',
        parentId: parentId,
        searchTerm: searchTerm,
        startIndex: startIndex,
        limit: limit,
        fields: fields,
        includeItemTypes: includeItemTypes,
        excludeItemTypes: excludeItemTypes,
        isFavorite: isFavorite,
        imageTypeLimit: imageTypeLimit,
        enableImageTypes: enableImageTypes,
        nameStartsWith: nameStartsWith,
        nameStartsWithOrGreater: nameStartsWithOrGreater,
        nameLessThan: nameLessThan,
        sortBy: sortBy,
      );

  /// `GET /Genres/{genreName}` — lookup a genre by exact name.
  /// Returns null on 404.
  Future<JellyfinItem?> byName(String name) =>
      lookupItemByName('/Genres', name, _http);

  Future<JellyfinQueryResult<JellyfinItem>> _browse(
    String path, {
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    bool? isFavorite,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<String> sortBy = const [],
  }) async {
    final qp = <String, dynamic>{'startIndex': startIndex};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes.join(',');
    }
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }
    if (nameStartsWith != null) qp['nameStartsWith'] = nameStartsWith;
    if (nameStartsWithOrGreater != null) {
      qp['nameStartsWithOrGreater'] = nameStartsWithOrGreater;
    }
    if (nameLessThan != null) qp['nameLessThan'] = nameLessThan;
    if (sortBy.isNotEmpty) qp['sortBy'] = sortBy.join(',');

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
