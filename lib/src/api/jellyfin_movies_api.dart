// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';

/// `/Movies/*` — movie-specific browsing.
///
/// Wraps the `Movies` OpenAPI tag (1 operation). The endpoint returns
/// a list of recommendation "rows", each with a category label and
/// the [JellyfinItem]s belonging to it (e.g. "Because you watched X",
/// "Top picks", "Directed by Y").
///
/// {@category TV, movies and live TV}
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
    List<JellyfinItemField> fields = const [],
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'parentId': ?parentId,
      'categoryLimit': ?categoryLimit,
      'itemLimit': ?itemLimit,
      if (fields.isNotEmpty) 'fields': fields,
    };

    return _http.requestJson(
      '/Movies/Recommendations',
      queryParameters: qp,
      listOf(JellyfinMovieRecommendation.fromJson),
    );
  }
}
