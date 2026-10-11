// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import 'jellyfin_artists_api.dart';
import 'jellyfin_filter_api.dart';

/// `/Items` — the backbone of Jellyfin browsing.
class JellyfinItemsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinItemsApi(this._http);

  /// The `fields` set for playing and inspecting tracks: media sources and
  /// streams (codec, bitrate, the stream to pick), overview, provider ids,
  /// path and the rest of [browseFields].
  ///
  /// It is the expensive one. Measured on Jellyfin 12.0, a track costs
  /// ~3.2 KB with it against ~1.2 KB with [browseFields], and a 500-track
  /// album page was 1.5 MB of JSON that took the server ~230 ms to build —
  /// `MediaSources` and `MediaStreams` are most of both. Use it where those
  /// fields are read (a queue, the track info sheet), not for grids.
  ///
  /// Opt in explicitly: `list(fields: JellyfinItemsApi.musicFields)`.
  /// It is not a default, because `/Items` also serves video and photo
  /// libraries, where these fields are cost without benefit.
  ///
  /// `AlbumPrimaryImageTag` is not here because it is not a field: the
  /// server sends it on every track whose album has a cover, whatever
  /// `fields` says (verified on 12.0). 0.2 listed it; the server ignored it.
  static const List<String> musicFields = [
    'Overview',
    'Genres',
    'MediaSources',
    'MediaStreams',
    'ProviderIds',
    'PrimaryImageAspectRatio',
    'SortName',
    'DateCreated',
    'ChildCount',
    'ParentId',
    'Path',
    'OriginalTitle',
  ];

  /// The light `fields` set for grids and lists of albums, artists,
  /// playlists and genres: genres, date added, child count (an album's
  /// tracks, an artist's albums), sort name and the cover's aspect ratio.
  /// No media sources, streams, path or overview.
  ///
  /// Image tags (`ImageTags`, `AlbumPrimaryImageTag`) need no field — they
  /// always come — so covers and their versions work with this set too.
  static const List<String> browseFields = [
    'Genres',
    'DateCreated',
    'ChildCount',
    'SortName',
    'PrimaryImageAspectRatio',
  ];

  /// Page through items.
  ///
  /// Pass [includeItemTypes] with values from [JellyfinItemKind] to
  /// scope the result (e.g. `['MusicAlbum']`, `['Audio']`,
  /// `['MusicArtist']`).
  ///
  /// [sortBy] accepts: `'SortName' | 'Album' | 'AlbumArtist' |
  /// 'Artist' | 'Random' | 'DateCreated' | 'CommunityRating' |
  /// 'PlayCount' | 'PremiereDate' | 'ProductionYear' | …`. It is only
  /// sent when non-empty, and [descending] travels with it — the server
  /// ignores a sort order that has no sort column to apply it to.
  ///
  /// Filters: pass [filters] like `['IsFavorite']`.
  ///
  /// The narrowing parameters split into id-based and name-based pairs:
  /// [genreIds] / [genres], [studioIds] / [studios],
  /// [albumIds] / [albums], [artistIds] / [artists]. Prefer the id form
  /// — ids come back from [JellyfinFilterApi.facets] and survive a
  /// rename; the name form matches on the stored string. Every one of
  /// them is a `List<String>`, and this wrapper does the encoding: never
  /// pre-join them.
  ///
  /// [fields] defaults to the empty list, which gives the server's own
  /// default projection. Pass [browseFields] for grids and lists, and
  /// [musicFields] where media sources are read (see their costs).
  ///
  /// [parentId] with [recursive] (the default) scopes albums and tracks to
  /// one library — but **not artists**: verified on Jellyfin 12.0 with two
  /// music libraries, `includeItemTypes: ['MusicArtist']` ignores
  /// `parentId` and answers the artists of every library, a silent
  /// widening. List one library's artists with
  /// [JellyfinArtistsApi.albumArtists] or [JellyfinArtistsApi.list], which
  /// do honour `parentId`.
  ///
  /// [enableTotalRecordCount] (default `true`) makes the server count the
  /// whole result set for [JellyfinQueryResult.totalRecordCount] — a second
  /// query on its side. Pass `false` when you page by "a short page is the
  /// last" and never show a total; `totalRecordCount` then reports only
  /// the items in the page.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    String? parentId,
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> mediaTypes = const [],
    List<String> sortBy = const [],
    bool descending = false,
    int startIndex = 0,
    int? limit,
    String? searchTerm,
    List<String> filters = const [],
    List<String> ids = const [],
    List<String> excludeItemIds = const [],
    List<String> genreIds = const [],
    List<String> genres = const [],
    List<String> artistIds = const [],
    List<String> artists = const [],
    List<String> albumArtistIds = const [],
    List<String> contributingArtistIds = const [],
    List<String> albumIds = const [],
    List<String> albums = const [],
    List<String> studioIds = const [],
    List<String> studios = const [],
    List<String> personIds = const [],
    List<String> tags = const [],
    List<String> officialRatings = const [],
    List<int> years = const [],
    String? nameStartsWith,
    bool? isFavorite,
    bool? isPlayed,
    List<String> fields = const [],
    bool recursive = true,
    bool enableImages = true,
    bool enableUserData = true,
    bool enableTotalRecordCount = true,
    int? imageTypeLimit,
  }) async {
    final qp = _narrowing(
      parentId: parentId,
      includeItemTypes: includeItemTypes,
      excludeItemTypes: excludeItemTypes,
      mediaTypes: mediaTypes,
      searchTerm: searchTerm,
      filters: filters,
      ids: ids,
      excludeItemIds: excludeItemIds,
      genreIds: genreIds,
      genres: genres,
      artistIds: artistIds,
      artists: artists,
      albumArtistIds: albumArtistIds,
      contributingArtistIds: contributingArtistIds,
      albumIds: albumIds,
      albums: albums,
      studioIds: studioIds,
      studios: studios,
      personIds: personIds,
      tags: tags,
      officialRatings: officialRatings,
      years: years,
      nameStartsWith: nameStartsWith,
      isFavorite: isFavorite,
      isPlayed: isPlayed,
      recursive: recursive,
      enableTotalRecordCount: enableTotalRecordCount,
    )
      ..['startIndex'] = startIndex
      ..['enableImages'] = enableImages
      ..['enableUserData'] = enableUserData;
    if (limit != null) qp['limit'] = limit;
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy;
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (fields.isNotEmpty) qp['fields'] = fields;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;

    return _http.requestJson(
      '/Items',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// How many items match — without transferring them.
  ///
  /// Sends `limit=0&enableTotalRecordCount=true`, so the server counts
  /// the match set and returns an empty page. Takes the same narrowing
  /// parameters as [list] (minus paging, sorting and field selection),
  /// so any query you can page you can also count.
  Future<int> count({
    String? parentId,
    List<String> includeItemTypes = const [],
    List<String> excludeItemTypes = const [],
    List<String> mediaTypes = const [],
    String? searchTerm,
    List<String> filters = const [],
    List<String> ids = const [],
    List<String> excludeItemIds = const [],
    List<String> genreIds = const [],
    List<String> genres = const [],
    List<String> artistIds = const [],
    List<String> artists = const [],
    List<String> albumArtistIds = const [],
    List<String> contributingArtistIds = const [],
    List<String> albumIds = const [],
    List<String> albums = const [],
    List<String> studioIds = const [],
    List<String> studios = const [],
    List<String> personIds = const [],
    List<String> tags = const [],
    List<String> officialRatings = const [],
    List<int> years = const [],
    String? nameStartsWith,
    bool? isFavorite,
    bool? isPlayed,
    bool recursive = true,
  }) async {
    final qp = _narrowing(
      parentId: parentId,
      includeItemTypes: includeItemTypes,
      excludeItemTypes: excludeItemTypes,
      mediaTypes: mediaTypes,
      searchTerm: searchTerm,
      filters: filters,
      ids: ids,
      excludeItemIds: excludeItemIds,
      genreIds: genreIds,
      genres: genres,
      artistIds: artistIds,
      artists: artists,
      albumArtistIds: albumArtistIds,
      contributingArtistIds: contributingArtistIds,
      albumIds: albumIds,
      albums: albums,
      studioIds: studioIds,
      studios: studios,
      personIds: personIds,
      tags: tags,
      officialRatings: officialRatings,
      years: years,
      nameStartsWith: nameStartsWith,
      isFavorite: isFavorite,
      isPlayed: isPlayed,
      recursive: recursive,
      enableTotalRecordCount: true,
    )
      ..['limit'] = 0
      ..['enableImages'] = false
      ..['enableUserData'] = false;

    final res = await _http.request<Map<String, Object?>>(
      '/Items',
      queryParameters: qp,
    );
    final raw = res.data;
    if (raw == null) return 0;
    final v = raw['TotalRecordCount'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Builds the `/Items` query parameters shared by [list] and [count].
  ///
  /// Lives in one place so the two can never drift apart: whatever
  /// narrows a page also narrows a count. List values are handed to the
  /// transport unjoined — see [JellyfinConnection.request].
  Map<String, Object?> _narrowing({
    required String? parentId,
    required List<String> includeItemTypes,
    required List<String> excludeItemTypes,
    required List<String> mediaTypes,
    required String? searchTerm,
    required List<String> filters,
    required List<String> ids,
    required List<String> excludeItemIds,
    required List<String> genreIds,
    required List<String> genres,
    required List<String> artistIds,
    required List<String> artists,
    required List<String> albumArtistIds,
    required List<String> contributingArtistIds,
    required List<String> albumIds,
    required List<String> albums,
    required List<String> studioIds,
    required List<String> studios,
    required List<String> personIds,
    required List<String> tags,
    required List<String> officialRatings,
    required List<int> years,
    required String? nameStartsWith,
    required bool? isFavorite,
    required bool? isPlayed,
    required bool recursive,
    required bool enableTotalRecordCount,
  }) {
    final qp = <String, Object?>{
      'userId': _http.requireUserId(),
      'recursive': recursive,
      'enableTotalRecordCount': enableTotalRecordCount,
    };
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes;
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes;
    }
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (filters.isNotEmpty) qp['filters'] = filters;
    if (ids.isNotEmpty) qp['ids'] = ids;
    if (excludeItemIds.isNotEmpty) qp['excludeItemIds'] = excludeItemIds;
    if (genreIds.isNotEmpty) qp['genreIds'] = genreIds;
    if (genres.isNotEmpty) qp['genres'] = genres;
    if (artistIds.isNotEmpty) qp['artistIds'] = artistIds;
    if (artists.isNotEmpty) qp['artists'] = artists;
    if (albumArtistIds.isNotEmpty) qp['albumArtistIds'] = albumArtistIds;
    if (contributingArtistIds.isNotEmpty) {
      qp['contributingArtistIds'] = contributingArtistIds;
    }
    if (albumIds.isNotEmpty) qp['albumIds'] = albumIds;
    if (albums.isNotEmpty) qp['albums'] = albums;
    if (studioIds.isNotEmpty) qp['studioIds'] = studioIds;
    if (studios.isNotEmpty) qp['studios'] = studios;
    if (personIds.isNotEmpty) qp['personIds'] = personIds;
    if (tags.isNotEmpty) qp['tags'] = tags;
    if (officialRatings.isNotEmpty) qp['officialRatings'] = officialRatings;
    if (years.isNotEmpty) qp['years'] = years;
    if (nameStartsWith != null) qp['nameStartsWith'] = nameStartsWith;
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (isPlayed != null) qp['isPlayed'] = isPlayed;
    return qp;
  }

  /// Single item by id. Returns null on 404.
  ///
  /// `GET /Items/{itemId}` always returns the full `BaseItemDto`; it has
  /// no `fields` parameter, so none is sent. Use [list] with
  /// `ids: [itemId]` if you need server-side field selection.
  Future<JellyfinItem?> byId(String itemId) async {
    final userId = _http.requireUserId();
    try {
      final res = await _http.request<Map<String, Object?>>(
        '/Items/$itemId',
        queryParameters: {
          'userId': userId,
        },
      );
      final data = res.data;
      if (data == null) return null;
      return JellyfinItem.fromJson(data);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
  }

  /// "Continue Listening / Watching" — items with playback position > 0.
  Future<JellyfinQueryResult<JellyfinItem>> resume({
    String? parentId,
    List<String> mediaTypes = const [],
    int startIndex = 0,
    int? limit,
  }) async {
    final userId = _http.requireUserId();
    final qp = <String, Object?>{
      'userId': userId,
      'startIndex': startIndex,
      'enableImages': true,
      'enableUserData': true,
    };
    if (limit != null) qp['limit'] = limit;
    if (parentId != null) qp['parentId'] = parentId;
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes;
    return _http.requestJson(
      '/UserItems/Resume',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Items/Root` — the user's root folder. Returned as a
  /// single [JellyfinItem]; treat it as the "Home" parent.
  Future<JellyfinItem?> root() async {
    final userId = _http.requireUserId();
    final res = await _http.request<Map<String, Object?>>(
      '/Items/Root',
      queryParameters: {'userId': userId},
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `GET /Items/{itemId}/Intros` — pre-roll items (intros/trailers
  /// the server schedules ahead of this item).
  Future<JellyfinQueryResult<JellyfinItem>> intros(String itemId) async {
    final userId = _http.requireUserId();
    return _http.requestJson(
      '/Items/$itemId/Intros',
      queryParameters: {'userId': userId},
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Items/{itemId}/LocalTrailers` — every local trailer file
  /// attached to the item (returned as a flat list).
  Future<List<JellyfinItem>> localTrailers(String itemId) async {
    final userId = _http.requireUserId();
    return _http.requestJson(
      '/Items/$itemId/LocalTrailers',
      queryParameters: {'userId': userId},
      listOf(JellyfinItem.fromJson),
    );
  }

  /// `POST /Items/{itemId}/Refresh` — trigger a metadata + image
  /// refresh on a single item. Admin / library editor.
  Future<void> refresh({
    required String itemId,
    String metadataRefreshMode = 'Default',
    String imageRefreshMode = 'Default',
    bool replaceAllMetadata = false,
    bool replaceAllImages = false,
    bool regenerateTrickplay = false,
  }) async {
    await _http.request<void>(
      '/Items/$itemId/Refresh',
      method: 'POST',
      queryParameters: {
        'metadataRefreshMode': metadataRefreshMode,
        'imageRefreshMode': imageRefreshMode,
        'replaceAllMetadata': replaceAllMetadata,
        'replaceAllImages': replaceAllImages,
        'regenerateTrickplay': regenerateTrickplay,
      },
    );
  }

  /// `POST /Items/{itemId}` — replace an item's metadata.
  /// [body] is the full `BaseItemDto` shape.
  Future<void> updateMetadata({
    required String itemId,
    required Map<String, Object?> body,
  }) async {
    await _http.request<void>(
      '/Items/$itemId',
      method: 'POST',
      data: body,
    );
  }

  /// `POST /Items/{itemId}/ContentType?contentType={type}` — change
  /// an item's content type (e.g. promote a folder to a series).
  Future<void> updateContentType({
    required String itemId,
    required String contentType,
  }) async {
    await _http.request<void>(
      '/Items/$itemId/ContentType',
      method: 'POST',
      queryParameters: {'contentType': contentType},
    );
  }

  /// `GET /Items/{itemId}/MetadataEditor` — info needed to populate
  /// the "Edit metadata" UI (available genres, tags, lock options).
  Future<Map<String, Object?>> metadataEditorInfo(String itemId) async {
    final res = await _http.request<Map<String, Object?>>(
      '/Items/$itemId/MetadataEditor',
    );
    return res.data ?? const {};
  }

  /// `GET /Items/{itemId}/Download` — direct download URL (signed
  /// with the session token) for the item's primary media file.
  /// Returns the URL string; pass to [JellyfinClient.requestBytes]
  /// or to a `Dio` for a streaming download.
  String downloadUrl(String itemId) {
    final base = _http.baseUrl;
    final token = _http.token ?? '';
    return '$base/Items/$itemId/Download?ApiKey=$token';
  }

  /// `GET /Items/{itemId}/File` — same as [downloadUrl] but the
  /// upstream operation is `GetFile`. Some clients honour
  /// `Content-Disposition` here for original filename.
  String fileUrl(String itemId) {
    final base = _http.baseUrl;
    final token = _http.token ?? '';
    return '$base/Items/$itemId/File?ApiKey=$token';
  }

  /// `GET /Items/{itemId}/SpecialFeatures` — bonus content (deleted
  /// scenes, behind-the-scenes, etc.) attached to a movie or show.
  Future<List<JellyfinItem>> specialFeatures(String itemId) async {
    final userId = _http.requireUserId();
    return _http.requestJson(
      '/Items/$itemId/SpecialFeatures',
      queryParameters: {'userId': userId},
      listOf(JellyfinItem.fromJson),
    );
  }

  /// Latest additions (`/Items/Latest`).
  ///
  /// [isPlayed] is an optional play-state filter: leave it `null` (the
  /// default) to get all recent items regardless of play state, `true`
  /// for only-played, or `false` for only-unplayed. Omitting it matches
  /// the server's `GetLatestMedia` default of returning every play state.
  Future<List<JellyfinItem>> latest({
    String? parentId,
    List<String> includeItemTypes = const [],
    int limit = 20,
    bool? isPlayed,
  }) async {
    final userId = _http.requireUserId();
    final qp = <String, Object?>{
      'userId': userId,
      'limit': limit,
    };
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes;
    }
    if (isPlayed != null) qp['isPlayed'] = isPlayed;
    return _http.requestJson(
      '/Items/Latest',
      queryParameters: qp,
      listOf(JellyfinItem.fromJson),
    );
  }
}
