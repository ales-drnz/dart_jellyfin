// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_query_helpers.dart';
import 'jellyfin_url_helpers.dart';

/// `/LiveTv/*` — live TV channels, EPG, recordings, timers.
///
/// Wraps the consumer-facing slice of the `LiveTv` OpenAPI tag
/// (41 operations upstream; this wrapper covers the ones a typical
/// client app needs). Listings provider configuration and DVR backend
/// admin live behind the escape hatch.
///
/// {@category TV, movies and live TV}
class JellyfinLiveTvApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinLiveTvApi(this._http);

  // ─── Channels ──────────────────────────────────────────────────────

  /// `GET /LiveTv/Channels` — list TV channels.
  ///
  /// [sortBy] entries must be valid `ItemSortBy` enum members (e.g.
  /// `'Default'`, `'SortName'`); the default is empty, omitting the
  /// param so the server applies its native channel ordering.
  ///
  /// There is no server-side search: `/LiveTv/Channels` has no
  /// `searchTerm`. Filter the answer by name instead.
  Future<JellyfinQueryResult<JellyfinItem>> channels({
    int startIndex = 0,
    int? limit,
    bool? isFavorite,
    String? type, // TV | Radio
    bool enableUserData = true,
    List<JellyfinSortField> sortBy = const [],
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'startIndex': startIndex,
      'enableUserData': enableUserData,
      if (sortBy.isNotEmpty) 'sortBy': sortBy,
      'sortOrder': descending ? 'Descending' : 'Ascending',
      'limit': ?limit,
      'isFavorite': ?isFavorite,
      'type': ?type,
    };
    return _http.requestJson(
      '/LiveTv/Channels',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Channels/{channelId}` — single channel by id.
  ///
  /// Unlike [channels], this endpoint does not populate the
  /// `CurrentProgram` field, so the currently airing program may be
  /// absent from the returned item.
  ///
  /// `null` when there is no such channel (a `404`).
  Future<JellyfinItem?> channel({required String channelId}) {
    return _http.requestJsonOrNull(
      '/LiveTv/Channels/$channelId',
      objectOf(JellyfinItem.fromJson),
      queryParameters: {'userId': ?_http.userId},
    );
  }

  // ─── EPG / Programs ────────────────────────────────────────────────

  /// `GET /LiveTv/Programs` — Electronic Program Guide.
  ///
  /// [channelIds] scopes the query to specific channels.
  /// [minStartDate] / [maxStartDate] bound the time window
  /// (ISO-8601 strings — pass `DateTime.toUtc().toIso8601String()`).
  Future<JellyfinQueryResult<JellyfinItem>> programs({
    List<String> channelIds = const [],
    String? minStartDate,
    String? maxStartDate,
    String? minEndDate,
    String? maxEndDate,
    bool? isMovie,
    bool? isSeries,
    bool? isNews,
    bool? isKids,
    bool? isSports,
    bool? hasAired,
    int startIndex = 0,
    int? limit,
    List<JellyfinSortField> sortBy = const [JellyfinSortField.startDate],
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'startIndex': startIndex,
      'sortOrder': descending ? 'Descending' : 'Ascending',
      if (sortBy.isNotEmpty) 'sortBy': sortBy,
      if (channelIds.isNotEmpty) 'channelIds': channelIds,
      'minStartDate': ?minStartDate,
      'maxStartDate': ?maxStartDate,
      'minEndDate': ?minEndDate,
      'maxEndDate': ?maxEndDate,
      'isMovie': ?isMovie,
      'isSeries': ?isSeries,
      'isNews': ?isNews,
      'isKids': ?isKids,
      'isSports': ?isSports,
      'hasAired': ?hasAired,
      'limit': ?limit,
    };
    return _http.requestJson(
      '/LiveTv/Programs',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Programs/Recommended` — algorithm-curated picks.
  Future<JellyfinQueryResult<JellyfinItem>> recommendedPrograms({
    int? limit,
    bool isAiring = true,
    bool? hasAired,
    bool? isSeries,
    bool? isMovie,
    bool? isSports,
    bool? isNews,
    bool? isKids,
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'isAiring': isAiring,
      'limit': ?limit,
      'hasAired': ?hasAired,
      'isSeries': ?isSeries,
      'isMovie': ?isMovie,
      'isSports': ?isSports,
      'isNews': ?isNews,
      'isKids': ?isKids,
    };
    return _http.requestJson(
      '/LiveTv/Programs/Recommended',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  // ─── Recordings ────────────────────────────────────────────────────

  /// `GET /LiveTv/Recordings` — list DVR recordings.
  ///
  /// `GET /LiveTv/Recordings` has no group filter. Jellyfin 12 made
  /// `GET /LiveTv/Recordings/Series` and `/LiveTv/Recordings/Groups`
  /// obsolete, and 0.4.0 removed them.
  Future<JellyfinQueryResult<JellyfinItem>> recordings({
    String? channelId,
    String? seriesTimerId,
    bool? isInProgress,
    int startIndex = 0,
    int? limit,
    bool enableUserData = true,
  }) async {
    final qp = <String, Object?>{
      'userId': ?_http.userId,
      'startIndex': startIndex,
      'enableUserData': enableUserData,
      'channelId': ?channelId,
      'seriesTimerId': ?seriesTimerId,
      'isInProgress': ?isInProgress,
      'limit': ?limit,
    };
    return _http.requestJson(
      '/LiveTv/Recordings',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Recordings/{recordingId}`; `null` when there is no
  /// such recording (a `404`).
  Future<JellyfinItem?> recording({required String recordingId}) =>
      _http.requestJsonOrNull(
        '/LiveTv/Recordings/$recordingId',
        objectOf(JellyfinItem.fromJson),
        queryParameters: {'userId': ?_http.userId},
      );

  /// `DELETE /LiveTv/Recordings/{recordingId}` — delete a recording.
  Future<void> deleteRecording({required String recordingId}) async {
    await _http.request<void>(
      '/LiveTv/Recordings/$recordingId',
      method: 'DELETE',
    );
  }

  // ─── Timers (single recordings) ────────────────────────────────────

  /// `GET /LiveTv/Timers` — scheduled (pending) recordings.
  Future<JellyfinQueryResult<JellyfinTimer>> timers({
    String? channelId,
    String? seriesTimerId,
    bool? isActive,
    bool? isScheduled,
  }) async {
    final qp = <String, Object?>{
      'channelId': ?channelId,
      'seriesTimerId': ?seriesTimerId,
      'isActive': ?isActive,
      'isScheduled': ?isScheduled,
    };
    return _http.requestJson(
      '/LiveTv/Timers',
      queryParameters: qp,
      queryResultOf(JellyfinTimer.fromJson),
    );
  }

  /// `POST /LiveTv/Timers` — create a one-shot timer.
  Future<void> createTimer({required Map<String, Object?> body}) async {
    await _http.request<void>('/LiveTv/Timers', method: 'POST', data: body);
  }

  /// `DELETE /LiveTv/Timers/{id}` — cancel a timer.
  Future<void> deleteTimer({required String timerId}) async {
    await _http.request<void>('/LiveTv/Timers/$timerId', method: 'DELETE');
  }

  // ─── Series timers (recurring) ─────────────────────────────────────

  /// `GET /LiveTv/SeriesTimers` — recurring recording rules.
  Future<JellyfinQueryResult<JellyfinSeriesTimer>> seriesTimers({
    String? sortBy,
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'sortOrder': descending ? 'Descending' : 'Ascending',
      'sortBy': ?sortBy,
    };
    return _http.requestJson(
      '/LiveTv/SeriesTimers',
      queryParameters: qp,
      queryResultOf(JellyfinSeriesTimer.fromJson),
    );
  }

  /// `POST /LiveTv/SeriesTimers` — create a recurring rule (record
  /// every airing of a series).
  Future<void> createSeriesTimer({required Map<String, Object?> body}) async {
    await _http.request<void>(
      '/LiveTv/SeriesTimers',
      method: 'POST',
      data: body,
    );
  }

  /// `DELETE /LiveTv/SeriesTimers/{id}`.
  Future<void> deleteSeriesTimer({required String timerId}) async {
    await _http.request<void>(
      '/LiveTv/SeriesTimers/$timerId',
      method: 'DELETE',
    );
  }

  // ─── Admin: server info, EPG, channel mappings ────────────────────

  /// `GET /LiveTv/Info` — overall live-TV configuration on the
  /// server. Admin only.
  Future<JellyfinLiveTvInfo> info() => _http.requestJson(
    '/LiveTv/Info',
    objectOrEmptyOf(JellyfinLiveTvInfo.fromJson),
  );

  /// `GET /LiveTv/GuideInfo` — EPG metadata (start / end of the
  /// guide window, supported channels).
  Future<JellyfinGuideInfo> guideInfo() => _http.requestJson(
    '/LiveTv/GuideInfo',
    objectOrEmptyOf(JellyfinGuideInfo.fromJson),
  );

  /// `GET /LiveTv/ChannelMappingOptions` — options for mapping
  /// channels to listings provider entries. Admin only.
  Future<JellyfinChannelMappingOptions> channelMappingOptions({
    String? providerId,
  }) {
    final qp = <String, Object?>{'providerId': ?providerId};
    return _http.requestJson(
      '/LiveTv/ChannelMappingOptions',
      queryParameters: qp,
      objectOrEmptyOf(JellyfinChannelMappingOptions.fromJson),
    );
  }

  /// `POST /LiveTv/ChannelMappings` — set a channel-to-EPG mapping
  /// ([body] is a `SetChannelMappingDto`). Answers the mapping as saved.
  Future<JellyfinTunerChannelMapping> setChannelMapping(
    Map<String, Object?> body,
  ) => _http.requestJson(
    '/LiveTv/ChannelMappings',
    method: 'POST',
    data: body,
    objectOrEmptyOf(JellyfinTunerChannelMapping.fromJson),
  );

  // ─── Admin: tuner hosts ───────────────────────────────────────────

  /// `POST /LiveTv/TunerHosts` — register a tuner host (HDHomeRun,
  /// IPTV provider, …). [body] is the tuner-host descriptor
  /// (`TunerHostInfo`). Answers the tuner as saved, with its `Id`.
  Future<JellyfinTunerHost> addTunerHost(Map<String, Object?> body) =>
      _http.requestJson(
        '/LiveTv/TunerHosts',
        method: 'POST',
        data: body,
        objectOrEmptyOf(JellyfinTunerHost.fromJson),
      );

  /// `DELETE /LiveTv/TunerHosts?id={id}` — drop a tuner host.
  Future<void> deleteTunerHost({required String id}) async {
    await _http.request<void>(
      '/LiveTv/TunerHosts',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /LiveTv/TunerHosts/Types` — tuner-host types the server
  /// supports.
  Future<List<JellyfinNameIdPair>> tunerHostTypes() => _http.requestJson(
    '/LiveTv/TunerHosts/Types',
    listOf(JellyfinNameIdPair.fromJson),
  );

  /// `POST /LiveTv/Tuners/{tunerId}/Reset` — reset a tuner.
  Future<void> resetTuner({required String tunerId}) async {
    await _http.request<void>('/LiveTv/Tuners/$tunerId/Reset', method: 'POST');
  }

  /// `GET /LiveTv/Tuners/Discover` — discover tuners on the LAN.
  Future<List<JellyfinTunerHost>> discoverTuners({
    bool newDevicesOnly = false,
  }) => _http.requestJson(
    '/LiveTv/Tuners/Discover',
    queryParameters: {'newDevicesOnly': newDevicesOnly},
    listOf(JellyfinTunerHost.fromJson),
  );

  /// `GET /LiveTv/Tuners/Discvover` — typo-variant of [discoverTuners]
  /// preserved upstream. Behaves identically.
  @Deprecated(
    'Use discoverTuners(), which asks the route without the typo and '
    'answers the same. To be removed in a later release.',
  )
  Future<List<JellyfinTunerHost>> discoverTunersAlt({
    bool newDevicesOnly = false,
  }) => _http.requestJson(
    '/LiveTv/Tuners/Discvover',
    queryParameters: {'newDevicesOnly': newDevicesOnly},
    listOf(JellyfinTunerHost.fromJson),
  );

  // ─── Admin: listings providers ────────────────────────────────────

  /// `POST /LiveTv/ListingProviders` — add an EPG listings provider.
  ///
  /// [body] is a `ListingsProviderInfo`; the answer is the provider as
  /// saved, with its `Id`.
  Future<JellyfinListingsProvider> addListingProvider({
    required Map<String, Object?> body,
    bool validateListings = false,
    bool validateLogin = false,
  }) => _http.requestJson(
    '/LiveTv/ListingProviders',
    method: 'POST',
    queryParameters: {
      'validateListings': validateListings,
      'validateLogin': validateLogin,
    },
    data: body,
    objectOrEmptyOf(JellyfinListingsProvider.fromJson),
  );

  /// `DELETE /LiveTv/ListingProviders?id={id}` — remove a listings
  /// provider.
  Future<void> deleteListingProvider({required String id}) async {
    await _http.request<void>(
      '/LiveTv/ListingProviders',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /LiveTv/ListingProviders/Default` — fields the UI should
  /// pre-populate when adding a new listings provider.
  Future<JellyfinListingsProvider> defaultListingProvider() =>
      _http.requestJson(
        '/LiveTv/ListingProviders/Default',
        objectOrEmptyOf(JellyfinListingsProvider.fromJson),
      );

  /// `GET /LiveTv/ListingProviders/Lineups` — channel lineups
  /// available from a provider.
  Future<List<JellyfinNameIdPair>> lineups({
    String? id,
    String? type,
    String? location,
    String? country,
  }) {
    final qp = <String, Object?>{
      'id': ?id,
      'type': ?type,
      'location': ?location,
      'country': ?country,
    };
    return _http.requestJson(
      '/LiveTv/ListingProviders/Lineups',
      queryParameters: qp,
      listOf(JellyfinNameIdPair.fromJson),
    );
  }

  /// `GET /LiveTv/ListingProviders/SchedulesDirect/Countries` —
  /// countries supported by the Schedules Direct provider.
  ///
  /// Stays a map: the route relays Schedules Direct's own document
  /// (regions to lists of countries), which the API document declares as
  /// an untyped body.
  Future<Map<String, Object?>> schedulesDirectCountries() async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/ListingProviders/SchedulesDirect/Countries',
    );
    return res.data ?? const {};
  }

  // ─── Admin: recordings / live streams URL builders ────────────────

  /// `GET /LiveTv/LiveRecordings/{recordingId}/stream` — URL for an
  /// in-progress live recording stream.
  String liveRecordingStreamUrl({required String recordingId}) {
    return '${_http.requireBaseUrl()}/LiveTv/LiveRecordings/$recordingId'
        '/stream${_http.apiKeyQuery}';
  }

  /// `GET /LiveTv/LiveStreamFiles/{streamId}/stream.{container}` —
  /// URL for one segment of a live stream file.
  String liveStreamFileUrl({
    required String streamId,
    required String container,
  }) {
    return '${_http.requireBaseUrl()}/LiveTv/LiveStreamFiles/$streamId'
        '/stream.${seg(container)}${_http.apiKeyQuery}';
  }

  /// `GET /LiveTv/Recordings/Folders` — folder roots used for
  /// recording storage.
  Future<JellyfinQueryResult<JellyfinItem>> recordingFolders({
    String? userId,
  }) async {
    final qp = <String, Object?>{};
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    return _http.requestJson(
      '/LiveTv/Recordings/Folders',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Programs/{programId}` — fetch a single program
  /// (EPG entry) by id; `null` when there is no such program (a `404`).
  Future<JellyfinItem?> program({required String programId}) =>
      _http.requestJsonOrNull(
        '/LiveTv/Programs/$programId',
        objectOf(JellyfinItem.fromJson),
      );

  /// `GET /LiveTv/Timers/Defaults` — default values to pre-populate
  /// a new recording timer form, as a series timer
  /// (`SeriesTimerInfoDto`). Edit a copy of its `raw` and send it to
  /// [createTimer] or [createSeriesTimer].
  Future<JellyfinSeriesTimer> defaultTimer({String? programId}) {
    final qp = <String, Object?>{'programId': ?programId};
    return _http.requestJson(
      '/LiveTv/Timers/Defaults',
      queryParameters: qp,
      objectOrEmptyOf(JellyfinSeriesTimer.fromJson),
    );
  }
}
