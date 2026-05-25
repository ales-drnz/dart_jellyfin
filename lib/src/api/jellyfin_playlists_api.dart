// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Playlists/*`.
class JellyfinPlaylistsApi {
  final JellyfinConnection _http;

  JellyfinPlaylistsApi(this._http);

  /// Create a new playlist for the current user.
  ///
  /// [mediaType] is one of `'Audio' | 'Video' | 'Photo' | 'Book'` —
  /// scopes which items can be added later. Pass `'Audio'` for music.
  Future<JellyfinItem> create({
    required String name,
    String mediaType = 'Audio',
    List<String> itemIds = const [],
    bool isPublic = false,
  }) async {
    final userId = _requireUser();
    final res = await _http.request<Map<String, dynamic>>(
      '/Playlists',
      method: 'POST',
      data: {
        'Name': name,
        'UserId': userId,
        'MediaType': mediaType,
        'IsPublic': isPublic,
        if (itemIds.isNotEmpty) 'Ids': itemIds,
      },
    );
    final data = res.data;
    if (data == null) {
      throw const JellyfinException(
        'Playlist create returned no body',
        type: JellyfinErrorType.parse,
      );
    }
    // POST returns `{ Id: "..." }` — fetch the playlist as an item so
    // the caller gets a full JellyfinItem to display.
    final id = (data['Id'] as String?) ?? '';
    return JellyfinItem(
      id: id,
      name: name,
      type: JellyfinItemKind.playlist,
      mediaType: mediaType,
      albumArtists: const [],
      artists: const [],
      artistItems: const [],
      mediaSources: const [],
      mediaStreams: const [],
      isFolder: true,
      hasLyrics: false,
      genres: const [],
      tags: const [],
      imageTags: const {},
      backdropImageTags: const [],
      imageBlurHashes: const {},
      raw: data,
    );
  }

  /// Items in a playlist (`/Playlists/{id}/Items`).
  Future<JellyfinQueryResult<JellyfinItem>> items({
    required String playlistId,
    int startIndex = 0,
    int? limit,
    List<String> fields = JellyfinItemsApiFieldsAdapter.musicFields,
  }) async {
    final userId = _requireUser();
    final qp = <String, dynamic>{
      'userId': userId,
      'startIndex': startIndex,
      if (fields.isNotEmpty) 'fields': fields.join(','),
    };
    if (limit != null) qp['limit'] = limit;
    final res = await _http.request<Map<String, dynamic>>(
      '/Playlists/$playlistId/Items',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// Append items to a playlist.
  Future<void> addItems({
    required String playlistId,
    required List<String> itemIds,
  }) async {
    if (itemIds.isEmpty) return;
    final userId = _requireUser();
    await _http.request<void>(
      '/Playlists/$playlistId/Items',
      method: 'POST',
      queryParameters: {
        'ids': itemIds.join(','),
        'userId': userId,
      },
    );
  }

  /// Remove items by their playlist entry id (NOT by underlying item id).
  /// Get the entry ids from `items(...).raw['PlaylistItemId']`.
  Future<void> removeItems({
    required String playlistId,
    required List<String> entryIds,
  }) async {
    if (entryIds.isEmpty) return;
    await _http.request<void>(
      '/Playlists/$playlistId/Items',
      method: 'DELETE',
      queryParameters: {'entryIds': entryIds.join(',')},
    );
  }

  /// Delete the playlist itself — Jellyfin treats playlists as items, so
  /// it's `DELETE /Items/{id}`.
  Future<void> delete(String playlistId) async {
    await _http.request<void>('/Items/$playlistId', method: 'DELETE');
  }

  /// Rename a playlist.
  Future<void> rename({
    required String playlistId,
    required String name,
  }) async {
    // /Playlists/{id} POST with a new name updates the playlist.
    await _http.request<void>(
      '/Playlists/$playlistId',
      method: 'POST',
      data: {'Name': name},
    );
  }

  /// `GET /Playlists/{playlistId}` — fetch the playlist's metadata
  /// (name, owner, public/private flag, item count).
  Future<JellyfinItem?> byId(String playlistId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Playlists/$playlistId',
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `POST /Playlists/{playlistId}` — update playlist metadata
  /// (name, IsPublic flag, ids order). Accepts any subset of the
  /// fields the server understands.
  Future<void> update({
    required String playlistId,
    String? name,
    bool? isPublic,
    List<String>? ids,
    Map<String, dynamic> extra = const {},
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'Name': name,
      if (isPublic != null) 'IsPublic': isPublic,
      if (ids != null) 'Ids': ids,
      ...extra,
    };
    await _http.request<void>(
      '/Playlists/$playlistId',
      method: 'POST',
      data: body,
    );
  }

  /// `POST /Playlists/{playlistId}/Items/{itemId}/Move/{newIndex}` —
  /// reorder one item. [playlistItemId] is the playlist entry id
  /// (NOT the underlying item id), available on the `PlaylistItemId`
  /// field of each entry from [items].
  Future<void> moveItem({
    required String playlistId,
    required String playlistItemId,
    required int newIndex,
  }) async {
    await _http.request<void>(
      '/Playlists/$playlistId/Items/$playlistItemId/Move/$newIndex',
      method: 'POST',
    );
  }

  /// `GET /Playlists/{playlistId}/Users` — list users with access to
  /// a shared playlist. Returned as raw maps (`UserId`, `UserName`,
  /// `CanEdit`).
  Future<List<Map<String, dynamic>>> users(String playlistId) async {
    final res = await _http.request<List<dynamic>>(
      '/Playlists/$playlistId/Users',
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `GET /Playlists/{playlistId}/Users/{userId}` — one user's
  /// access record for a playlist.
  Future<Map<String, dynamic>?> userAccess({
    required String playlistId,
    required String userId,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Playlists/$playlistId/Users/$userId',
    );
    return res.data;
  }

  /// `POST /Playlists/{playlistId}/Users/{userId}?canEdit={bool}` —
  /// grant or update a user's access to a shared playlist.
  Future<void> setUserAccess({
    required String playlistId,
    required String userId,
    required bool canEdit,
  }) async {
    await _http.request<void>(
      '/Playlists/$playlistId/Users/$userId',
      method: 'POST',
      queryParameters: {'canEdit': canEdit},
    );
  }

  /// `DELETE /Playlists/{playlistId}/Users/{userId}` — revoke a
  /// user's access.
  Future<void> removeUserAccess({
    required String playlistId,
    required String userId,
  }) async {
    await _http.request<void>(
      '/Playlists/$playlistId/Users/$userId',
      method: 'DELETE',
    );
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

/// Tiny adapter so this file can reference the music-fields constant
/// without forming a circular import with [jellyfin_items_api.dart].
/// Keeps both file dependency directions clean.
abstract final class JellyfinItemsApiFieldsAdapter {
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
}
