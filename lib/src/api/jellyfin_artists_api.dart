// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_instant_mix_api.dart';
import 'jellyfin_items_api.dart';
import 'jellyfin_persons_api.dart';

/// Music artists, through the people routes.
///
/// Jellyfin 12 stores music artists as people and marks `GET /Artists`,
/// `/Artists/AlbumArtists` and `/Artists/{name}` obsolete in favour of
/// `GET /Persons` and `/Persons/{name}`. This sub-API asks those routes,
/// as Jellyfin Web 12 does for its Artists and Album Artists tabs:
/// [list] filters people by the `Artist` kind, [albumArtists] by
/// `AlbumArtist`, and [byName] looks one up.
///
/// The answers are `Person` items. Measured on 12.4:
///
/// * a person id filters tracks and albums like an artist id:
///   `items.list(artistIds: [person.id])` and `albumArtistIds:` answer
///   the artist's music;
/// * scoped by `parentId`, the lists match what `/Artists` and
///   `/Artists/AlbumArtists` answered;
/// * a person id seeds an empty instant mix, and the person carries no
///   MusicBrainz id. For those, use the `MusicArtist` item: a track's
///   `artistItems` and `albumArtistItems`, or
///   `items.list(includeItemTypes: [JellyfinItemKind.musicArtist])`, see
///   [JellyfinInstantMixApi.fromArtist].
///
/// `/Persons` has no sort, genre or year filter: it answers by name.
/// [JellyfinItemsApi.list] with `includeItemTypes:
/// [JellyfinItemKind.musicArtist]` sorts and pages `MusicArtist` items.
///
/// {@category Library}
class JellyfinArtistsApi {
  final JellyfinPersonsApi _persons;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinArtistsApi(JellyfinConnection http)
    : _persons = JellyfinPersonsApi(http);

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

  /// `GET /Persons/{name}` — the person named [name], or `null` when
  /// there is none.
  Future<JellyfinItem?> byName({required String name}) =>
      _persons.byName(name: name);
}
