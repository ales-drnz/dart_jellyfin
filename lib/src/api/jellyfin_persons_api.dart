// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import 'jellyfin_lookup_helpers.dart';

/// `/Persons*` — actors, directors, composers, artists, etc.
///
/// Wraps the `Persons` OpenAPI tag (2 operations). Since Jellyfin 12
/// music artists are people too, and `GET /Persons` is the declared
/// successor of the `/Artists` routes; filter with
/// `personTypes: ['Artist']` or `['AlbumArtist']`.
class JellyfinPersonsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinPersonsApi(this._http);

  /// `GET /Persons` — search people; filter by [personTypes]
  /// (e.g. `['Actor', 'Director']`) or to people who appear in a
  /// specific item via `appearsInItemId`. [parentId] scopes the
  /// result to one library; [nameStartsWith], [nameStartsWithOrGreater]
  /// and [nameLessThan] drive an alphabet picker; [startIndex] and
  /// [limit] page it.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    int? startIndex,
    int? limit,
    String? searchTerm,
    String? parentId,
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<String> fields = const [],
    List<String> filters = const [],
    bool? isFavorite,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    List<String> personTypes = const [],
    List<String> excludePersonTypes = const [],
    String? appearsInItemId,
    bool enableImages = true,
  }) async {
    final qp = <String, Object?>{
      'enableUserData': enableUserData,
      'enableImages': enableImages,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (parentId != null) qp['parentId'] = parentId;
    if (nameStartsWith != null) qp['nameStartsWith'] = nameStartsWith;
    if (nameStartsWithOrGreater != null) {
      qp['nameStartsWithOrGreater'] = nameStartsWithOrGreater;
    }
    if (nameLessThan != null) qp['nameLessThan'] = nameLessThan;
    if (fields.isNotEmpty) qp['fields'] = fields;
    if (filters.isNotEmpty) qp['filters'] = filters;
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }
    if (personTypes.isNotEmpty) qp['personTypes'] = personTypes;
    if (excludePersonTypes.isNotEmpty) {
      qp['excludePersonTypes'] = excludePersonTypes;
    }
    if (appearsInItemId != null) qp['appearsInItemId'] = appearsInItemId;

    return _http.requestJson(
      '/Persons',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Persons/{name}` — lookup a person by exact name. Returns
  /// null on 404.
  Future<JellyfinItem?> byName({
    required String name,
  }) =>
      lookupItemByName('/Persons', name, _http);
}
