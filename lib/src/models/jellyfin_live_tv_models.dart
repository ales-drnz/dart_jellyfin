// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Live TV
// ---------------------------------------------------------------------------

/// A scheduled recording (`TimerInfoDto`).
final class JellyfinTimer {
  /// `Id`, for `liveTv.deleteTimer`.
  final String id;

  /// `Name`.
  final String? name;

  /// `Overview`.
  final String? overview;

  /// `ChannelId`.
  final String? channelId;

  /// `ChannelName`.
  final String? channelName;

  /// `ProgramId`.
  final String? programId;

  /// The series rule that created it (`SeriesTimerId`).
  final String? seriesTimerId;

  /// `StartDate`.
  final DateTime? startDate;

  /// `EndDate`.
  final DateTime? endDate;

  /// `New`, `InProgress`, `Completed`, … (`Status`).
  final String? status;

  /// `Priority`.
  final int? priority;

  /// `PrePaddingSeconds`.
  final int? prePaddingSeconds;

  /// `PostPaddingSeconds`.
  final int? postPaddingSeconds;

  /// `UntilDeleted`, `UntilSpaceNeeded`, … (`KeepUntil`).
  final String? keepUntil;

  /// `RunTimeTicks`.
  final int? runTimeTicks;

  /// The program to record (`ProgramInfo`).
  final JellyfinItem? programInfo;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a timer from already-parsed components.
  const JellyfinTimer({
    required this.id,
    required this.raw,
    this.name,
    this.overview,
    this.channelId,
    this.channelName,
    this.programId,
    this.seriesTimerId,
    this.startDate,
    this.endDate,
    this.status,
    this.priority,
    this.prePaddingSeconds,
    this.postPaddingSeconds,
    this.keepUntil,
    this.runTimeTicks,
    this.programInfo,
  });

  /// Decodes a `TimerInfoDto`.
  factory JellyfinTimer.fromJson(Map<String, Object?> json) {
    final program = json['ProgramInfo'];
    return JellyfinTimer(
      id: asString(json['Id']) ?? '',
      name: asString(json['Name']),
      overview: asString(json['Overview']),
      channelId: asString(json['ChannelId']),
      channelName: asString(json['ChannelName']),
      programId: asString(json['ProgramId']),
      seriesTimerId: asString(json['SeriesTimerId']),
      startDate: asUtcDateTime(json['StartDate']),
      endDate: asUtcDateTime(json['EndDate']),
      status: asString(json['Status']),
      priority: asInt(json['Priority']),
      prePaddingSeconds: asInt(json['PrePaddingSeconds']),
      postPaddingSeconds: asInt(json['PostPaddingSeconds']),
      keepUntil: asString(json['KeepUntil']),
      runTimeTicks: asInt(json['RunTimeTicks']),
      programInfo: program is Map<String, Object?>
          ? JellyfinItem.fromJson(program)
          : null,
      raw: json,
    );
  }
}

/// A recurring recording rule (`SeriesTimerInfoDto`), and the defaults
/// `liveTv.defaultTimer` answers.
final class JellyfinSeriesTimer {
  /// `Id`, for `liveTv.deleteSeriesTimer`.
  final String id;

  /// `Name`.
  final String? name;

  /// `Overview`.
  final String? overview;

  /// `ChannelId`.
  final String? channelId;

  /// `ChannelName`.
  final String? channelName;

  /// `ProgramId`.
  final String? programId;

  /// `StartDate`.
  final DateTime? startDate;

  /// `EndDate`.
  final DateTime? endDate;

  /// `Priority`.
  final int? priority;

  /// `PrePaddingSeconds`.
  final int? prePaddingSeconds;

  /// `PostPaddingSeconds`.
  final int? postPaddingSeconds;

  /// `KeepUntil`.
  final String? keepUntil;

  /// How many recordings to keep, `0` for all (`KeepUpTo`).
  final int? keepUpTo;

