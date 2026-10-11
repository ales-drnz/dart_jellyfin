// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import 'jellyfin_items_api.dart';

/// `/Items/Suggestions` — server-curated picks for the current user.
///
/// Wraps the `Suggestions` OpenAPI tag (1 operation). Returns the same
/// envelope as [JellyfinItemsApi.list]: a [JellyfinQueryResult] of
/// [JellyfinItem]s, so the result plugs into any browsing UI.
class JellyfinSuggestionsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinSuggestionsApi(this._http);

  /// `/Items/Suggestions` — homepage-style picks.
  ///
  /// [mediaType] filters to media kinds (e.g. `['Audio']`, `['Video']`).
  /// [type] filters to BaseItemKind values (e.g. `['MusicAlbum']`,
  /// `['Movie']`, see [JellyfinItemKind]).
  Future<JellyfinQueryResult<JellyfinItem>> list({
    List<String> mediaType = const [],
    List<String> type = const [],
    int? startIndex,
    int? limit,
    bool enableTotalRecordCount = true,
  }) async {
    final qp = <String, Object?>{
      'enableTotalRecordCount': enableTotalRecordCount,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (mediaType.isNotEmpty) qp['mediaType'] = mediaType;
    if (type.isNotEmpty) qp['type'] = type;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;

    return _http.requestJson(
      '/Items/Suggestions',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }
}
