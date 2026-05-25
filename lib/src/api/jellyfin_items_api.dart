// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Items` — the backbone of Jellyfin browsing.
class JellyfinItemsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinItemsApi(this._http);

  /// A reasonable default set of fields for music browsing — overview,
  /// genres, mediastreams, mediasources, …
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
    'AlbumPrimaryImageTag',
  ];

  /// Page through items.
  ///
  /// Pass [includeItemTypes] with values from [JellyfinItemKind] to
  /// scope the result (e.g. `['MusicAlbum']`, `['Audio']`,
  /// `['MusicArtist']`).
  ///
  /// `sortBy` accepts: `'SortName' | 'Album' | 'AlbumArtist' |
  /// 'Artist' | 'Random' | 'DateCreated' | 'CommunityRating' |
  /// 'PlayCount' | 'PremiereDate' | 'ProductionYear' | …`.
  ///
  /// Filters: pass [filters] like `['IsFavorite']`.
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
    String? genreIds,
    String? artistIds,
    String? albumIds,
    List<String> ids = const [],
    List<String> fields = musicFields,
    bool recursive = true,
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
  }) async {
    final userId = _requireUser();
    final qp = <String, dynamic>{
      'userId': userId,
      'startIndex': startIndex,
      'recursive': recursive,
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      'sortOrder': descending ? 'Descending' : 'Ascending',
    };
    if (limit != null) qp['limit'] = limit;
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (excludeItemTypes.isNotEmpty) {
      qp['excludeItemTypes'] = excludeItemTypes.join(',');
    }
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes.join(',');
    if (sortBy.isNotEmpty) qp['sortBy'] = sortBy.join(',');
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    if (genreIds != null) qp['genreIds'] = genreIds;
    if (artistIds != null) qp['artistIds'] = artistIds;
    if (albumIds != null) qp['albumIds'] = albumIds;
    if (ids.isNotEmpty) qp['ids'] = ids.join(',');
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;

    final res = await _http.request<Map<String, dynamic>>(
      '/Items',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// Cheaper alternative to [list] when you only need the count — sets
  /// `Limit=0&EnableTotalRecordCount=true` so the server returns just
  /// the total.
  Future<int> count({
    String? parentId,
    List<String> includeItemTypes = const [],
    List<String> filters = const [],
  }) async {
    final userId = _requireUser();
    final qp = <String, dynamic>{
      'userId': userId,
      'recursive': true,
      'limit': 0,
      'enableImages': false,
      'enableUserData': false,
      'enableTotalRecordCount': true,
    };
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    final res = await _http.request<Map<String, dynamic>>(
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

  /// Single item by id. Returns null on 404.
  Future<JellyfinItem?> byId(String itemId, {List<String> fields = musicFields}) async {
    final userId = _requireUser();
    try {
      final res = await _http.request<Map<String, dynamic>>(
        '/Items/$itemId',
        queryParameters: {
          'userId': userId,
          if (fields.isNotEmpty) 'fields': fields.join(','),
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
    final userId = _requireUser();
    final qp = <String, dynamic>{
      'userId': userId,
      'startIndex': startIndex,
      'enableImages': true,
      'enableUserData': true,
    };
    if (limit != null) qp['limit'] = limit;
    if (parentId != null) qp['parentId'] = parentId;
    if (mediaTypes.isNotEmpty) qp['mediaTypes'] = mediaTypes.join(',');
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/Resume',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Items/Root` — the user's root folder. Returned as a
  /// single [JellyfinItem]; treat it as the "Home" parent.
  Future<JellyfinItem?> root() async {
    final userId = _requireUser();
    final res = await _http.request<Map<String, dynamic>>(
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
    final userId = _requireUser();
    final res = await _http.request<Map<String, dynamic>>(
      '/Items/$itemId/Intros',
      queryParameters: {'userId': userId},
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Items/{itemId}/LocalTrailers` — every local trailer file
  /// attached to the item (returned as a flat list).
  Future<List<JellyfinItem>> localTrailers(String itemId) async {
    final userId = _requireUser();
    final res = await _http.request<List<dynamic>>(
      '/Items/$itemId/LocalTrailers',
      queryParameters: {'userId': userId},
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinItem.fromJson(e),
    ];
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
    required Map<String, dynamic> body,
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
  Future<Map<String, dynamic>> metadataEditorInfo(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
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
    return '$base/Items/$itemId/Download?api_key=$token';
  }

  /// `GET /Items/{itemId}/File` — same as [downloadUrl] but the
  /// upstream operation is `GetFile`. Some clients honour
  /// `Content-Disposition` here for original filename.
  String fileUrl(String itemId) {
    final base = _http.baseUrl;
    final token = _http.token ?? '';
    return '$base/Items/$itemId/File?api_key=$token';
  }

  /// `GET /Items/{itemId}/SpecialFeatures` — bonus content (deleted
  /// scenes, behind-the-scenes, etc.) attached to a movie or show.
  Future<List<JellyfinItem>> specialFeatures(String itemId) async {
    final userId = _requireUser();
    final res = await _http.request<List<dynamic>>(
      '/Items/$itemId/SpecialFeatures',
      queryParameters: {'userId': userId},
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinItem.fromJson(e),
    ];
  }

  /// Latest additions (`/Items/Latest`).
  Future<List<JellyfinItem>> latest({
    String? parentId,
    List<String> includeItemTypes = const [],
    int limit = 20,
    bool isPlayed = false,
  }) async {
    final userId = _requireUser();
    final qp = <String, dynamic>{
      'userId': userId,
      'limit': limit,
      'isPlayed': isPlayed,
    };
    if (parentId != null) qp['parentId'] = parentId;
    if (includeItemTypes.isNotEmpty) {
      qp['includeItemTypes'] = includeItemTypes.join(',');
    }
    final res = await _http.request<List<dynamic>>(
      '/Items/Latest',
      queryParameters: qp,
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinItem.fromJson(e),
    ];
  }

  String _requireUser() {
    final id = _http.userId;
    if (id == null) {
      throw const JellyfinException(
        'No user — call JellyfinClient.setSession() with a userId first.',
        type: JellyfinErrorType.state,
      );
    }
    return id;
  }
}