  /// `RecordAnyTime`.
  final bool recordAnyTime;

  /// `RecordAnyChannel`.
  final bool recordAnyChannel;

  /// `RecordNewOnly`.
  final bool recordNewOnly;

  /// `SkipEpisodesInLibrary`.
  final bool skipEpisodesInLibrary;

  /// The days it records on, `Sunday` … `Saturday` (`Days`).
  final List<String> days;

  /// `Daily`, `Weekdays` or `Weekends` (`DayPattern`).
  final String? dayPattern;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a series timer from already-parsed components.
  const JellyfinSeriesTimer({
    required this.id,
    required this.recordAnyTime,
    required this.recordAnyChannel,
    required this.recordNewOnly,
    required this.skipEpisodesInLibrary,
    required this.days,
    required this.raw,
    this.name,
    this.overview,
    this.channelId,
    this.channelName,
    this.programId,
    this.startDate,
    this.endDate,
    this.priority,
    this.prePaddingSeconds,
    this.postPaddingSeconds,
    this.keepUntil,
    this.keepUpTo,
    this.dayPattern,
  });

  /// Decodes a `SeriesTimerInfoDto`.
  factory JellyfinSeriesTimer.fromJson(Map<String, Object?> json) =>
      JellyfinSeriesTimer(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        overview: asString(json['Overview']),
        channelId: asString(json['ChannelId']),
        channelName: asString(json['ChannelName']),
        programId: asString(json['ProgramId']),
        startDate: asUtcDateTime(json['StartDate']),
        endDate: asUtcDateTime(json['EndDate']),
        priority: asInt(json['Priority']),
        prePaddingSeconds: asInt(json['PrePaddingSeconds']),
        postPaddingSeconds: asInt(json['PostPaddingSeconds']),
        keepUntil: asString(json['KeepUntil']),
        keepUpTo: asInt(json['KeepUpTo']),
        recordAnyTime: json['RecordAnyTime'] == true,
        recordAnyChannel: json['RecordAnyChannel'] == true,
        recordNewOnly: json['RecordNewOnly'] == true,
        skipEpisodesInLibrary: json['SkipEpisodesInLibrary'] == true,
        days: asStringList(json['Days']),
        dayPattern: asString(json['DayPattern']),
        raw: json,
      );
}

/// A live TV backend (`LiveTvServiceInfo`).
final class JellyfinLiveTvService {
  /// `Name`.
  final String name;

  /// `Ok` or `Unavailable` (`Status`).
  final String? status;

  /// `StatusMessage`.
  final String? statusMessage;

  /// `Version`.
  final String? version;

  /// `IsVisible`.
  final bool isVisible;

  /// `HasUpdateAvailable`.
  final bool hasUpdateAvailable;

  /// `Tuners`.
  final List<String> tuners;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a service from already-parsed components.
  const JellyfinLiveTvService({
    required this.name,
    required this.isVisible,
    required this.hasUpdateAvailable,
    required this.tuners,
    required this.raw,
    this.status,
    this.statusMessage,
    this.version,
  });

  /// Decodes a `LiveTvServiceInfo`.
  factory JellyfinLiveTvService.fromJson(Map<String, Object?> json) =>
      JellyfinLiveTvService(
        name: asString(json['Name']) ?? '',
        status: asString(json['Status']),
        statusMessage: asString(json['StatusMessage']),
        version: asString(json['Version']),
        isVisible: json['IsVisible'] == true,
        hasUpdateAvailable: json['HasUpdateAvailable'] == true,
        tuners: asStringList(json['Tuners']),
        raw: json,
      );
}

/// The live TV setup of the server (`LiveTvInfo`).
final class JellyfinLiveTvInfo {
  /// `IsEnabled`.
  final bool isEnabled;

  /// The backends (`Services`).
  final List<JellyfinLiveTvService> services;

