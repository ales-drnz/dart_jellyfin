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

/// `/Genres*` — generic genres across the library.
///
/// Wraps the `Genres` OpenAPI tag (2 operations). Jellyfin 12 folds the
/// `/MusicGenres` routes into these: list music genres with
/// `list(parentId: musicLibraryId)` and find one with [musicGenre].
///
/// Jellyfin keeps two genre items per name: a `Genre` and, for music, a
/// `MusicGenre`, with different ids. Both ids filter
/// `items.list(genreIds:)`, but only the `MusicGenre` id seeds an instant
/// mix — `/Items/{GenreId}/InstantMix` answers 200 with an empty mix. See
/// [list] for which one each call returns.
///
/// {@category Library}
class JellyfinGenresApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinGenresApi(this._http);

  /// `GET /Genres` — list genres, scoped to [parentId] and filtered
  /// by item kind.
  ///
  /// Which genre item comes back depends on [parentId], not on
  /// [includeItemTypes] (verified on 12.4):
  ///
  /// * with the id of a music library, the `MusicGenre` items — the ids
  ///   a track's `genreItems` carry, which
  ///   `instantMix.fromItem` takes;
  /// * without [parentId], the `Genre` items, even with
  ///   `includeItemTypes` set to albums and tracks. Their ids filter
  ///   `items.list(genreIds:)` just as well, but an instant mix seeded by
  ///   one is empty. This list can miss a music genre: a fresh 12.4
  ///   server had no `Genre` item for one until [byName] was called
  ///   with its name.
  ///
  /// So for music, pass the music library's id as [parentId].
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemKind> includeItemTypes = const [],
    List<JellyfinItemKind> excludeItemTypes = const [],
    bool? isFavorite,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<JellyfinSortField> sortBy = const [],
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'startIndex': startIndex,
      ...browseQuery(
        userId: _http.userId,
        parentId: parentId,
        searchTerm: searchTerm,
        limit: limit,
        sortBy: sortBy,
        descending: descending,
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
      '/Genres',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Genres/{genreName}` — lookup a genre by exact name.
  /// Returns null on 404.
  ///
  /// Answers the `Genre` item, never the `MusicGenre` one: the route
  /// takes no `parentId`. Its id filters `items.list(genreIds:)`, but an
  /// instant mix seeded by it is empty (verified on 12.4). For a music
  /// genre use [musicGenre].
  Future<JellyfinItem?> byName({required String name}) =>
      lookupItemByName('/Genres', name, _http);

  /// The `MusicGenre` item named [name] in the music library
  /// [parentId], or `null` when there is none.
  ///
  /// Replaces `GET /MusicGenres/{genreName}`, which Jellyfin 12 marks
  /// obsolete. It asks `GET /Genres` with [parentId] and [name] as the
  /// search term, and keeps the entry whose name equals [name], ignoring
  /// case: the search also matches parts of names. The id seeds
  /// `instantMix.fromItem` and filters `items.list(genreIds:)`.
  Future<JellyfinItem?> musicGenre({
    required String name,
    required String parentId,
  }) async {
    final page = await list(parentId: parentId, searchTerm: name);
    final wanted = name.toLowerCase();
    for (final genre in page.items) {
      if (genre.name.toLowerCase() == wanted) return genre;
    }
    return null;
  }
}
