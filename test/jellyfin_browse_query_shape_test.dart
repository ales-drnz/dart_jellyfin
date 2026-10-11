// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Wire-contract assertions for the item-browsing and filtering surface.
///
/// Every test here inspects the query string the wrapper emits, because
/// that is the only place this defect class is observable: Jellyfin
/// silently drops an array value it cannot parse (see
/// `CommaDelimitedCollectionModelBinder`, which swallows the
/// `FormatException` and keeps going) and answers 200 with a *wider*
/// result set. Asserting on returned entities would pass either way.
///
/// The contract being pinned: an array query parameter is emitted as one
/// repeated parameter per element (`genreIds=a&genreIds=b`), never as a
/// delimited string. Jellyfin binds arrays with a comma binder on some
/// endpoints and a pipe binder on others; both take repeated values
/// verbatim without splitting, so repetition is correct for all of them.
library;

import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient client;

  setUp(() {
    adapter = CapturingAdapter();
    client = capturingClient(adapter);
  });

  group('JellyfinItemsApi.list id filters', () {
    test('every id list is repeated, not delimiter-joined', () async {
      await client.items.list(
        ids: const ['i1', 'i2'],
        excludeItemIds: const ['x1', 'x2'],
        genreIds: const ['g1', 'g2'],
        artistIds: const ['a1', 'a2'],
        albumArtistIds: const ['aa1', 'aa2'],
        contributingArtistIds: const ['ca1', 'ca2'],
        albumIds: const ['al1', 'al2'],
        studioIds: const ['s1', 's2'],
        personIds: const ['p1', 'p2'],
      );

      expect(adapter.path, '/Items');
      expect(adapter.query['ids'], ['i1', 'i2']);
      expect(adapter.query['excludeItemIds'], ['x1', 'x2']);
      expect(adapter.query['genreIds'], ['g1', 'g2']);
      expect(adapter.query['artistIds'], ['a1', 'a2']);
      expect(adapter.query['albumArtistIds'], ['aa1', 'aa2']);
      expect(adapter.query['contributingArtistIds'], ['ca1', 'ca2']);
      expect(adapter.query['albumIds'], ['al1', 'al2']);
      expect(adapter.query['studioIds'], ['s1', 's2']);
      expect(adapter.query['personIds'], ['p1', 'p2']);
    });

    test('no id list is joined with a comma or a pipe', () async {
      await client.items.list(
        genreIds: const ['g1', 'g2'],
        artistIds: const ['a1', 'a2'],
      );

      // `,` encodes as %2C and `|` as %7C — a joined list would leave
      // one of them between the two ids.
      expect(adapter.rawQuery, isNot(contains('%2C')));
      expect(adapter.rawQuery, isNot(contains('%7C')));
      expect(adapter.rawQuery, isNot(contains('g1,g2')));
      expect(adapter.rawQuery, isNot(contains('g1|g2')));
    });

    test('name filters travel alongside their id counterparts', () async {
      await client.items.list(
        genres: const ['Rock', 'Jazz'],
        artists: const ['Bowie'],
        albums: const ['Low'],
        studios: const ['4AD'],
        tags: const ['live', 'remaster'],
        officialRatings: const ['PG'],
        years: const [1977, 1980],
      );

      expect(adapter.query['genres'], ['Rock', 'Jazz']);
      expect(adapter.query['artists'], ['Bowie']);
      expect(adapter.query['albums'], ['Low']);
      expect(adapter.query['studios'], ['4AD']);
      expect(adapter.query['tags'], ['live', 'remaster']);
      expect(adapter.query['officialRatings'], ['PG']);
      expect(adapter.query['years'], ['1977', '1980']);
    });

    test('a name containing a delimiter survives intact', () async {
      await client.items.list(
        genres: const ['Rock, Pop', 'Jazz|Funk'],
      );

      // Exactly two values, each still whole. A joined encoding would
      // make the server split these into four bogus genres.
      expect(adapter.query['genres'], ['Rock, Pop', 'Jazz|Funk']);
    });

    test('empty lists are omitted entirely', () async {
      await client.items.list(parentId: 'lib-1');

      for (final key in const [
        'ids',
        'genreIds',
        'genres',
        'artistIds',
        'albumIds',
        'studioIds',
        'personIds',
        'tags',
        'years',
        'officialRatings',
      ]) {
        expect(
          adapter.query.containsKey(key),
          isFalse,
          reason: '$key should not be sent when empty',
        );
      }
    });
  });

  group('JellyfinItemsApi.list fields and sorting', () {
    test('sends no fields param by default', () async {
      await client.items.list(parentId: 'lib-1');
      expect(adapter.query.containsKey('fields'), isFalse);
    });

    test('musicFields is opt-in and repeated', () async {
      await client.items.list(fields: JellyfinItemsApi.musicFields);
      expect(adapter.query['fields'], JellyfinItemsApi.musicFields);
    });

    test('omits sortOrder when there is no sortBy to apply it to', () async {
      await client.items.list(parentId: 'lib-1');
      expect(adapter.query.containsKey('sortBy'), isFalse);
      expect(adapter.query.containsKey('sortOrder'), isFalse);
    });

    test('multi-column sortBy is repeated and carries sortOrder', () async {
      await client.items.list(
        sortBy: const [
          JellyfinSortField.albumArtist,
          JellyfinSortField.sortName
        ],
        descending: true,
      );
      expect(adapter.query['sortBy'], ['AlbumArtist', 'SortName']);
      expect(adapter.query['sortOrder'], ['Descending']);
    });
  });

  group('JellyfinItemsApi.count', () {
    setUp(() {
      adapter.body = jsonEncode({
        'Items': <dynamic>[],
        'TotalRecordCount': 42,
      });
    });

    test('counts a genre- and search-scoped set without fetching it', () async {
      final total = await client.items.count(
        parentId: 'lib-1',
        includeItemTypes: const [JellyfinItemKind.audio],
        genreIds: const ['g1', 'g2'],
        searchTerm: 'bowie',
      );

      expect(total, 42);
      expect(adapter.path, '/Items');
      expect(adapter.query['genreIds'], ['g1', 'g2']);
      expect(adapter.query['searchTerm'], ['bowie']);
      expect(adapter.query['includeItemTypes'], ['Audio']);
      expect(adapter.query['limit'], ['0']);
      expect(adapter.query['enableTotalRecordCount'], ['true']);
      expect(adapter.query['enableImages'], ['false']);
      expect(adapter.query['enableUserData'], ['false']);
    });

    test('narrows exactly like list does', () async {
      // Same narrowing arguments through both entry points must reach
      // the wire identically; if one grows a filter the other lacks,
      // callers are pushed back to the list(limit: 1) workaround.
      const narrowing = <String>[
        'parentId',
        'includeItemTypes',
        'excludeItemTypes',
        'mediaTypes',
        'searchTerm',
        'filters',
        'ids',
        'excludeItemIds',
        'genreIds',
        'genres',
        'artistIds',
        'artists',
        'albumArtistIds',
        'contributingArtistIds',
        'albumIds',
        'albums',
        'studioIds',
        'studios',
        'personIds',
        'tags',
        'officialRatings',
        'years',
        'nameStartsWith',
        'isFavorite',
        'isPlayed',
        'recursive',
      ];

      await client.items.list(
        parentId: 'lib-1',
        includeItemTypes: const [JellyfinItemKind.audio],
        excludeItemTypes: const [JellyfinItemKind.folder],
        mediaTypes: const [JellyfinMediaType.audio],
        searchTerm: 'bowie',
        filters: const [JellyfinItemFilter.isFavorite],
        ids: const ['i1'],
        excludeItemIds: const ['x1'],
        genreIds: const ['g1'],
        genres: const ['Rock'],
        artistIds: const ['a1'],
        artists: const ['Bowie'],
        albumArtistIds: const ['aa1'],
        contributingArtistIds: const ['ca1'],
        albumIds: const ['al1'],
        albums: const ['Low'],
        studioIds: const ['s1'],
        studios: const ['4AD'],
        personIds: const ['p1'],
        tags: const ['live'],
        officialRatings: const ['PG'],
        years: const [1977],
        nameStartsWith: 'B',
        isFavorite: true,
        isPlayed: false,
        recursive: false,
      );
      final fromList = adapter.query;

      await client.items.count(
        parentId: 'lib-1',
        includeItemTypes: const [JellyfinItemKind.audio],
        excludeItemTypes: const [JellyfinItemKind.folder],
        mediaTypes: const [JellyfinMediaType.audio],
        searchTerm: 'bowie',
        filters: const [JellyfinItemFilter.isFavorite],
        ids: const ['i1'],
        excludeItemIds: const ['x1'],
        genreIds: const ['g1'],
        genres: const ['Rock'],
        artistIds: const ['a1'],
        artists: const ['Bowie'],
        albumArtistIds: const ['aa1'],
        contributingArtistIds: const ['ca1'],
        albumIds: const ['al1'],
        albums: const ['Low'],
        studioIds: const ['s1'],
        studios: const ['4AD'],
        personIds: const ['p1'],
        tags: const ['live'],
        officialRatings: const ['PG'],
        years: const [1977],
        nameStartsWith: 'B',
        isFavorite: true,
        isPlayed: false,
        recursive: false,
      );
      final fromCount = adapter.query;

      for (final key in narrowing) {
        expect(
          fromList[key],
          isNotNull,
          reason: 'list() did not send $key',
        );
        expect(
          fromCount[key],
          fromList[key],
          reason: 'count() and list() disagree on $key',
        );
      }
    });
  });

  group('JellyfinArtistsApi', () {
    test('genreIds is repeated, not pipe-joined', () async {
      // Regression: /Artists binds genreIds with the *comma* binder, so
      // a pipe-joined value parsed as one malformed guid, was dropped,
      // and the genre filter silently did nothing.
      await client.artists.list(genreIds: const ['g1', 'g2']);

      expect(adapter.path, '/Artists');
      expect(adapter.query['genreIds'], ['g1', 'g2']);
      expect(adapter.rawQuery, isNot(contains('%7C')));
    });

    test('genres, tags and officialRatings are repeated too', () async {
      await client.artists.albumArtists(
        genres: const ['Rock', 'Jazz'],
        tags: const ['live'],
        officialRatings: const ['PG'],
        years: const [1977, 1980],
        sortBy: const [
          JellyfinSortField.sortName,
          JellyfinSortField.dateCreated
        ],
      );

      expect(adapter.path, '/Artists/AlbumArtists');
      expect(adapter.query['genres'], ['Rock', 'Jazz']);
      expect(adapter.query['tags'], ['live']);
      expect(adapter.query['officialRatings'], ['PG']);
      expect(adapter.query['years'], ['1977', '1980']);
      expect(adapter.query['sortBy'], ['SortName', 'DateCreated']);
    });
  });

  group('JellyfinTvShowsApi.episodes', () {
    test('sends sortBy as a single enum value', () async {
      // /Shows/{seriesId}/Episodes binds `ItemSortBy? sortBy` — one
      // enum, not a collection. A comma-joined list never parses.
      await client.tvShows.episodes(
        seriesId: 'series-1',
        sortBy: 'PremiereDate',
      );

      expect(adapter.path, '/Shows/series-1/Episodes');
      expect(adapter.query['sortBy'], ['PremiereDate']);
      expect(adapter.rawQuery, isNot(contains('%2C')));
    });

    test('omits sortBy when not given', () async {
      await client.tvShows.episodes(seriesId: 'series-1');
      expect(adapter.query.containsKey('sortBy'), isFalse);
    });
  });

  group('JellyfinLibraryApi.similarItems', () {
    test('excludeArtistIds is a repeated list', () async {
      await client.library.similarItems(
        itemId: 'item-1',
        excludeArtistIds: const ['a1', 'a2'],
      );

      expect(adapter.path, '/Items/item-1/Similar');
      expect(adapter.query['excludeArtistIds'], ['a1', 'a2']);
    });

    test('omits excludeArtistIds when empty', () async {
      await client.library.similarItems(itemId: 'item-1');
      expect(adapter.query.containsKey('excludeArtistIds'), isFalse);
    });
  });

  group('JellyfinLibraryApi.collections', () {
    test('hits /Items/{id}/Collections with paging and fields', () async {
      await client.library.collections(
        itemId: 'item-1',
        startIndex: 10,
        limit: 5,
        fields: const [
          JellyfinItemField.overview,
          JellyfinItemField.childCount
        ],
      );

      expect(adapter.path, '/Items/item-1/Collections');
      expect(adapter.query['startIndex'], ['10']);
      expect(adapter.query['limit'], ['5']);
      expect(adapter.query['fields'], ['Overview', 'ChildCount']);
    });

    test('sends no query at all when nothing is asked', () async {
      await client.library.collections(itemId: 'item-1');
      expect(adapter.path, '/Items/item-1/Collections');
      expect(adapter.query.containsKey('startIndex'), isFalse);
      expect(adapter.query.containsKey('limit'), isFalse);
      expect(adapter.query.containsKey('fields'), isFalse);
    });
  });

  group('sibling browse endpoints use the same encoding', () {
    test('genres.list', () async {
      await client.genres.list(
        includeItemTypes: const [
          JellyfinItemKind.musicAlbum,
          JellyfinItemKind.audio
        ],
        fields: const [JellyfinItemField.overview, JellyfinItemField.genres],
        sortBy: const [JellyfinSortField.sortName],
      );
      expect(adapter.query['includeItemTypes'], ['MusicAlbum', 'Audio']);
      expect(adapter.query['fields'], ['Overview', 'Genres']);
      expect(adapter.query['sortBy'], ['SortName']);
    });

    test('musicGenres.list', () async {
      await client.musicGenres.list(
        includeItemTypes: const [
          JellyfinItemKind.musicAlbum,
          JellyfinItemKind.audio
        ],
      );
      expect(adapter.query['includeItemTypes'], ['MusicAlbum', 'Audio']);
    });

    test('studios.list', () async {
      await client.studios.list(
        includeItemTypes: const [
          JellyfinItemKind.movie,
          JellyfinItemKind.series
        ],
        enableImageTypes: const ['Primary', 'Thumb'],
      );
      expect(adapter.query['includeItemTypes'], ['Movie', 'Series']);
      expect(adapter.query['enableImageTypes'], ['Primary', 'Thumb']);
    });

    test('persons.list', () async {
      await client.persons.list(
        personTypes: const ['Actor', 'Director'],
        excludePersonTypes: const ['Writer'],
      );
      expect(adapter.query['personTypes'], ['Actor', 'Director']);
      expect(adapter.query['excludePersonTypes'], ['Writer']);
    });

    test('persons.list scoping and alphabet params', () async {
      await client.persons.list(
        parentId: 'lib-1',
        startIndex: 20,
        nameStartsWith: 'B',
        nameStartsWithOrGreater: 'A',
        nameLessThan: 'C',
        personTypes: const ['Artist'],
      );
      expect(adapter.path, '/Persons');
      expect(adapter.query['parentId'], ['lib-1']);
      expect(adapter.query['startIndex'], ['20']);
      expect(adapter.query['nameStartsWith'], ['B']);
      expect(adapter.query['nameStartsWithOrGreater'], ['A']);
      expect(adapter.query['nameLessThan'], ['C']);
      expect(adapter.query['personTypes'], ['Artist']);
    });

    test('persons.list omits scoping params when unset', () async {
      await client.persons.list();
      for (final k in const [
        'parentId',
        'startIndex',
        'nameStartsWith',
        'nameStartsWithOrGreater',
        'nameLessThan',
      ]) {
        expect(adapter.query.containsKey(k), isFalse, reason: k);
      }
    });

    test('years.list', () async {
      await client.years.list(
        mediaTypes: const [JellyfinMediaType.video, JellyfinMediaType.audio],
        sortBy: const [JellyfinSortField.productionYear],
      );
      expect(adapter.query['mediaTypes'], ['Video', 'Audio']);
      expect(adapter.query['sortBy'], ['ProductionYear']);
    });

    test('trailers.list', () async {
      await client.trailers.list(genreIds: const ['g1', 'g2']);
      expect(adapter.query['genreIds'], ['g1', 'g2']);
    });

    test('search.hints', () async {
      await client.search.hints(
        query: 'bowie',
        includeItemTypes: const [
          JellyfinItemKind.audio,
          JellyfinItemKind.musicAlbum
        ],
        mediaTypes: const [JellyfinMediaType.audio],
      );
      expect(adapter.path, '/Search/Hints');
      expect(adapter.query['includeItemTypes'], ['Audio', 'MusicAlbum']);
      expect(adapter.query['mediaTypes'], ['Audio']);
    });

    test('filter.facets', () async {
      await client.filter.facets(
        includeItemTypes: const [
          JellyfinItemKind.audio,
          JellyfinItemKind.musicAlbum
        ],
      );
      expect(adapter.path, '/Items/Filters2');
      expect(adapter.query['includeItemTypes'], ['Audio', 'MusicAlbum']);
    });

    test('suggestions.list', () async {
      await client.suggestions.list(
        mediaType: const ['Audio', 'Video'],
        type: const ['MusicAlbum', 'Movie'],
      );
      expect(adapter.path, '/Items/Suggestions');
      expect(adapter.query['mediaType'], ['Audio', 'Video']);
      expect(adapter.query['type'], ['MusicAlbum', 'Movie']);
    });

    test('userViews.list', () async {
      await client.userViews.list(presetViews: const ['music', 'movies']);
      expect(adapter.query['presetViews'], ['music', 'movies']);
    });
  });

  group('JellyfinPlaylistsApi.items', () {
    test('sends no fields param by default', () async {
      await client.playlists.items(playlistId: 'pl-1');
      expect(adapter.path, '/Playlists/pl-1/Items');
      expect(adapter.query.containsKey('fields'), isFalse);
    });

    test('musicFields is opt-in and repeated', () async {
      await client.playlists.items(
        playlistId: 'pl-1',
        fields: JellyfinItemsApi.musicFields,
      );
      expect(adapter.query['fields'], JellyfinItemsApi.musicFields);
    });
  });
}