  /// The users allowed live TV (`EnabledUsers`).
  final List<String> enabledUsers;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the info from already-parsed components.
  const JellyfinLiveTvInfo({
    required this.isEnabled,
    required this.services,
    required this.enabledUsers,
    required this.raw,
  });

  /// Decodes a `LiveTvInfo`.
  factory JellyfinLiveTvInfo.fromJson(Map<String, Object?> json) =>
      JellyfinLiveTvInfo(
        isEnabled: json['IsEnabled'] == true,
        services: asObjectList(
          json['Services'],
          JellyfinLiveTvService.fromJson,
        ),
        enabledUsers: asStringList(json['EnabledUsers']),
        raw: json,
      );
}

/// The time window the guide covers (`GuideInfo`).
final class JellyfinGuideInfo {
  /// `StartDate`.
  final DateTime? startDate;

  /// `EndDate`.
  final DateTime? endDate;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the guide info from already-parsed components.
  const JellyfinGuideInfo({required this.raw, this.startDate, this.endDate});

  /// Decodes a `GuideInfo`.
  factory JellyfinGuideInfo.fromJson(Map<String, Object?> json) =>
      JellyfinGuideInfo(
        startDate: asUtcDateTime(json['StartDate']),
        endDate: asUtcDateTime(json['EndDate']),
        raw: json,
      );
}

/// A tuner channel and the guide channel it maps to
/// (`TunerChannelMapping`).
final class JellyfinTunerChannelMapping {
  /// The tuner channel (`Id`).
  final String id;

  /// `Name`.
  final String? name;

  /// The guide channel (`ProviderChannelId`).
  final String? providerChannelId;

  /// `ProviderChannelName`.
  final String? providerChannelName;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a mapping from already-parsed components.
  const JellyfinTunerChannelMapping({
    required this.id,
    required this.raw,
    this.name,
    this.providerChannelId,
    this.providerChannelName,
  });

  /// Decodes a `TunerChannelMapping`.
  factory JellyfinTunerChannelMapping.fromJson(Map<String, Object?> json) =>
      JellyfinTunerChannelMapping(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        providerChannelId: asString(json['ProviderChannelId']),
        providerChannelName: asString(json['ProviderChannelName']),
        raw: json,
      );
}

/// The channel mappings of a listings provider
/// (`ChannelMappingOptionsDto`).
final class JellyfinChannelMappingOptions {
  /// `TunerChannels`.
  final List<JellyfinTunerChannelMapping> tunerChannels;

  /// `ProviderChannels`.
  final List<JellyfinNameIdPair> providerChannels;

  /// `Mappings`.
  final List<JellyfinNameValuePair> mappings;

  /// `ProviderName`.
  final String? providerName;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the options from already-parsed components.
  const JellyfinChannelMappingOptions({
    required this.tunerChannels,
    required this.providerChannels,
    required this.mappings,
    required this.raw,
    this.providerName,
  });

  /// Decodes a `ChannelMappingOptionsDto`.
  factory JellyfinChannelMappingOptions.fromJson(Map<String, Object?> json) =>
      JellyfinChannelMappingOptions(
        tunerChannels: asObjectList(
          json['TunerChannels'],
          JellyfinTunerChannelMapping.fromJson,
        ),
        providerChannels: asObjectList(
          json['ProviderChannels'],
          JellyfinNameIdPair.fromJson,
        ),
        mappings: asObjectList(
          json['Mappings'],
          JellyfinNameValuePair.fromJson,
        ),
        providerName: asString(json['ProviderName']),
        raw: json,
      );
}

/// A tuner (`TunerHostInfo`).
final class JellyfinTunerHost {
  /// `Id`, for `liveTv.deleteTunerHost`.
  final String? id;

  /// `hdhomerun` or `m3u` (`Type`).
  final String? type;

  /// `Url`.
  final String? url;

  /// `DeviceId`.
  final String? deviceId;

