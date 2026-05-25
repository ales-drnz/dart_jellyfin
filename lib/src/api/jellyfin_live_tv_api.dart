// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

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
  Future<JellyfinQueryResult<JellyfinItem>> channels({
    int startIndex = 0,
    int? limit,
    String? searchTerm,
    bool? isFavorite,
    String? type, // TV | Radio
    bool enableUserData = true,
    List<String> sortBy = const ['DefaultChannelOrder'],
    bool descending = false,
  }) async {
    final qp = <String, dynamic>{
      'userId': _http.userId,
      'startIndex': startIndex,
      'enableUserData': enableUserData,
      if (sortBy.isNotEmpty) 'sortBy': sortBy.join(','),
      'sortOrder': descending ? 'Descending' : 'Ascending',
    };
    if (limit != null) qp['limit'] = limit;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      qp['searchTerm'] = searchTerm;
    }
    if (isFavorite != null) qp['isFavorite'] = isFavorite;
    if (type != null) qp['type'] = type;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Channels',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /LiveTv/Channels/{channelId}` — single channel + currently
  /// airing program.
  Future<JellyfinItem?> channel(String channelId) async {
    final res = await _http.request<Map<String, dynamic>>(
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
    final qp = <String, dynamic>{
      'userId': _http.userId,
      'startIndex': startIndex,
      'sortOrder': descending ? 'Descending' : 'Ascending',
      if (sortBy.isNotEmpty) 'sortBy': sortBy.join(','),
    };
    if (channelIds.isNotEmpty) qp['channelIds'] = channelIds.join(',');
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
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Programs',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
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
    final qp = <String, dynamic>{
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
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Programs/Recommended',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  // ─── Recordings ────────────────────────────────────────────────────

  /// `GET /LiveTv/Recordings` — list DVR recordings.
  Future<JellyfinQueryResult<JellyfinItem>> recordings({
    String? channelId,
    String? groupId,
    String? seriesTimerId,
    bool? isInProgress,
    int startIndex = 0,
    int? limit,
    bool enableUserData = true,
  }) async {
    final qp = <String, dynamic>{
      'userId': _http.userId,
      'startIndex': startIndex,
      'enableUserData': enableUserData,
    };
    if (channelId != null) qp['channelId'] = channelId;
    if (groupId != null) qp['groupId'] = groupId;
    if (seriesTimerId != null) qp['seriesTimerId'] = seriesTimerId;
    if (isInProgress != null) qp['isInProgress'] = isInProgress;
    if (limit != null) qp['limit'] = limit;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Recordings',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /LiveTv/Recordings/{recordingId}`.
  Future<JellyfinItem?> recording(String recordingId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Recordings/$recordingId',
      queryParameters: {'userId': _http.userId},
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `DELETE /LiveTv/Recordings/{recordingId}` — delete a recording.
  Future<void> deleteRecording(String recordingId) async {
    await _http.request<void>(
      '/LiveTv/Recordings/$recordingId',
      method: 'DELETE',
    );
  }

  // ─── Timers (single recordings) ────────────────────────────────────

  /// `GET /LiveTv/Timers` — scheduled (pending) recordings.
  Future<JellyfinQueryResult<Map<String, dynamic>>> timers({
    String? channelId,
    String? seriesTimerId,
    bool? isActive,
    bool? isScheduled,
  }) async {
    final qp = <String, dynamic>{};
    if (channelId != null) qp['channelId'] = channelId;
    if (seriesTimerId != null) qp['seriesTimerId'] = seriesTimerId;
    if (isActive != null) qp['isActive'] = isActive;
    if (isScheduled != null) qp['isScheduled'] = isScheduled;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Timers',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      (e) => e,
    );
  }

  /// `POST /LiveTv/Timers` — create a one-shot timer.
  Future<void> createTimer({required Map<String, dynamic> body}) async {
    await _http.request<void>(
      '/LiveTv/Timers',
      method: 'POST',
      data: body,
    );
  }

  /// `DELETE /LiveTv/Timers/{id}` — cancel a timer.
  Future<void> deleteTimer(String timerId) async {
    await _http.request<void>(
      '/LiveTv/Timers/$timerId',
      method: 'DELETE',
    );
  }

  // ─── Series timers (recurring) ─────────────────────────────────────

  /// `GET /LiveTv/SeriesTimers` — recurring recording rules.
  Future<JellyfinQueryResult<Map<String, dynamic>>> seriesTimers({
    String? sortBy,
    bool descending = false,
  }) async {
    final qp = <String, dynamic>{
      'sortOrder': descending ? 'Descending' : 'Ascending',
    };
    if (sortBy != null) qp['sortBy'] = sortBy;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/SeriesTimers',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      (e) => e,
    );
  }

  /// `POST /LiveTv/SeriesTimers` — create a recurring rule (record
  /// every airing of a series).
  Future<void> createSeriesTimer({required Map<String, dynamic> body}) async {
    await _http.request<void>(
      '/LiveTv/SeriesTimers',
      method: 'POST',
      data: body,
    );
  }

  /// `DELETE /LiveTv/SeriesTimers/{id}`.
  Future<void> deleteSeriesTimer(String timerId) async {
    await _http.request<void>(
      '/LiveTv/SeriesTimers/$timerId',
      method: 'DELETE',
    );
  }

  // ─── Admin: server info, EPG, channel mappings ────────────────────

  /// `GET /LiveTv/Info` — overall live-TV configuration on the
  /// server. Admin only.
  Future<Map<String, dynamic>> info() async {
    final res = await _http.request<Map<String, dynamic>>('/LiveTv/Info');
    return res.data ?? const {};
  }

  /// `GET /LiveTv/GuideInfo` — EPG metadata (start / end of the
  /// guide window, supported channels).
  Future<Map<String, dynamic>> guideInfo() async {
    final res = await _http.request<Map<String, dynamic>>('/LiveTv/GuideInfo');
    return res.data ?? const {};
  }

  /// `GET /LiveTv/ChannelMappingOptions` — options for mapping
  /// channels to listings provider entries. Admin only.
  Future<Map<String, dynamic>> channelMappingOptions({
    String? providerId,
  }) async {
    final qp = <String, dynamic>{};
    if (providerId != null) qp['providerId'] = providerId;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/ChannelMappingOptions',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  /// `POST /LiveTv/ChannelMappings` — set a channel-to-EPG mapping.
  Future<Map<String, dynamic>> setChannelMapping(
      Map<String, dynamic> body) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/ChannelMappings',
      method: 'POST',
      data: body,
    );
    return res.data ?? const {};
  }

  // ─── Admin: tuner hosts ───────────────────────────────────────────

  /// `POST /LiveTv/TunerHosts` — register a tuner host (HDHomeRun,
  /// IPTV provider, …). [body] is the tuner-host descriptor.
  Future<Map<String, dynamic>> addTunerHost(Map<String, dynamic> body) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/TunerHosts',
      method: 'POST',
      data: body,
    );
    return res.data ?? const {};
  }

  /// `DELETE /LiveTv/TunerHosts?id={id}` — drop a tuner host.
  Future<void> deleteTunerHost(String id) async {
    await _http.request<void>(
      '/LiveTv/TunerHosts',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /LiveTv/TunerHosts/Types` — tuner-host types the server
  /// supports.
  Future<List<Map<String, dynamic>>> tunerHostTypes() async {
    final res = await _http.request<List<dynamic>>('/LiveTv/TunerHosts/Types');
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `POST /LiveTv/Tuners/{tunerId}/Reset` — reset a tuner.
  Future<void> resetTuner(String tunerId) async {
    await _http.request<void>(
      '/LiveTv/Tuners/$tunerId/Reset',
      method: 'POST',
    );
  }

  /// `GET /LiveTv/Tuners/Discover` — discover tuners on the LAN.
  Future<List<Map<String, dynamic>>> discoverTuners({
    bool newDevicesOnly = false,
  }) async {
    final res = await _http.request<List<dynamic>>(
      '/LiveTv/Tuners/Discover',
      queryParameters: {'newDevicesOnly': newDevicesOnly},
    );
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `GET /LiveTv/Tuners/Discvover` — typo-variant of [discoverTuners]
  /// preserved upstream. Behaves identically.
  Future<List<Map<String, dynamic>>> discoverTunersAlt({
    bool newDevicesOnly = false,
  }) async {
    final res = await _http.request<List<dynamic>>(
      '/LiveTv/Tuners/Discvover',
      queryParameters: {'newDevicesOnly': newDevicesOnly},
    );
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  // ─── Admin: listings providers ────────────────────────────────────

  /// `POST /LiveTv/ListingProviders` — add an EPG listings provider.
  Future<Map<String, dynamic>> addListingProvider({
    required Map<String, dynamic> body,
    bool validateListings = false,
    bool validateLogin = false,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
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
  Future<void> deleteListingProvider(String id) async {
    await _http.request<void>(
      '/LiveTv/ListingProviders',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /LiveTv/ListingProviders/Default` — fields the UI should
  /// pre-populate when adding a new listings provider.
  Future<Map<String, dynamic>> defaultListingProvider() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/ListingProviders/Default',
    );
    return res.data ?? const {};
  }

  /// `GET /LiveTv/ListingProviders/Lineups` — channel lineups
  /// available from a provider.
  Future<List<Map<String, dynamic>>> lineups({
    String? id,
    String? type,
    String? location,
    String? country,
  }) async {
    final qp = <String, dynamic>{};
    if (id != null) qp['id'] = id;
    if (type != null) qp['type'] = type;
    if (location != null) qp['location'] = location;
    if (country != null) qp['country'] = country;
    final res = await _http.request<List<dynamic>>(
      '/LiveTv/ListingProviders/Lineups',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `GET /LiveTv/ListingProviders/SchedulesDirect/Countries` —
  /// countries supported by the Schedules Direct provider.
  Future<Map<String, dynamic>> schedulesDirectCountries() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/ListingProviders/SchedulesDirect/Countries',
    );
    return res.data ?? const {};
  }

  // ─── Admin: recordings / live streams URL builders ────────────────

  /// `GET /LiveTv/LiveRecordings/{recordingId}/stream` — URL for an
  /// in-progress live recording stream.
  String liveRecordingStreamUrl(String recordingId) {
    final base = _http.baseUrl;
    final token = _http.token ?? '';
    return '$base/LiveTv/LiveRecordings/$recordingId/stream?api_key=$token';
  }

  /// `GET /LiveTv/LiveStreamFiles/{streamId}/stream.{container}` —
  /// URL for one segment of a live stream file.
  String liveStreamFileUrl({
    required String streamId,
    required String container,
  }) {
    final base = _http.baseUrl;
    final token = _http.token ?? '';
    return '$base/LiveTv/LiveStreamFiles/$streamId/stream.$container?api_key=$token';
  }

  /// `GET /LiveTv/Recordings/Groups/{groupId}` — fetch a single
  /// recording group by id.
  Future<Map<String, dynamic>> recordingGroup(String groupId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Recordings/Groups/$groupId',
    );
    return res.data ?? const {};
  }

  /// `GET /LiveTv/Recordings/Groups` — list every recording group
  /// (categories the server uses to organise recordings).
  Future<JellyfinQueryResult<JellyfinItem>> recordingGroups({
    String? userId,
  }) async {
    final qp = <String, dynamic>{};
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Recordings/Groups',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /LiveTv/Recordings/Folders` — folder roots used for
  /// recording storage.
  Future<JellyfinQueryResult<JellyfinItem>> recordingFolders({
    String? userId,
  }) async {
    final qp = <String, dynamic>{};
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Recordings/Folders',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /LiveTv/Recordings/Series` — recordings grouped by series.
  Future<JellyfinQueryResult<JellyfinItem>> recordingsSeries({
    String? userId,
    String? groupId,
    int? startIndex,
    int? limit,
    bool? isActive,
    bool? isLibraryItem,
    List<String> fields = const [],
    bool enableImages = true,
    bool enableUserData = true,
  }) async {
    final qp = <String, dynamic>{
      'enableImages': enableImages,
      'enableUserData': enableUserData,
    };
    final u = userId ?? _http.userId;
    if (u != null) qp['userId'] = u;
    if (groupId != null) qp['groupId'] = groupId;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (isActive != null) qp['isActive'] = isActive;
    if (isLibraryItem != null) qp['isLibraryItem'] = isLibraryItem;
    if (fields.isNotEmpty) qp['fields'] = fields.join(',');
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Recordings/Series',
      queryParameters: qp,
    );
    return JellyfinQueryResult.fromJson(
      res.data ?? const {},
      JellyfinItem.fromJson,
    );
  }

  /// `GET /LiveTv/Programs/{programId}` — fetch a single program
  /// (EPG entry) by id.
  Future<JellyfinItem?> program(String programId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Programs/$programId',
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  }

  /// `GET /LiveTv/Timers/Defaults` — default values to pre-populate
  /// a new recording timer form.
  Future<Map<String, dynamic>> defaultTimer({String? programId}) async {
    final qp = <String, dynamic>{};
    if (programId != null) qp['programId'] = programId;
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveTv/Timers/Defaults',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }
}
