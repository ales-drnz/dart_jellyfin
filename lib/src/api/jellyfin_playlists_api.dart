// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_server_models.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_items_api.dart';

/// `/Playlists/*`.
///
/// Jellyfin 12.2 loses a rename that reaches a playlist within about half
/// a second of a change to its entries, and still answers success (see
/// [rename]). This class remembers when it last changed each playlist's
/// entries and holds [rename] / [update] back until [renameSettle] has
/// passed since; [delete] waits too. Only writes made through this
/// instance are known: a change from another client, or another
/// [JellyfinClient], is not.
class JellyfinPlaylistsApi {
  /// How long after an entry write [rename], [update] and [delete] wait
  /// before they are sent. Jellyfin 12.2 lost every rename sent at once
  /// after an add and none sent 0.5 s or more later; this keeps a margin.
  static const Duration renameSettle = Duration(seconds: 1);

  final JellyfinConnection _http;

  /// Monotonic clock for [_entryWrites].
  final Stopwatch _clock = Stopwatch()..start();

  /// Playlist id → [_clock] time of the last entry write answered.
  final Map<String, Duration> _entryWrites = {};

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinPlaylistsApi(this._http);

  void _wroteEntries(String playlistId) =>
      _entryWrites[playlistId] = _clock.elapsed;

