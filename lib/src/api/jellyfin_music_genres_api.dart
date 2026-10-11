// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import 'jellyfin_genres_api.dart';
import 'jellyfin_lookup_helpers.dart';

/// `/MusicGenres*` — music-specific genres.
///
/// Jellyfin 12 folds music genres into the generic genre endpoints:
/// `GET /MusicGenres` is hidden from the OpenAPI document and
/// `GET /MusicGenres/{name}` is marked obsolete. Both still answer on
/// 12.2.
///
/// `genres.list(parentId: musicLibraryId)` replaces [list]: it answers
/// the same `MusicGenre` items, with the same ids. Without `parentId`,
/// `/Genres` answers the generic `Genre` items instead, whose ids seed an
/// empty instant mix — see [JellyfinGenresApi.list].
///
/// [byName] has no exact replacement — `genres.byName()` answers the
/// `Genre` item — so it is not deprecated here.
class JellyfinMusicGenresApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinMusicGenresApi(this._http);

  /// `GET /MusicGenres` — music genres scoped to [parentId] and
  /// optional name range.
  ///
  /// The route still works, but it is hidden from the published
  /// OpenAPI document and marked obsolete upstream in favour of
  /// `GET /Genres`. Prefer `genres.list(parentId: musicLibraryId)`, which
  /// answers the same genres with the same ids and will outlive this
  /// endpoint. The `parentId` is what matters: without it `/Genres`
  /// answers `Genre` items whose ids seed an empty instant mix.
  @Deprecated(
    'Hidden from the Jellyfin 12 API; use '
    'genres.list(parentId: <music library id>) instead.',
  )
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<String> fields = const [],
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    bool? isFavorite,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<String> sortBy = const [],
    bool descending = false,
  }) async {
    final qp = <String, Object?>{'startIndex': startIndex};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes;
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes;
    }
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }
    if (nameStartsWith != null) qp['nameStartsWith'] = nameStartsWith;
    if (nameStartsWithOrGreater != null) {
      qp['nameStartsWithOrGreater'] = nameStartsWithOrGreater;
    }
    if (nameLessThan != null) qp['nameLessThan'] = nameLessThan;
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy;
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }

    return _http.requestJson(
      '/MusicGenres',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /MusicGenres/{genreName}` — lookup a music genre by exact
  /// name. Returns null on 404.
  ///
  /// Answers the `MusicGenre` item, whose id seeds
  /// `instantMix.fromItem`. Jellyfin 12 marks the route obsolete but
  /// still serves it (12.2), and offers no exact replacement:
  /// `genres.byName()` answers the generic `Genre` item, whose id seeds an
  /// empty mix. Should the route go, `genres.list(parentId:
  /// musicLibraryId, searchTerm: name)` finds the same item among partial
  /// matches.
  Future<JellyfinItem?> byName({
    required String name,
  }) =>
      lookupItemByName('/MusicGenres', name, _http);
}
