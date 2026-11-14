// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_instant_mix_api.dart';
import 'jellyfin_items_api.dart';
import 'jellyfin_persons_api.dart';
import 'jellyfin_query_helpers.dart';

/// Music artists, through the people routes.
///
/// Jellyfin 12 stores music artists as people and marks `GET /Artists`,
/// `/Artists/AlbumArtists` and `/Artists/{name}` obsolete in favour of
/// `GET /Persons` and `/Persons/{name}`. This sub-API asks those routes,
/// as Jellyfin Web 12 does for its Artists and Album Artists tabs:
/// [list] filters people by the `Artist` kind, [albumArtists] by
/// `AlbumArtist`, and [byName] looks up an artist.
///
/// The answers are `Person` items. Measured on 12.4:
///
/// * a person id filters tracks and albums like an artist id:
///   `items.list(artistIds: [person.id])` and `albumArtistIds:` answer
///   the artist's music;
/// * scoped by `parentId`, the lists name the same artists as
///   `/Artists` and `/Artists/AlbumArtists`, and `totalRecordCount`
///   counts every match, not the page;
/// * `isFavorite` and `filters` read the person's own user data: an
///   artist marked favourite through its `MusicArtist` id is not a
///   favourite person;
/// * a person id seeds an empty instant mix, and the person carries no
///   MusicBrainz id. For those, use the `MusicArtist` item: a track's
///   `artistItems` and `albumArtistItems`, or
///   `items.list(includeItemTypes: [JellyfinItemKind.musicArtist])`, see
///   [JellyfinInstantMixApi.fromArtist].
///
/// `/Persons` has no sort, genre or year filter: it answers by name.
/// [musicArtists] and [musicAlbumArtists] list the `MusicArtist` items of
/// one library instead, sorted and filtered by the server, through the
/// obsolete `/Artists` routes, which 12.4 still answers.
/// [JellyfinItemsApi.list] with `includeItemTypes:
/// [JellyfinItemKind.musicArtist]` sorts and pages `MusicArtist` items
/// too, but ignores `parentId`.
///
/// {@category Library}
class JellyfinArtistsApi {
  final JellyfinConnection _http;
  final JellyfinPersonsApi _persons;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinArtistsApi(this._http) : _persons = JellyfinPersonsApi(_http);

