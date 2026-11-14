// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
/// @docImport 'jellyfin_items_api.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';

/// `/Items/Suggestions` — server-curated picks for the current user.
///
/// Wraps the `Suggestions` OpenAPI tag (1 operation). Returns the same
/// envelope as [JellyfinItemsApi.list]: a [JellyfinQueryResult] of
/// [JellyfinItem]s, so the result plugs into any browsing UI.
///
/// {@category Search and lyrics}
class JellyfinSuggestionsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinSuggestionsApi(this._http);

  /// `/Items/Suggestions` — homepage-style picks.
  ///
  /// [mediaType] filters to media kinds ([JellyfinMediaType.audio],
  /// [JellyfinMediaType.video]); [type] to item kinds
  /// ([JellyfinItemKind.musicAlbum], [JellyfinItemKind.movie]).
  Future<JellyfinQueryResult<JellyfinItem>> list({
    List<JellyfinMediaType> mediaType = const [],
    List<JellyfinItemKind> type = const [],
    int? startIndex,
    int? limit,
    bool enableTotalRecordCount = true,
  }) async {
    final qp = <String, Object?>{
      'enableTotalRecordCount': enableTotalRecordCount,
      'userId': ?_http.userId,
      if (mediaType.isNotEmpty) 'mediaType': mediaType,
      if (type.isNotEmpty) 'type': type,
      'startIndex': ?startIndex,
      'limit': ?limit,
    };

    return _http.requestJson(
      '/Items/Suggestions',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }
}
