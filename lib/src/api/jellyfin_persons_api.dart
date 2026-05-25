// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Persons*` — actors, directors, composers, etc.
///
/// Wraps the `Persons` OpenAPI tag (2 operations).
class JellyfinPersonsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinPersonsApi(this._http);

  /// `GET /Persons` — search people; filter by [personTypes]
  /// (e.g. `['Actor', 'Director']`) or to people who appear in a
  /// specific item via [appearsInItemId].
  Future<JellyfinQueryResult<JellyfinItem>> list({
    int? limit,
    String? searchTerm,
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
    final qp = <String, dynamic>{
      'enableUserData': enableUserData,
      'enableImages': enableImages,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (limit != null) qp['limit'] = limit;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }
    if (personTypes.isNotEmpty) qp['personTypes'] = personTypes.join(',');
    if (excludePersonTypes.isNotEmpty) {
      qp['excludePersonTypes'] = excludePersonTypes.join(',');
    }
    if (appearsInItemId != null) qp['appearsInItemId'] = appearsInItemId;

    final res = await _http.request<Map<String, dynamic>>(
      '/Persons',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Persons/{name}` — lookup a person by exact name. Returns
  /// null on 404.
  Future<JellyfinItem?> byName(String name) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    try {
      final res = await _http.request<Map<String, dynamic>>(
        '/Persons/${Uri.encodeComponent(name)}',
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
