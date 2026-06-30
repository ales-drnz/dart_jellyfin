// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Trailers` — server-curated trailer browsing.
///
/// Wraps the `Trailers` OpenAPI tag (1 operation). The endpoint
/// accepts the same broad set of filters as [JellyfinItemsApi.list]
/// (search term, parent id, sort, paging) but is scoped server-side
/// to trailer-typed items, so it's cheaper than a `Items.list(...)`
/// with a manual type filter.
class JellyfinTrailersApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinTrailersApi(this._http);

  /// `GET /Trailers` — list trailers visible to the current user.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<String> sortBy = const [],
    bool descending = false,
    List<String> fields = const [],
    List<String> excludeItemTypes = const [],
    List<String> filters = const [],
    bool? isFavorite,
    List<String> genreIds = const [],
    bool enableUserData = true,
    bool enableImages = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool recursive = true,
  }) async {
    final qp = <String, dynamic>{
      'startIndex': startIndex,
      'recursive': recursive,
      'enableImages': enableImages,
      'enableUserData': enableUserData,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (limit != null) qp['limit'] = limit;
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy.join(',');
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes.join(',');
    }
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (genreIds.isNotEmpty) qp['genreIds'] = genreIds.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

    final res = await _http.request<Map<String, dynamic>>(
      '/Trailers',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }
}
