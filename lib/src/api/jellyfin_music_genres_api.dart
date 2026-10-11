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
/// 12.0, but [JellyfinGenresApi] is the supported path —
/// `genres.list(includeItemTypes: ['MusicAlbum', 'Audio'])` returns
/// the same buckets and `genres.byName()` the same lookup.
class JellyfinMusicGenresApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinMusicGenresApi(this._http);

  /// `GET /MusicGenres` — music genres scoped to [parentId] and
  /// optional name range.
  ///
  /// The route still works, but it is hidden from the published
  /// OpenAPI document and marked obsolete upstream in favour of
  /// `GET /Genres`. Prefer
  /// `genres.list(includeItemTypes: ['MusicAlbum', 'Audio'])`, which is
  /// the supported way to get the same buckets and will outlive this
  /// endpoint.
  @Deprecated(
    'Hidden from the Jellyfin 12 API; use '
    "genres.list(includeItemTypes: ['MusicAlbum', 'Audio']) instead.",
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
  /// Obsolete in Jellyfin 12; `genres.byName()` is the replacement.
  @Deprecated('Obsolete in Jellyfin 12; use genres.byName() instead.')
  Future<JellyfinItem?> byName(String name) =>
      lookupItemByName('/MusicGenres', name, _http);
}
