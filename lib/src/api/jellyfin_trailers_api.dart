// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/Trailers` — server-curated trailer browsing.
///
/// Wraps the `Trailers` OpenAPI tag (1 operation). Jellyfin 12 marks
/// `GET /Trailers` obsolete: it is a thin alias of `GET /Items` with
/// `includeItemTypes=Trailer`, so
/// `items.list(includeItemTypes: ['Trailer'])` takes the same filters
/// and is the supported path.
class JellyfinTrailersApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinTrailersApi(this._http);

  /// `GET /Trailers` — list trailers visible to the current user.
  ///
  /// Obsolete in Jellyfin 12; still served through the 12.x cycle.
  @Deprecated(
    "Obsolete in Jellyfin 12; use items.list(includeItemTypes: ['Trailer']).",
  )
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
      qp['sortBy'] = sortBy;
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (fields.isNotEmpty) qp['fields'] = fields;
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes;
    }
    if (filters.isNotEmpty) qp['filters'] = filters;
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (genreIds.isNotEmpty) qp['genreIds'] = genreIds;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }

    return _http.requestJson(
      '/Trailers',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }
}
