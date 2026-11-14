// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';

/// `/Channels` — plugin-provided IPTV / online-source channels.
///
/// Wraps the `Channels` OpenAPI tag (5 operations). Not to be
/// confused with Live TV channels: these are content sources added
/// by server plugins (YouTube, podcast feeds, etc.). Each channel
/// surfaces a tree of items the user can browse like a regular
/// library.
///
/// {@category Library}
class JellyfinChannelsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinChannelsApi(this._http);

  /// `GET /Channels` — every channel the server knows about.
  Future<JellyfinQueryResult<JellyfinItem>> list({
    int? startIndex,
    int? limit,
    bool? supportsLatestItems,
    bool? supportsMediaDeletion,
    bool? isFavorite,
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'startIndex': ?startIndex,
      'limit': ?limit,
    };
    if (supportsLatestItems != null) {
      qp['supportsLatestItems'] = supportsLatestItems;
    }
    if (supportsMediaDeletion != null) {
      qp['supportsMediaDeletion'] = supportsMediaDeletion;
    }
    if (isFavorite != null) qp['isFavorite'] = isFavorite;

    return _http.requestJson(
      '/Channels',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Channels/{channelId}/Items` — items inside a channel,
  /// optionally scoped to a sub-folder by [folderId].
  Future<JellyfinQueryResult<JellyfinItem>> items({
    required String channelId,
    String? folderId,
    int? startIndex,
    int? limit,
    List<JellyfinSortField> sortBy = const [],
    bool descending = false,
    List<JellyfinItemFilter> filters = const [],
    List<JellyfinItemField> fields = const [],
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'folderId': ?folderId,
      'startIndex': ?startIndex,
      'limit': ?limit,
    };
    if (sortBy.isNotEmpty) {
      qp['sortBy'] = sortBy;
      qp['sortOrder'] = descending ? 'Descending' : 'Ascending';
    }
    if (filters.isNotEmpty) qp['filters'] = filters;
    if (fields.isNotEmpty) qp['fields'] = fields;

    return _http.requestJson(
      '/Channels/$channelId/Items',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Channels/Items/Latest` — latest items across all channels.
  Future<JellyfinQueryResult<JellyfinItem>> latest({
    int? startIndex,
    int? limit,
    List<String> channelIds = const [],
    List<JellyfinItemFilter> filters = const [],
    List<JellyfinItemField> fields = const [],
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'startIndex': ?startIndex,
      'limit': ?limit,
      if (channelIds.isNotEmpty) 'channelIds': channelIds,
      if (filters.isNotEmpty) 'filters': filters,
      if (fields.isNotEmpty) 'fields': fields,
    };

    return _http.requestJson(
      '/Channels/Items/Latest',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /Channels/{channelId}/Features` — feature flags for one
  /// channel (supports search, item sort, deletion, etc.).
  Future<JellyfinChannelFeatures> features({required String channelId}) =>
      _http.requestJson(
        '/Channels/$channelId/Features',
        objectOrEmptyOf(JellyfinChannelFeatures.fromJson),
      );

  /// `GET /Channels/Features` — feature flags for every channel.
  Future<List<JellyfinChannelFeatures>> allFeatures() => _http.requestJson(
    '/Channels/Features',
    listOf(JellyfinChannelFeatures.fromJson),
  );
}
