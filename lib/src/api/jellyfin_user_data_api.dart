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
  Future<JellyfinUserData> markFavorite(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserFavoriteItems/$itemId',
      method: 'POST',
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Remove favourite mark.
  Future<JellyfinUserData> unmarkFavorite(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserFavoriteItems/$itemId',
      method: 'DELETE',
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Convenience wrapper — calls [markFavorite] or [unmarkFavorite] based on [isFavorite].
  Future<JellyfinUserData> setFavorite(String itemId, bool isFavorite) =>
      isFavorite ? markFavorite(itemId) : unmarkFavorite(itemId);

  /// Mark an item as played.
  Future<JellyfinUserData> markPlayed(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserPlayedItems/$itemId',
      method: 'POST',
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Remove played mark.
  Future<JellyfinUserData> markUnplayed(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserPlayedItems/$itemId',
      method: 'DELETE',
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Fetch the current user's data for an item (favourite flag,
  /// playback position, play count, last-played date).
  Future<JellyfinUserData> get(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/UserData',
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// `POST /UserItems/{itemId}/Rating?likes={bool}` — update the
  /// current user's rating (like/dislike) on an item.
  Future<JellyfinUserData> rate({
    required String itemId,
    required bool likes,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/Rating',
      method: 'POST',
      queryParameters: {'likes': likes},
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// `DELETE /UserItems/{itemId}/Rating` — clear the user's
  /// like/dislike on an item.
  Future<JellyfinUserData> clearRating(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/UserItems/$itemId/Rating',
      method: 'DELETE',
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }

  /// Update the user-data record on an item (e.g. set
  /// `playbackPositionTicks` from another device).
  Future<JellyfinUserData> update({
    required String itemId,
    JellyfinUserData? userData,
    Map<String, dynamic>? raw,
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
    );
    return JellyfinUserData.fromJson(res.data ?? const {});
  }
}