  /// `GET /Persons?personTypes=Artist` — the people credited as artist
  /// on a track.
  ///
  /// [parentId] scopes the list to one library; without it the server
  /// also answers people from other libraries. [nameStartsWith],
  /// [nameStartsWithOrGreater] and [nameLessThan] drive an alphabet
  /// picker; [startIndex] and [limit] page it.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemFilter> filters = const [],
    bool? isFavorite,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool enableImages = true,
  }) => _persons.list(
    personTypes: const ['Artist'],
    parentId: parentId,
    searchTerm: searchTerm,
    startIndex: startIndex,
    limit: limit,
    nameStartsWith: nameStartsWith,
    nameStartsWithOrGreater: nameStartsWithOrGreater,
    nameLessThan: nameLessThan,
    fields: fields,
    filters: filters,
    isFavorite: isFavorite,
    enableUserData: enableUserData,
    imageTypeLimit: imageTypeLimit,
    enableImageTypes: enableImageTypes,
    enableImages: enableImages,
  );

  /// `GET /Persons?personTypes=AlbumArtist` — the people credited as
  /// album artist. The right call for an "Artists" tab in a music UI.
  ///
  /// Takes the same parameters as [list].
  Future<JellyfinQueryResult<JellyfinItem>> albumArtists({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    String? nameStartsWith,
    String? nameStartsWithOrGreater,
    String? nameLessThan,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemFilter> filters = const [],
    bool? isFavorite,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool enableImages = true,
  }) => _persons.list(
    personTypes: const ['AlbumArtist'],
    parentId: parentId,
    searchTerm: searchTerm,
    startIndex: startIndex,
    limit: limit,
    nameStartsWith: nameStartsWith,
    nameStartsWithOrGreater: nameStartsWithOrGreater,
    nameLessThan: nameLessThan,
    fields: fields,
    filters: filters,
    isFavorite: isFavorite,
    enableUserData: enableUserData,
    imageTypeLimit: imageTypeLimit,
    enableImageTypes: enableImageTypes,
    enableImages: enableImages,
  );

  /// `GET /Artists` — the `MusicArtist` items credited as artist on a
  /// track, as Jellyfin Web 10 listed them.
  ///
  /// The ids are those of the `MusicArtist` items, the ones
  /// `items.list(includeItemTypes: [JellyfinItemKind.musicArtist])`,
  /// a track's `artistItems` and [JellyfinInstantMixApi.fromArtist] use:
  /// [isFavorite] and [filters] read the artist's own user data, and the
  /// item carries its MusicBrainz id. [parentId] scopes the list to one
  /// library, which `/Items` ignores for `MusicArtist` (measured on 12.0
  /// and 12.4 with two music libraries). [sortBy] and [descending] order
  /// it; [genreIds], [genres] and [years] narrow it to the artists with a
  /// track that matches.
  ///
  /// Jellyfin 12 marks `/Artists` obsolete in favour of `/Persons` ([list])
  /// and still answers it (12.4); a later Jellyfin may answer 404, a
  /// `notFound` error.
  Future<JellyfinQueryResult<JellyfinItem>> musicArtists({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<JellyfinSortField> sortBy = const [],
    bool descending = false,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemFilter> filters = const [],
    bool? isFavorite,
    List<String> genreIds = const [],
    List<String> genres = const [],
    List<int> years = const [],
    String? nameStartsWith,
    bool enableUserData = true,
    bool enableImages = true,
  }) => _artistsRoute(
    '/Artists',
    parentId: parentId,
    searchTerm: searchTerm,
    startIndex: startIndex,
    limit: limit,
    sortBy: sortBy,
    descending: descending,
    fields: fields,
    filters: filters,
    isFavorite: isFavorite,
    genreIds: genreIds,
    genres: genres,
    years: years,
    nameStartsWith: nameStartsWith,
    enableUserData: enableUserData,
    enableImages: enableImages,
  );

  /// `GET /Artists/AlbumArtists` — the `MusicArtist` items credited as
  /// album artist, the ones with an album of their own.
  ///
  /// Takes the same parameters as [musicArtists], and is as obsolete.
  Future<JellyfinQueryResult<JellyfinItem>> musicAlbumArtists({
    String? parentId,
    String? searchTerm,
    int startIndex = 0,
    int? limit,
    List<JellyfinSortField> sortBy = const [],
    bool descending = false,
    List<JellyfinItemField> fields = const [],
    List<JellyfinItemFilter> filters = const [],
    bool? isFavorite,
    List<String> genreIds = const [],
    List<String> genres = const [],
    List<int> years = const [],
    String? nameStartsWith,
    bool enableUserData = true,
    bool enableImages = true,
  }) => _artistsRoute(
    '/Artists/AlbumArtists',
    parentId: parentId,
    searchTerm: searchTerm,
    startIndex: startIndex,
    limit: limit,
    sortBy: sortBy,
    descending: descending,
    fields: fields,
    filters: filters,
    isFavorite: isFavorite,
    genreIds: genreIds,
    genres: genres,
    years: years,
    nameStartsWith: nameStartsWith,
    enableUserData: enableUserData,
    enableImages: enableImages,
  );

  Future<JellyfinQueryResult<JellyfinItem>> _artistsRoute(
    String path, {
    required String? parentId,
    required String? searchTerm,
    required int startIndex,
    required int? limit,
    required List<JellyfinSortField> sortBy,
    required bool descending,
    required List<JellyfinItemField> fields,
    required List<JellyfinItemFilter> filters,
    required bool? isFavorite,
    required List<String> genreIds,
    required List<String> genres,
    required List<int> years,
    required String? nameStartsWith,
    required bool enableUserData,
    required bool enableImages,
  }) {
    final qp = <String, Object?>{
      'startIndex': startIndex,
      'enableUserData': enableUserData,
      'enableImages': enableImages,
      ...browseQuery(
        userId: _http.userId,
        parentId: parentId,
        searchTerm: searchTerm,
        limit: limit,
        sortBy: sortBy,
        descending: descending,
        fields: fields,
        filters: filters,
        isFavorite: isFavorite,
        nameStartsWith: nameStartsWith,
      ),
      if (genreIds.isNotEmpty) 'genreIds': genreIds,
      if (genres.isNotEmpty) 'genres': genres,
      if (years.isNotEmpty) 'years': years,
    };
    return _http.requestJson(
      path,
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// The artist or album artist named [name], or `null` when there is
  /// none.
  ///
  /// `GET /Persons/{name}` answers any person, an actor too, and the
  /// person it answers carries no credit kind (12.4). So this first asks
  /// `GET /Persons` for artists and album artists with [name] as the
  /// search term and keeps the entry whose name equals [name], ignoring
  /// case: the search also matches parts of names. Then it reads that
  /// person through `GET /Persons/{name}`.
  Future<JellyfinItem?> byName({required String name}) async {
    final page = await _persons.list(
      personTypes: const ['Artist', 'AlbumArtist'],
      searchTerm: name,
      enableUserData: false,
      enableImages: false,
    );
    final wanted = name.toLowerCase();
    for (final person in page.items) {
      if (person.name.toLowerCase() == wanted) {
        return _persons.byName(name: person.name);
      }
    }
    return null;
  }
}
