// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/MediaSegments/*` — skip-intro/recap/outro markers.
///
/// Wraps the `MediaSegments` OpenAPI tag (1 operation). Segments are
/// produced by Jellyfin plugins (e.g. Intro Skipper) and consumed by
/// players to expose a "skip" button at the right moment.
class JellyfinMediaSegmentsApi {
  final JellyfinConnection _http;

  JellyfinMediaSegmentsApi(this._http);

  /// `/MediaSegments/{itemId}` — every segment registered on this item.
  ///
  /// Filter to specific kinds with [includeSegmentTypes], using the
  /// canonical strings from [JellyfinMediaSegmentType]
  /// (e.g. `['Intro', 'Outro']`).
  Future<JellyfinQueryResult<JellyfinMediaSegment>> forItem({
    required String itemId,
    List<String> includeSegmentTypes = const [],
  }) async {
    final qp = <String, dynamic>{};
    if (includeSegmentTypes.isNotEmpty) {
      qp['includeSegmentTypes'] = includeSegmentTypes.join(',');
    }
    final res = await _http.request<Map<String, dynamic>>(
      '/MediaSegments/$itemId',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinMediaSegment.fromJson,
    );
  }
}
