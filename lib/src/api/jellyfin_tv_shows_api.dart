// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Shows/*` — TV-series-specific browsing.
///
/// Wraps the `TvShows` OpenAPI tag (4 operations). Generic item
/// queries live on [JellyfinItemsApi]; this sub-API only handles the
/// four shapes that need a series-aware backend (episode list per
/// season, season list per series, "Next Up", "Upcoming").
class JellyfinTvShowsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinTvShowsApi(this._http);

  /// `/Shows/{seriesId}/Episodes` — episodes of a series, optionally
  /// scoped to a single season (by number or by season item id).
  Future<JellyfinQueryResult<JellyfinItem>> episodes({
    required String seriesId,
    int? season,
    String? seasonId,
    bool? isMissing,
    String? adjacentTo,
    String? startItemId,
    int? startIndex,
    int? limit,
    List<String> fields = const [],
    List<String> sortBy = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, dynamic>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (season != null) qp['season'] = season;
    if (seasonId != null) qp['seasonId'] = seasonId;
    if (isMissing != null) qp['isMissing'] = isMissing;
    if (adjacentTo != null) qp['adjacentTo'] = adjacentTo;
    if (startItemId != null) qp['startItemId'] = startItemId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (sortBy.isNotEmpty) qp['sortBy'] = sortBy.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

    final res = await _http.request<Map<String, dynamic>>(
      '/Shows/$seriesId/Episodes',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `/Shows/{seriesId}/Seasons` — seasons of a series.
  Future<JellyfinQueryResult<JellyfinItem>> seasons({
    required String seriesId,
    bool? isSpecialSeason,
    bool? isMissing,
    String? adjacentTo,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, dynamic>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (isSpecialSeason != null) qp['isSpecialSeason'] = isSpecialSeason;
    if (isMissing != null) qp['isMissing'] = isMissing;
    if (adjacentTo != null) qp['adjacentTo'] = adjacentTo;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

    final res = await _http.request<Map<String, dynamic>>(
      '/Shows/$seriesId/Seasons',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `/Shows/NextUp` — server-curated "what to watch next" episodes.
  Future<JellyfinQueryResult<JellyfinItem>> nextUp({
    String? seriesId,
    String? parentId,
    int? startIndex,
    int? limit,
    List<String> fields = const [],
    String? nextUpDateCutoff,
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool enableTotalRecordCount = true,
    bool disableFirstEpisode = false,
    bool enableResumable = true,
    bool enableRewatching = false,
  }) async {
    final qp = <String, dynamic>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      'enableTotalRecordCount': enableTotalRecordCount,
      'disableFirstEpisode': disableFirstEpisode,
      'enableResumable': enableResumable,
      'enableRewatching': enableRewatching,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (seriesId != null) qp['seriesId'] = seriesId;
    if (parentId != null) qp['parentId'] = parentId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (nextUpDateCutoff != null) qp['nextUpDateCutoff'] = nextUpDateCutoff;
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

    final res = await _http.request<Map<String, dynamic>>(
      '/Shows/NextUp',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `/Shows/Upcoming` — episodes whose premiere date is in the future.
  Future<JellyfinQueryResult<JellyfinItem>> upcoming({
    String? parentId,
    int? startIndex,
    int? limit,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, dynamic>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
    };
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    if (parentId != null) qp['parentId'] = parentId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    if (imageTypeLimit != null) qp['imageTypeLimit'] = imageTypeLimit;
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes.join(',');
    }

    final res = await _http.request<Map<String, dynamic>>(
      '/Shows/Upcoming',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }
}
