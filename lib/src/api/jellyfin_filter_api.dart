// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Items/Filters*` — dynamic facet endpoints.
///
/// Wraps the `Filter` OpenAPI tag (2 operations). Used to drive
/// dynamic filter chips: pick a library, ask the server which genres,
/// tags, ratings, years are present, then feed the user's choice back
/// into [JellyfinItemsApi.list] via `genreIds`, `tags`, `years`.
class JellyfinFilterApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinFilterApi(this._http);

  /// `/Items/Filters2` — modern facet payload (genres are
  /// [JellyfinNameGuidPair] with ids).
  Future<JellyfinQueryFilters> facets({
    String? parentId,
    List<String> includeItemTypes = const [],
    bool? isAiring,
    bool? isMovie,
    bool? isSports,
    bool? isKids,
    bool? isNews,
    bool? isSeries,
    bool recursive = true,
  }) async {
    final qp = <String, dynamic>{'recursive': recursive};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (isAiring != null) qp['isAiring'] = isAiring;
    if (isMovie != null) qp['isMovie'] = isMovie;
    if (isSports != null) qp['isSports'] = isSports;
    if (isKids != null) qp['isKids'] = isKids;
    if (isNews != null) qp['isNews'] = isNews;
    if (isSeries != null) qp['isSeries'] = isSeries;

    final res = await _http.request<Map<String, dynamic>>(
      '/Items/Filters2',
      queryParameters: qp,
    );
    return JellyfinQueryFilters.fromJson(res.data ?? const {});
  }

  /// `/Items/Filters` — legacy facet payload (flat string arrays plus
  /// years and official ratings).
  Future<JellyfinQueryFiltersLegacy> legacy({
    String? parentId,
    List<String> includeItemTypes = const [],
    List<String> mediaTypes = const [],
  }) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes.join(',');

    final res = await _http.request<Map<String, dynamic>>(
      '/Items/Filters',
      queryParameters: qp,
    );
    return JellyfinQueryFiltersLegacy.fromJson(res.data ?? const {});
  }
}
