// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/UserViews` — alternate "views" endpoints.
///
/// Wraps the `UserViews` OpenAPI tag (2 operations). The library's
/// "Views" tab traditionally uses `library.userViews()`
/// (`/Users/{id}/Views`); these endpoints expose richer knobs:
/// preset filtering, hidden libraries, external (channel/plugin)
/// content, and the server's grouping recommendations.
class JellyfinUserViewsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinUserViewsApi(this._http);

  /// `GET /UserViews` — views with optional preset/hidden/external
  /// filtering.
  Future<JellyfinQueryResult<JellyfinView>> list({
    bool? includeExternalContent,
    List<String> presetViews = const [],
    bool? includeHidden,
  }) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (includeExternalContent != null) {
      qp['includeExternalContent'] = includeExternalContent;
    }
    if (presetViews.isNotEmpty) qp['presetViews'] = presetViews.join(',');
    if (includeHidden != null) qp['includeHidden'] = includeHidden;

    final res = await _http.request<Map<String, dynamic>>(
      '/UserViews',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinView.fromJson,
    );
  }

  /// `GET /UserViews/GroupingOptions` — the server's recommendations
  /// for how to group views in the UI (e.g. "by media type", "by
  /// folder"). Returned as a flat list of option maps.
  Future<List<Map<String, dynamic>>> groupingOptions() async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;

    final res = await _http.request<List<dynamic>>(
      '/UserViews/GroupingOptions',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
