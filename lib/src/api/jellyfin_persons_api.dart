// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_lookup_helpers.dart';
import 'jellyfin_query_helpers.dart';

/// `/Persons*` — actors, directors, composers, artists, etc.
///
/// Wraps the `Persons` OpenAPI tag (2 operations). Since Jellyfin 12
/// music artists are people too, and `GET /Persons` is the declared
/// successor of the `/Artists` routes: `JellyfinArtistsApi` asks it with
/// `personTypes: ['Artist']` or `['AlbumArtist']`.
///
/// {@category Library}
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
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemFilter> filters = const [],
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
      'startIndex': ?startIndex,
      ...browseQuery(
        userId: _http.userId,
        parentId: parentId,
        searchTerm: searchTerm,
        limit: limit,
        fields: fields,
        filters: filters,
        isFavorite: isFavorite,
        imageTypeLimit: imageTypeLimit,
        enableImageTypes: enableImageTypes,
        nameStartsWith: nameStartsWith,
        nameStartsWithOrGreater: nameStartsWithOrGreater,
        nameLessThan: nameLessThan,
      ),
      if (personTypes.isNotEmpty) 'personTypes': personTypes,
      if (excludePersonTypes.isNotEmpty)
        'excludePersonTypes': excludePersonTypes,
      'appearsInItemId': ?appearsInItemId,
    };

    return _http.requestJson(
      '/Persons',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Persons/{name}` — lookup a person by exact name. Returns
  /// null on 404.
  Future<JellyfinItem?> byName({required String name}) =>
      lookupItemByName('/Persons', name, _http);
}
