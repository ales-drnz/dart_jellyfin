// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
/// @docImport 'jellyfin_items_api.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';

/// `/Shows/*` — TV-series-specific browsing.
///
/// Wraps the `TvShows` OpenAPI tag (4 operations). Generic item
/// queries live on [JellyfinItemsApi]; this sub-API only handles the
/// four shapes that need a series-aware backend (episode list per
/// season, season list per series, "Next Up", "Upcoming").
///
/// {@category TV, movies and live TV}
class JellyfinTvShowsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinTvShowsApi(this._http);

  /// `/Shows/{seriesId}/Episodes` — episodes of a series, optionally
  /// scoped to a single season (by number or by season item id).
  ///
  /// [sortBy] is a single `ItemSortBy` value (e.g. `'PremiereDate'`),
  /// not a list: this endpoint binds one enum, unlike the multi-column
  /// `sortBy` on [JellyfinItemsApi.list]. It also has no sort-order
  /// knob — pass `'Random'` for shuffled order, or reverse the returned
  /// page yourself.
  Future<JellyfinQueryResult<JellyfinItem>> episodes({
    required String seriesId,
    int? season,
    String? seasonId,
    bool? isMissing,
    String? adjacentTo,
    String? startItemId,
    int? startIndex,
    int? limit,
    List<JellyfinItemField> fields = const [],
    String? sortBy,
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, Object?>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      'userId': ?_http.userId,
      'season': ?season,
      'seasonId': ?seasonId,
      'isMissing': ?isMissing,
      'adjacentTo': ?adjacentTo,
      'startItemId': ?startItemId,
      'startIndex': ?startIndex,
      'limit': ?limit,
      if (fields.isNotEmpty) 'fields': fields,
      'sortBy': ?sortBy,
      'imageTypeLimit': ?imageTypeLimit,
    };
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }

    return _http.requestJson(
      '/Shows/$seriesId/Episodes',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `/Shows/{seriesId}/Seasons` — seasons of a series.
  Future<JellyfinQueryResult<JellyfinItem>> seasons({
    required String seriesId,
    bool? isSpecialSeason,
    bool? isMissing,
    String? adjacentTo,
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, Object?>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      'userId': ?_http.userId,
      'isSpecialSeason': ?isSpecialSeason,
      'isMissing': ?isMissing,
      'adjacentTo': ?adjacentTo,
      if (fields.isNotEmpty) 'fields': fields,
      'imageTypeLimit': ?imageTypeLimit,
    };
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }

    return _http.requestJson(
      '/Shows/$seriesId/Seasons',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `/Shows/NextUp` — server-curated "what to watch next" episodes.
  Future<JellyfinQueryResult<JellyfinItem>> nextUp({
    String? seriesId,
    String? parentId,
    int? startIndex,
    int? limit,
    List<JellyfinItemField> fields = const [],
    String? nextUpDateCutoff,
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
    bool enableTotalRecordCount = true,
    bool enableResumable = true,
    bool enableRewatching = false,
  }) async {
    final qp = <String, Object?>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      'enableTotalRecordCount': enableTotalRecordCount,
      'enableResumable': enableResumable,
      'enableRewatching': enableRewatching,
      'userId': ?_http.userId,
      'seriesId': ?seriesId,
      'parentId': ?parentId,
      'startIndex': ?startIndex,
      'limit': ?limit,
      if (fields.isNotEmpty) 'fields': fields,
      'nextUpDateCutoff': ?nextUpDateCutoff,
      'imageTypeLimit': ?imageTypeLimit,
    };
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }

    return _http.requestJson(
      '/Shows/NextUp',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `/Shows/Upcoming` — episodes whose premiere date is in the future.
  Future<JellyfinQueryResult<JellyfinItem>> upcoming({
    String? parentId,
    int? startIndex,
    int? limit,
    List<JellyfinItemField> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
    int? imageTypeLimit,
    List<String> enableImageTypes = const [],
  }) async {
    final qp = <String, Object?>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
      'userId': ?_http.userId,
      'parentId': ?parentId,
      'startIndex': ?startIndex,
      'limit': ?limit,
      if (fields.isNotEmpty) 'fields': fields,
      'imageTypeLimit': ?imageTypeLimit,
    };
    if (enableImageTypes.isNotEmpty) {
      qp['enableImageTypes'] = enableImageTypes;
    }

    return _http.requestJson(
      '/Shows/Upcoming',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }
}