  /// Waits out what is left of [renameSettle] since the last entry write
  /// to [playlistId]; returns at once when there was none.
  Future<void> _settle(String playlistId) async {
    final at = _entryWrites[playlistId];
    if (at == null) return;
    final left = renameSettle - (_clock.elapsed - at);
    if (left > Duration.zero) await Future<void>.delayed(left);
    // Another entry write may have landed while this one waited.
    if (_entryWrites[playlistId] == at) _entryWrites.remove(playlistId);
  }

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
    final userId = _http.requireUserId();
    final res = await _http.request<Map<String, Object?>>(
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
    if (itemIds.isNotEmpty) _wroteEntries(id);
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
  ///
  /// [fields] defaults to the empty list — the server's own projection.
  /// Playlists hold video as readily as audio, so pass
  /// [JellyfinItemsApi.musicFields] when you want the music set.
  Future<JellyfinQueryResult<JellyfinItem>> items({
    required String playlistId,
    int startIndex = 0,
    int? limit,
    List<JellyfinItemField> fields = const [],
  }) async {
    final userId = _http.requireUserId();
    final qp = <String, Object?>{
      'userId': userId,
      'startIndex': startIndex,
      if (fields.isNotEmpty) 'fields': fields,
    };
    if (limit != null) qp['limit'] = limit;
    return _http.requestJson(
      '/Playlists/$playlistId/Items',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// Append items to a playlist.
  Future<void> addItems({
    required String playlistId,
    required List<String> itemIds,
  }) async {
    if (itemIds.isEmpty) return;
    final userId = _http.requireUserId();
    await _http.request<void>(
      '/Playlists/$playlistId/Items',
      method: 'POST',
      queryParameters: {
        'ids': itemIds,
        'userId': userId,
      },
    );
    _wroteEntries(playlistId);
  }

  /// Remove entries by their [JellyfinItem.playlistItemId].
  ///
  /// On Jellyfin 12.2 an entry id is the item id, so this removes *every*
  /// copy of a track listed more than once (verified) — the server cannot
  /// remove a single copy.
  Future<void> removeItems({
    required String playlistId,
    required List<JellyfinPlaylistEntryId> entryIds,
  }) async {
    if (entryIds.isEmpty) return;
    await _http.request<void>(
      '/Playlists/$playlistId/Items',
      method: 'DELETE',
      queryParameters: {'entryIds': entryIds},
    );
    _wroteEntries(playlistId);
  }

  /// Delete the playlist itself — Jellyfin treats playlists as items, so
  /// it's `DELETE /Items/{id}`.
  ///
  /// Waits like [rename] after a recent entry write by this instance:
  /// Jellyfin 12.2 deletes the playlist but then saves the pending entry
  /// change, which writes its `playlist.xml` back to disk, an orphan a
  /// later library scan may bring back.
  Future<void> delete({
    required String playlistId,
  }) async {
    await _settle(playlistId);
    await _http.request<void>('/Items/$playlistId', method: 'DELETE');
    _entryWrites.remove(playlistId);
  }

  /// Rename a playlist.
  ///
  /// Jellyfin 12.2 loses a rename that arrives within about half a second
  /// of a write that changed the playlist's entries — [create] with
  /// `itemIds`, [addItems] — and still answers success: the server saves
  /// the entry change to the playlist file after answering, over the new
  /// name. A read right after the rename still shows the new name; the
  /// old one returns a moment later. Measured: 10 of 10 renames sent at
  /// once after an add were lost, none of 16 with a gap of 0.5–4 s, none
  /// sent on their own.
  ///
  /// So when this instance changed the playlist's entries — [create] with
  /// `itemIds`, [addItems], [removeItems], [moveItem], [update] with
  /// `ids` — less than [renameSettle] ago, the rename waits out the rest
  /// first; otherwise it is sent at once. An entry change made by another
  /// client is not known here and can still win.
  Future<void> rename({
    required String playlistId,
    required String name,
  }) async {
    await _settle(playlistId);
    // /Playlists/{id} POST with a new name updates the playlist.
    await _http.request<void>(
      '/Playlists/$playlistId',
      method: 'POST',
      data: {'Name': name},
    );
  }

  /// `GET /Items/{playlistId}` — fetch the playlist's item metadata
  /// (name, type, child/item count, etc.).
  ///
  /// Jellyfin treats playlists as items, so the full [JellyfinItem] is
  /// served from `/Items/{id}` (a `BaseItemDto`). The `/Playlists/{id}`
  /// endpoint returns a `PlaylistDto` (only `OpenAccess`, `Shares`,
  /// `ItemIds`) and carries none of these fields, so it is not used here.
  Future<JellyfinItem?> byId({
    required String playlistId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/Items/$playlistId',
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `POST /Playlists/{playlistId}` — update playlist metadata
  /// (name, IsPublic flag, ids order). Accepts any subset of the
  /// fields the server understands.
  ///
  /// Waits like [rename] after a recent entry write by this instance, so
  /// a [name] is not lost; [ids] replaces the entries and counts as one.
  Future<void> update({
    required String playlistId,
    String? name,
    bool? isPublic,
    List<String>? ids,
    Map<String, Object?> extra = const {},
  }) async {
    final body = <String, Object?>{
      if (name != null) 'Name': name,
      if (isPublic != null) 'IsPublic': isPublic,
      if (ids != null) 'Ids': ids,
      ...extra,
    };
    await _settle(playlistId);
    await _http.request<void>(
      '/Playlists/$playlistId',
      method: 'POST',
      data: body,
    );
    if (ids != null) _wroteEntries(playlistId);
  }

  /// `POST /Playlists/{playlistId}/Items/{itemId}/Move/{newIndex}` —
  /// reorder one entry. [playlistItemId] is the entry's
  /// [JellyfinItem.playlistItemId] — on 12.2 the item id, so with a track
  /// listed twice the first copy moves (verified).
  ///
  /// A move is an entry write: a [rename] right after it waits (see
  /// [renameSettle]).
  Future<void> moveItem({
    required String playlistId,
    required JellyfinPlaylistEntryId playlistItemId,
    required int newIndex,
  }) async {
    await _http.request<void>(
      '/Playlists/$playlistId/Items/$playlistItemId/Move/$newIndex',
      method: 'POST',
    );
    _wroteEntries(playlistId);
  }

  /// `GET /Playlists/{playlistId}/Users` — list users with access to
  /// a shared playlist, as [JellyfinPlaylistUserPermission]s (user id and
  /// `canEdit`); resolve display names separately via the users API if
  /// needed.
  Future<List<JellyfinPlaylistUserPermission>> users({
    required String playlistId,
  }) =>
      _http.requestJson(
        '/Playlists/$playlistId/Users',
        listOf(JellyfinPlaylistUserPermission.fromJson),
      );

  /// `GET /Playlists/{playlistId}/Users/{userId}` — one user's
  /// access record for a playlist.
  Future<Map<String, Object?>?> userAccess({
    required String playlistId,
    required String userId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/Playlists/$playlistId/Users/$userId',
    );
    return res.data;
  }

  /// `POST /Playlists/{playlistId}/Users/{userId}` — grant or update a
  /// user's access to a shared playlist. The `CanEdit` flag is sent in the
  /// JSON body (`UpdatePlaylistUserDto`), not as a query parameter.
  Future<void> setUserAccess({
    required String playlistId,
    required String userId,
    required bool canEdit,
  }) async {
    await _http.request<void>(
      '/Playlists/$playlistId/Users/$userId',
      method: 'POST',
      data: {'CanEdit': canEdit},
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
}
