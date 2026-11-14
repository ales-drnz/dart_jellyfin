// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_query_helpers.dart';

/// `/Years*` — release-year browse buckets.
///
/// Wraps the `Years` OpenAPI tag (2 operations). The unit of return
/// is a [JellyfinItem] per year, with `name` set to the year number.
///
/// {@category Library}
class JellyfinYearsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinYearsApi(this._http);

  /// `GET /Years` — every year that has at least one matching item.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    int startIndex = 0,
    int? limit,
    List<JellyfinSortField> sortBy = const [],
    bool descending = false,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemKind> includeItemTypes = const [],
    List<JellyfinItemKind> excludeItemTypes = const [],
    List<JellyfinMediaType> mediaTypes = const [],
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool recursive = true,
    bool enableImages = true,
  }) async {
    final qp = <String, Object?>{
      'startIndex': startIndex,
      'recursive': recursive,
      'enableUserData': enableUserData,
      'enableImages': enableImages,
      'userId': ?_http.userId,
      'parentId': ?parentId,
      'limit': ?limit,
    };
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy;
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (fields.isNotEmpty) qp['fields'] = fields;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes;
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes;
    }
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }

    return _http.requestJson(
      '/Years',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Years/{year}` — lookup a single year. Returns null on 404.
  Future<JellyfinItem?> byYear({required int year}) async {
    final qp = <String, Object?>{'userId': ?_http.userId};
    return _http.requestJsonOrNull(
      '/Years/$year',
      objectOf(JellyfinItem.fromJson),
      queryParameters: qp,
    );
  }
}
