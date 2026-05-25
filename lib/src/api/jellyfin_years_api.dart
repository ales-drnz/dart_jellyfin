// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Years*` — release-year browse buckets.
///
/// Wraps the `Years` OpenAPI tag (2 operations). The unit of return
/// is a [JellyfinItem] per year, with `name` set to the year number.
class JellyfinYearsApi {
  final JellyfinConnection _http;

  JellyfinYearsApi(this._http);

  /// `GET /Years` — every year that has at least one matching item.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    int startIndex = 0,
    int? limit,
    List<String> sortBy = const [],
    bool descending = false,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> mediaTypes = const [],
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool recursive = true,
    bool enableImages = true,
  }) async {
    final qp = <String, dynamic>{
      'startIndex': startIndex,
      'recursive': recursive,
      'enableUserData': enableUserData,
      'enableImages': enableImages,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (limit != null) qp['limit'] = limit;
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
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

    final res = await _http.request<Map<String, dynamic>>(
      '/Years',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Years/{year}` — lookup a single year. Returns null on 404.
  Future<JellyfinItem?> byYear(int year) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    try {
      final res = await _http.request<Map<String, dynamic>>(
        '/Years/$year',
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
}