  /// `FriendlyName`.
  final String? friendlyName;

  /// `TunerCount`.
  final int? tunerCount;

  /// `ImportFavoritesOnly`.
  final bool importFavoritesOnly;

  /// `AllowHWTranscoding`.
  final bool allowHwTranscoding;

  /// `AllowStreamSharing`.
  final bool allowStreamSharing;

  /// `UserAgent`.
  final String? userAgent;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a tuner host from already-parsed components.
  const JellyfinTunerHost({
    required this.importFavoritesOnly,
    required this.allowHwTranscoding,
    required this.allowStreamSharing,
    required this.raw,
    this.id,
    this.type,
    this.url,
    this.deviceId,
    this.friendlyName,
    this.tunerCount,
    this.userAgent,
  });

  /// Decodes a `TunerHostInfo`.
  factory JellyfinTunerHost.fromJson(Map<String, Object?> json) =>
      JellyfinTunerHost(
        id: asString(json['Id']),
        type: asString(json['Type']),
        url: asString(json['Url']),
        deviceId: asString(json['DeviceId']),
        friendlyName: asString(json['FriendlyName']),
        tunerCount: asInt(json['TunerCount']),
        importFavoritesOnly: json['ImportFavoritesOnly'] == true,
        allowHwTranscoding: json['AllowHWTranscoding'] == true,
        allowStreamSharing: json['AllowStreamSharing'] == true,
        userAgent: asString(json['UserAgent']),
        raw: json,
      );
}

/// A guide data source (`ListingsProviderInfo`).
final class JellyfinListingsProvider {
  /// `Id`, for `liveTv.deleteListingProvider`.
  final String? id;

  /// `SchedulesDirect` or `xmltv` (`Type`).
  final String? type;

  /// `ListingsId`.
  final String? listingsId;

  /// `Path`, for XMLTV.
  final String? path;

  /// `Country`.
  final String? country;

  /// `ZipCode`.
  final String? zipCode;

  /// `EnableAllTuners`.
  final bool enableAllTuners;

  /// `EnabledTuners`.
  final List<String> enabledTuners;

  /// `NewsCategories`.
  final List<String> newsCategories;

  /// `SportsCategories`.
  final List<String> sportsCategories;

  /// `KidsCategories`.
  final List<String> kidsCategories;

  /// `MovieCategories`.
  final List<String> movieCategories;

  /// `ChannelMappings`.
  final List<JellyfinNameValuePair> channelMappings;

  /// The decoded body; holds `Username` and `Password` when set.
  final Map<String, Object?> raw;

  /// Builds a listings provider from already-parsed components.
  const JellyfinListingsProvider({
    required this.enableAllTuners,
    required this.enabledTuners,
    required this.newsCategories,
    required this.sportsCategories,
    required this.kidsCategories,
    required this.movieCategories,
    required this.channelMappings,
    required this.raw,
    this.id,
    this.type,
    this.listingsId,
    this.path,
    this.country,
    this.zipCode,
  });

  /// Decodes a `ListingsProviderInfo`.
  factory JellyfinListingsProvider.fromJson(Map<String, Object?> json) =>
      JellyfinListingsProvider(
        id: asString(json['Id']),
        type: asString(json['Type']),
        listingsId: asString(json['ListingsId']),
        path: asString(json['Path']),
        country: asString(json['Country']),
        zipCode: asString(json['ZipCode']),
        enableAllTuners: json['EnableAllTuners'] == true,
        enabledTuners: asStringList(json['EnabledTuners']),
        newsCategories: asStringList(json['NewsCategories']),
        sportsCategories: asStringList(json['SportsCategories']),
        kidsCategories: asStringList(json['KidsCategories']),
        movieCategories: asStringList(json['MovieCategories']),
        channelMappings: asObjectList(
          json['ChannelMappings'],
          JellyfinNameValuePair.fromJson,
        ),
        raw: json,
      );
}
