// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_lookup_helpers.dart';
import 'jellyfin_query_helpers.dart';

/// `/Studios*` — production studios and labels.
///
/// Wraps the `Studios` OpenAPI tag (2 operations).
///
/// {@category Library}
class JellyfinStudiosApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinStudiosApi(this._http);

  /// `GET /Studios` — list studios, optionally scoped to a parent
  /// library and filtered by item kind.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemKind> includeItemTypes = const [],
    List<JellyfinItemKind> excludeItemTypes = const [],
    bool? isFavorite,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
  }) async {
    final qp = <String, Object?>{
      'startIndex': startIndex,
      'enableUserData': enableUserData,
      ...browseQuery(
        userId: _http.userId,
        parentId: parentId,
        searchTerm: searchTerm,
        limit: limit,
        fields: fields,
        includeItemTypes: includeItemTypes,
        excludeItemTypes: excludeItemTypes,
        isFavorite: isFavorite,
        imageTypeLimit: imageTypeLimit,
        enableImageTypes: enableImageTypes,
        nameStartsWith: nameStartsWith,
        nameStartsWithOrGreater: nameStartsWithOrGreater,
        nameLessThan: nameLessThan,
      ),
    };

    return _http.requestJson(
      '/Studios',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Studios/{name}` — lookup a studio by exact name. Returns
  /// null on 404.
  Future<JellyfinItem?> byName({required String name}) =>
      lookupItemByName('/Studios', name, _http);
}
