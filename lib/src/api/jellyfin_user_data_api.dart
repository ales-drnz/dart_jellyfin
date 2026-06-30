// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// Favourites and played flags, plus the unified user-data record.
///
/// Jellyfin 10.11 collapsed the legacy per-user routes
/// (`/Users/{userId}/FavoriteItems/{itemId}`, `/Users/{userId}/PlayedItems/{itemId}`)
/// onto flat paths that pick the user from the access token:
///
///   POST/DELETE `/UserFavoriteItems/{itemId}`
///   POST/DELETE `/UserPlayedItems/{itemId}`
///
/// The wrappers below speak the new shape. Older servers (≤10.9) used
/// the user-scoped form; if you need that compatibility, drop down to
/// the escape hatch.
class JellyfinUserDataApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinUserDataApi(this._http);

  /// Mark an item as favourite.
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> markFavorite(String itemId, {String? userId}) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserFavoriteItems/$itemId',
      method: 'POST',
      queryParameters: _userQuery(userId),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Remove favourite mark.
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> unmarkFavorite(
    String itemId, {
    String? userId,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserFavoriteItems/$itemId',
      method: 'DELETE',
      queryParameters: _userQuery(userId),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Convenience wrapper — calls [markFavorite] or [unmarkFavorite] based on
  /// [isFavorite]. [userId] is threaded through to the underlying call.
  Future<JellyfinUserData> setFavorite(
    String itemId,
    bool isFavorite, {
    String? userId,
  }) =>
      isFavorite
          ? markFavorite(itemId, userId: userId)
          : unmarkFavorite(itemId, userId: userId);

  /// Mark an item as played.
  ///
  /// [datePlayed] backfills when the item was watched (e.g. when syncing from
  /// another device); the server uses the current time when omitted.
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> markPlayed(
    String itemId, {
    DateTime? datePlayed,
    String? userId,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserPlayedItems/$itemId',
      method: 'POST',
      queryParameters: _userQuery(
        userId,
        extra: datePlayed == null
            ? null
            : {'datePlayed': datePlayed.toUtc().toIso8601String()},
      ),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Remove played mark.
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> markUnplayed(String itemId, {String? userId}) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserPlayedItems/$itemId',
      method: 'DELETE',
      queryParameters: _userQuery(userId),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Fetch the current user's data for an item (favourite flag,
  /// playback position, play count, last-played date).
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> get(String itemId, {String? userId}) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/UserData',
      queryParameters: _userQuery(userId),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// `POST /UserItems/{itemId}/Rating?likes={bool}` — update the
  /// current user's rating (like/dislike) on an item.
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> rate({
    required String itemId,
    required bool likes,
    String? userId,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/Rating',
      method: 'POST',
      queryParameters: _userQuery(userId, extra: {'likes': likes}),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// `DELETE /UserItems/{itemId}/Rating` — clear the user's
  /// like/dislike on an item.
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> clearRating(String itemId, {String? userId}) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/Rating',
      method: 'DELETE',
      queryParameters: _userQuery(userId),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Update the user-data record on an item (e.g. set
  /// `playbackPositionTicks` from another device).
  ///
  /// [userId] targets another user's data (admin token only); defaults to
  /// the token's own user when omitted.
  Future<JellyfinUserData> update({
    required String itemId,
    JellyfinUserData? userData,
    Map<String, dynamic>? raw,
    String? userId,
  }) async {
    final body = raw ??
        {
          if (userData?.playbackPositionTicks != null)
            'PlaybackPositionTicks': userData!.playbackPositionTicks,
          if (userData?.playCount != null) 'PlayCount': userData!.playCount,
          'IsFavorite': userData?.isFavorite ?? false,
          if (userData?.likes != null) 'Likes': userData!.likes,
          if (userData?.lastPlayedDate != null)
            'LastPlayedDate':
                userData!.lastPlayedDate!.toUtc().toIso8601String(),
          'Played': userData?.played ?? false,
        };
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/UserData',
      method: 'POST',
      data: body,
      queryParameters: _userQuery(userId),
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Builds the `userId` query map shared by every method, defaulting to the
  /// connection's own user when [userId] is null, and merging any [extra]
  /// per-call params (e.g. `likes`, `datePlayed`). Returns `null` when there
  /// is nothing to send.
  Map<String, dynamic>? _userQuery(
    String? userId, {
    Map<String, dynamic>? extra,
  }) {
    final uid = userId ?? _http.userId;
    final qp = <String, dynamic>{
      if (uid != null) 'userId': uid,
      ...?extra,
    };
    return qp.isEmpty ? null : qp;
  }
}
