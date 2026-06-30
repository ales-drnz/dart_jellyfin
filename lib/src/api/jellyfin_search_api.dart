// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Search/Hints` — fast, type-as-you-go search.
class JellyfinSearchApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinSearchApi(this._http);

  /// `GET /Search/Hints` — incremental, lightweight search.
  ///
  /// Returns ranked [JellyfinSearchHint]s rather than full items, so it's
  /// safe to call on every keystroke. Pass [userId] to scope to a user's
  /// libraries; the include/exclude flags control which content types
  /// participate in the result.
  ///
  /// Note: the server defaults every `include*` flag to `true`, but this
  /// wrapper deliberately narrows the result to media and artists only —
  /// [includeGenres], [includeStudios] and [includePeople] default to `false`
  /// to keep type-as-you-go results light. Set them to `true` to opt genre,
  /// studio and people hints back in.
  Future<JellyfinQueryResult<JellyfinSearchHint>> hints({
    required String query,
    String? userId,
    String? parentId,
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> mediaTypes = const [],
    int startIndex = 0,
    int? limit,
    bool includeArtists = true,
    bool includeMedia = true,
    bool includeGenres = false,
    bool includeStudios = false,
    bool includePeople = false,
  }) async {
    final qp = <String, dynamic>{
      'searchTerm': query,
      'startIndex': startIndex,
      'includeArtists': includeArtists,
      'includeMedia': includeMedia,
      'includeGenres': includeGenres,
      'includeStudios': includeStudios,
      'includePeople': includePeople,
    };
    if (limit != null) qp['limit'] = limit;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes.join(',');
    }
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes.join(',');

    final res = await _http.request<Map<String, dynamic>>(
      '/Search/Hints',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinSearchHint.fromJson,
      itemsKey: 'SearchHints',
    );
  }
}
