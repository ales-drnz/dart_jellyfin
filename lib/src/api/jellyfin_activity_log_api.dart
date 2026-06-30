// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/System/ActivityLog` — recent server activity.
///
/// Wraps the `ActivityLog` OpenAPI tag (1 operation). Admin only.
class JellyfinActivityLogApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinActivityLogApi(this._http);

  /// `GET /System/ActivityLog/Entries` — recent activity entries.
  Future<List<Map<String, dynamic>>> entries({
    int? startIndex,
    int? limit,
    DateTime? minDate,
    bool? hasUserId,
  }) async {
    final qp = <String, dynamic>{};
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (minDate != null) qp['minDate'] = minDate.toUtc().toIso8601String();
    if (hasUserId != null) qp['hasUserId'] = hasUserId;
    final res = await _http.request<Map<String, dynamic>>(
      '/System/ActivityLog/Entries',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final items = res.data?['Items'];
    if (items is! List) return const [];
    return [
      for (final e in items)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
