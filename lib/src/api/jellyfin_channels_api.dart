// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Channels` — plugin-provided IPTV / online-source channels.
///
/// Wraps the `Channels` OpenAPI tag (5 operations). Not to be
/// confused with Live TV channels: these are content sources added
/// by server plugins (YouTube, podcast feeds, etc.). Each channel
/// surfaces a tree of items the user can browse like a regular
/// library.
class JellyfinChannelsApi {
  final JellyfinConnection _http;

  JellyfinChannelsApi(this._http);

  /// `GET /Channels` — every channel the server knows about.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    int? startIndex,
    int? limit,
    bool? supportsLatestItems,
    bool? supportsMediaDeletion,
    bool? isFavorite,
  }) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (supportsLatestItems != null) {
      qp['supportsLatestItems'] = supportsLatestItems;
    }
    if (supportsMediaDeletion != null) {
      qp['supportsMediaDeletion'] = supportsMediaDeletion;
    }
    if (isFavorite != null) qp['isFavorite'] = isFavorite;

    final res = await _http.request<Map<String, dynamic>>(
      '/Channels',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Channels/{channelId}/Items` — items inside a channel,
  /// optionally scoped to a sub-folder by [folderId].
  Future<JellyfinQueryResult<JellyfinItem>> items({
    required String channelId,
    String? folderId,
    int? startIndex,
    int? limit,
    List<String> sortBy = const [],
    bool descending = false,
    List<String> filters = const [],
    List<String> fields = const [],
  }) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (folderId != null) qp['folderId'] = folderId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy.join(',');
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');

    final res = await _http.request<Map<String, dynamic>>(
      '/Channels/$channelId/Items',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Channels/Items/Latest` — latest items across all channels.
  Future<JellyfinQueryResult<JellyfinItem>> latest({
    int? startIndex,
    int? limit,
    List<String> channelIds = const [],
    List<String> filters = const [],
    List<String> fields = const [],
  }) async {
    final qp = <String, dynamic>{};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (channelIds.isNotEmpty) qp['channelIds'] = channelIds.join(',');
    if (filters.isNotEmpty) qp['filters'] = filters.join(',');
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');

    final res = await _http.request<Map<String, dynamic>>(
      '/Channels/Items/Latest',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /Channels/{channelId}/Features` — feature flags for one
  /// channel (supports search, item sort, deletion, etc.).
  Future<Map<String, dynamic>> features(String channelId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Channels/$channelId/Features',
    );
    return res.data ?? const {};
  }

  /// `GET /Channels/Features` — feature flags for every channel,
  /// returned as a flat list of feature maps.
  Future<List<Map<String, dynamic>>> allFeatures() async {
    final res = await _http.request<List<dynamic>>('/Channels/Features');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
