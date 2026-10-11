// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/LiveTv/*` — live TV channels, EPG, recordings, timers.
///
/// Wraps the consumer-facing slice of the `LiveTv` OpenAPI tag
/// (41 operations upstream; this wrapper covers the ones a typical
/// client app needs). Listings provider configuration and DVR backend
/// admin live behind the escape hatch.
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
  /// `searchTerm` (in 10.11 or 12.x), so the parameter of that name, which
  /// earlier versions sent and the server ignored, is deprecated and no
  /// longer sent. Filter the answer by name instead.
  Future<JellyfinQueryResult<JellyfinItem>> channels({
    int startIndex = 0,
    int? limit,
    @Deprecated('Ignored by the server; filter the answer by name')
    String? searchTerm,
    bool? isFavorite,
    String? type, // TV | Radio
    bool enableUserData = true,
    List<String> sortBy = const [],
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'userId': _http.userId,
      'startIndex': startIndex,
      'enableUserData': enableUserData,
      if (sortBy.isNotEmpty) 'sortBy': sortBy,
      'sortOrder': descending ? 'Descending' : 'Ascending',
    };
    if (limit != null) qp['limit'] = limit;
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (type != null) qp['type'] = type;
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
  Future<JellyfinItem?> channel({
    required String channelId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/Channels/$channelId',
      queryParameters: {'userId': _http.userId},
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
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
    List<String> sortBy = const ['StartDate'],
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'userId': _http.userId,
      'startIndex': startIndex,
      'sortOrder': descending ? 'Descending' : 'Ascending',
      if (sortBy.isNotEmpty) 'sortBy': sortBy,
    };
    if (channelIds.isNotEmpty) qp['channelIds'] = channelIds;
    if (minStartDate != null) qp['minStartDate'] = minStartDate;
    if (maxStartDate != null) qp['maxStartDate'] = maxStartDate;
    if (minEndDate != null) qp['minEndDate'] = minEndDate;
    if (maxEndDate != null) qp['maxEndDate'] = maxEndDate;
    if (isMovie != null) qp['isMovie'] = isMovie;
    if (isSeries != null) qp['isSeries'] = isSeries;
    if (isNews != null) qp['isNews'] = isNews;
    if (isKids != null) qp['isKids'] = isKids;
    if (isSports != null) qp['isSports'] = isSports;
    if (hasAired != null) qp['hasAired'] = hasAired;
    if (limit != null) qp['limit'] = limit;
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
      'userId': _http.userId,
      'isAiring': isAiring,
    };
    if (limit != null) qp['limit'] = limit;
    if (hasAired != null) qp['hasAired'] = hasAired;
    if (isSeries != null) qp['isSeries'] = isSeries;
    if (isMovie != null) qp['isMovie'] = isMovie;
    if (isSports != null) qp['isSports'] = isSports;
    if (isNews != null) qp['isNews'] = isNews;
    if (isKids != null) qp['isKids'] = isKids;
    return _http.requestJson(
      '/LiveTv/Programs/Recommended',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  // ─── Recordings ────────────────────────────────────────────────────

  /// `GET /LiveTv/Recordings` — list DVR recordings.
  ///
  /// To filter recordings by group, use [recordingsSeries] (the
  /// `GET /LiveTv/Recordings/Series` operation), which accepts a
  /// `groupId`; `GET /LiveTv/Recordings` itself has no group filter.
  Future<JellyfinQueryResult<JellyfinItem>> recordings({
    String? channelId,
    String? seriesTimerId,
    bool? isInProgress,
    int startIndex = 0,
    int? limit,
    bool enableUserData = true,
  }) async {
    final qp = <String, Object?>{
      'userId': _http.userId,
      'startIndex': startIndex,
      'enableUserData': enableUserData,
    };
    if (channelId != null) qp['channelId'] = channelId;
    if (seriesTimerId != null) qp['seriesTimerId'] = seriesTimerId;
    if (isInProgress != null) qp['isInProgress'] = isInProgress;
    if (limit != null) qp['limit'] = limit;
    return _http.requestJson(
      '/LiveTv/Recordings',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Recordings/{recordingId}`.
  Future<JellyfinItem?> recording({
    required String recordingId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/Recordings/$recordingId',
      queryParameters: {'userId': _http.userId},
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `DELETE /LiveTv/Recordings/{recordingId}` — delete a recording.
  Future<void> deleteRecording({
    required String recordingId,
  }) async {
    await _http.request<void>(
      '/LiveTv/Recordings/$recordingId',
      method: 'DELETE',
    );
  }

  // ─── Timers (single recordings) ────────────────────────────────────

  /// `GET /LiveTv/Timers` — scheduled (pending) recordings.
  Future<JellyfinQueryResult<Map<String, Object?>>> timers({
    String? channelId,
    String? seriesTimerId,
    bool? isActive,
    bool? isScheduled,
  }) async {
    final qp = <String, Object?>{};
    if (channelId != null) qp['channelId'] = channelId;
    if (seriesTimerId != null) qp['seriesTimerId'] = seriesTimerId;
    if (isActive != null) qp['isActive'] = isActive;
    if (isScheduled != null) qp['isScheduled'] = isScheduled;
    return _http.requestJson(
      '/LiveTv/Timers',
      queryParameters: qp.isEmpty ? null : qp,
      queryResultOf((e) => e),
    );
  }

  /// `POST /LiveTv/Timers` — create a one-shot timer.
  Future<void> createTimer({required Map<String, Object?> body}) async {
    await _http.request<void>(
      '/LiveTv/Timers',
      method: 'POST',
      data: body,
    );
  }

  /// `DELETE /LiveTv/Timers/{id}` — cancel a timer.
  Future<void> deleteTimer({
    required String timerId,
  }) async {
    await _http.request<void>(
      '/LiveTv/Timers/$timerId',
      method: 'DELETE',
    );
  }

  // ─── Series timers (recurring) ─────────────────────────────────────

  /// `GET /LiveTv/SeriesTimers` — recurring recording rules.
  Future<JellyfinQueryResult<Map<String, Object?>>> seriesTimers({
    String? sortBy,
    bool descending = false,
  }) async {
    final qp = <String, Object?>{
      'sortOrder': descending ? 'Descending' : 'Ascending',
    };
    if (sortBy != null) qp['sortBy'] = sortBy;
    return _http.requestJson(
      '/LiveTv/SeriesTimers',
      queryParameters: qp,
      queryResultOf((e) => e),
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
  Future<void> deleteSeriesTimer({
    required String timerId,
  }) async {
    await _http.request<void>(
      '/LiveTv/SeriesTimers/$timerId',
      method: 'DELETE',
    );
  }

  // ─── Admin: server info, EPG, channel mappings ────────────────────

  /// `GET /LiveTv/Info` — overall live-TV configuration on the
  /// server. Admin only.
  Future<Map<String, Object?>> info() async {
    final res = await _http.request<Map<String, Object?>>('/LiveTv/Info');
    return res.data ?? const {};
  }

  /// `GET /LiveTv/GuideInfo` — EPG metadata (start / end of the
  /// guide window, supported channels).
  Future<Map<String, Object?>> guideInfo() async {
    final res = await _http.request<Map<String, Object?>>('/LiveTv/GuideInfo');
    return res.data ?? const {};
  }

  /// `GET /LiveTv/ChannelMappingOptions` — options for mapping
  /// channels to listings provider entries. Admin only.
  Future<Map<String, Object?>> channelMappingOptions({
    String? providerId,
  }) async {
    final qp = <String, Object?>{};
    if (providerId != null) qp['providerId'] = providerId;
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/ChannelMappingOptions',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  /// `POST /LiveTv/ChannelMappings` — set a channel-to-EPG mapping.
  Future<Map<String, Object?>> setChannelMapping(
    Map<String, Object?> body,
  ) async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/ChannelMappings',
      method: 'POST',
      data: body,
    );
    return res.data ?? const {};
  }

  // ─── Admin: tuner hosts ───────────────────────────────────────────

  /// `POST /LiveTv/TunerHosts` — register a tuner host (HDHomeRun,
  /// IPTV provider, …). [body] is the tuner-host descriptor.
  Future<Map<String, Object?>> addTunerHost(Map<String, Object?> body) async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/TunerHosts',
      method: 'POST',
      data: body,
    );
    return res.data ?? const {};
  }

  /// `DELETE /LiveTv/TunerHosts?id={id}` — drop a tuner host.
  Future<void> deleteTunerHost({
    required String id,
  }) async {
    await _http.request<void>(
      '/LiveTv/TunerHosts',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /LiveTv/TunerHosts/Types` — tuner-host types the server
  /// supports.
  Future<List<Map<String, Object?>>> tunerHostTypes() async {
    final res = await _http.request<List<Object?>>('/LiveTv/TunerHosts/Types');
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  /// `POST /LiveTv/Tuners/{tunerId}/Reset` — reset a tuner.
  Future<void> resetTuner({
    required String tunerId,
  }) async {
    await _http.request<void>(
      '/LiveTv/Tuners/$tunerId/Reset',
      method: 'POST',
    );
  }

  /// `GET /LiveTv/Tuners/Discover` — discover tuners on the LAN.
  Future<List<Map<String, Object?>>> discoverTuners({
    bool newDevicesOnly = false,
  }) async {
    final res = await _http.request<List<Object?>>(
      '/LiveTv/Tuners/Discover',
      queryParameters: {'newDevicesOnly': newDevicesOnly},
    );
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  /// `GET /LiveTv/Tuners/Discvover` — typo-variant of [discoverTuners]
  /// preserved upstream. Behaves identically.
  Future<List<Map<String, Object?>>> discoverTunersAlt({
    bool newDevicesOnly = false,
  }) async {
    final res = await _http.request<List<Object?>>(
      '/LiveTv/Tuners/Discvover',
      queryParameters: {'newDevicesOnly': newDevicesOnly},
    );
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  // ─── Admin: listings providers ────────────────────────────────────

  /// `POST /LiveTv/ListingProviders` — add an EPG listings provider.
  Future<Map<String, Object?>> addListingProvider({
    required Map<String, Object?> body,
    bool validateListings = false,
    bool validateLogin = false,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/ListingProviders',
      method: 'POST',
      queryParameters: {
        'validateListings': validateListings,
        'validateLogin': validateLogin,
      },
      data: body,
    );
    return res.data ?? const {};
  }

  /// `DELETE /LiveTv/ListingProviders?id={id}` — remove a listings
  /// provider.
  Future<void> deleteListingProvider({
    required String id,
  }) async {
    await _http.request<void>(
      '/LiveTv/ListingProviders',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /LiveTv/ListingProviders/Default` — fields the UI should
  /// pre-populate when adding a new listings provider.
  Future<Map<String, Object?>> defaultListingProvider() async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/ListingProviders/Default',
    );
    return res.data ?? const {};
  }

  /// `GET /LiveTv/ListingProviders/Lineups` — channel lineups
  /// available from a provider.
  Future<List<Map<String, Object?>>> lineups({
    String? id,
    String? type,
    String? location,
    String? country,
  }) async {
    final qp = <String, Object?>{};
    if (id != null) qp['id'] = id;
    if (type != null) qp['type'] = type;
    if (location != null) qp['location'] = location;
    if (country != null) qp['country'] = country;
    final res = await _http.request<List<Object?>>(
      '/LiveTv/ListingProviders/Lineups',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  /// `GET /LiveTv/ListingProviders/SchedulesDirect/Countries` —
  /// countries supported by the Schedules Direct provider.
  Future<Map<String, Object?>> schedulesDirectCountries() async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/ListingProviders/SchedulesDirect/Countries',
    );
    return res.data ?? const {};
  }

  // ─── Admin: recordings / live streams URL builders ────────────────

  /// `GET /LiveTv/LiveRecordings/{recordingId}/stream` — URL for an
  /// in-progress live recording stream.
  String liveRecordingStreamUrl({
    required String recordingId,
  }) {
    final base = _requireBaseUrl();
    final token = _requireToken();
    return '$base/LiveTv/LiveRecordings/$recordingId/stream?ApiKey=$token';
  }

  /// `GET /LiveTv/LiveStreamFiles/{streamId}/stream.{container}` —
  /// URL for one segment of a live stream file.
  String liveStreamFileUrl({
    required String streamId,
    required String container,
  }) {
    final base = _requireBaseUrl();
    final token = _requireToken();
    return '$base/LiveTv/LiveStreamFiles/$streamId/stream.$container?ApiKey=$token';
  }

  /// `GET /LiveTv/Recordings/Groups` — list every recording group
  /// (categories the server uses to organise recordings).
  ///
  /// Hidden from the Jellyfin 12 OpenAPI document and marked obsolete
  /// upstream, with no replacement. It still answers on 12.0 but may
  /// be removed in any major release without notice. Use
  /// [recordingFolders] or [recordings] where they fit.
  @Deprecated(
    'Hidden from the Jellyfin 12 API and may be removed without notice; '
    'use recordingFolders() or recordings() instead.',
  )
  Future<JellyfinQueryResult<JellyfinItem>> recordingGroups({
    String? userId,
  }) async {
    final qp = <String, Object?>{};
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    return _http.requestJson(
      '/LiveTv/Recordings/Groups',
      queryParameters: qp.isEmpty ? null : qp,
      queryResultOf(JellyfinItem.fromJson),
    );
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
      queryParameters: qp.isEmpty ? null : qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Recordings/Series` — recordings grouped by series.
  ///
  /// [status] is a `RecordingStatus` enum member: `New`, `InProgress`,
  /// `Completed`, `Cancelled`, `ConflictedOk`, `ConflictedNotOk` or
  /// `Error`.
  ///
  /// Hidden from the Jellyfin 12 OpenAPI document and marked obsolete
  /// upstream, with no replacement. It still answers on 12.0 but may
  /// be removed in any major release without notice. [recordings]
  /// with `isSeries: true` covers the common case.
  @Deprecated(
    'Hidden from the Jellyfin 12 API and may be removed without notice; '
    'use recordings() instead.',
  )
  Future<JellyfinQueryResult<JellyfinItem>> recordingsSeries({
    String? userId,
    String? channelId,
    String? groupId,
    int? startIndex,
    int? limit,
    String? status,
    bool? isInProgress,
    String? seriesTimerId,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
  }) async {
    final qp = <String, Object?>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
    };
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    if (channelId != null) qp['channelId'] = channelId;
    if (groupId != null) qp['groupId'] = groupId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (status != null) qp['status'] = status;
    if (isInProgress != null) qp['isInProgress'] = isInProgress;
    if (seriesTimerId != null) qp['seriesTimerId'] = seriesTimerId;
    if (fields.isNotEmpty) qp['fields'] = fields;
    return _http.requestJson(
      '/LiveTv/Recordings/Series',
      queryParameters: qp,
      queryResultOf(JellyfinItem.fromJson),
    );
  }

  /// `GET /LiveTv/Programs/{programId}` — fetch a single program
  /// (EPG entry) by id.
  Future<JellyfinItem?> program({
    required String programId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/Programs/$programId',
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `GET /LiveTv/Timers/Defaults` — default values to pre-populate
  /// a new recording timer form.
  Future<Map<String, Object?>> defaultTimer({String? programId}) async {
    final qp = <String, Object?>{};
    if (programId != null) qp['programId'] = programId;
    final res = await _http.request<Map<String, Object?>>(
      '/LiveTv/Timers/Defaults',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  String _requireBaseUrl() {
    final url = _http.baseUrl;
    if (url == null) {
      throw const JellyfinException(
        'No base URL — call JellyfinClient.connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    return url;
  }

  String _requireToken() {
    final t = _http.token;
    if (t == null) {
      throw const JellyfinException(
        'No token — call JellyfinClient.setSession() first.',
        type: JellyfinErrorType.state,
      );
    }
    return t;
  }
}
