// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Movies/*` — movie-specific browsing.
///
/// Wraps the `Movies` OpenAPI tag (1 operation). The endpoint returns
/// a list of recommendation "rows", each with a category label and
/// the [JellyfinItem]s belonging to it (e.g. "Because you watched X",
/// "Top picks", "Directed by Y").
class JellyfinMoviesApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinMoviesApi(this._http);

  /// `/Movies/Recommendations` — server-curated rows of movie picks.
  ///
  /// [categoryLimit] caps the number of rows; [itemLimit] caps the
  /// movies per row.
  Future<List<JellyfinMovieRecommendation>> recommendations({
    String? parentId,
    int? categoryLimit,
    int? itemLimit,
    List<String> fields = const [],
  }) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (categoryLimit != null) qp['categoryLimit'] = categoryLimit;
    if (itemLimit != null) qp['itemLimit'] = itemLimit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');

    final res = await _http.request<List<dynamic>>(
      '/Movies/Recommendations',
      queryParameters: qp,
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinMovieRecommendation.fromJson(e),
    ];
  }
}
