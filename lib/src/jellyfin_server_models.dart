// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Typed answers of the server, device and housekeeping endpoints.
///
/// Every model keeps the decoded body in `raw`, so a field not lifted here
/// is still one map lookup away. Shapes were checked against Jellyfin 12.2
/// responses, not only the API document.
library;

import 'jellyfin_json.dart';
import 'jellyfin_models.dart';

/// How the server sees this client's connection (`/System/Endpoint`).
final class JellyfinEndpointInfo {
  /// The request came from the server's own machine.
  final bool isLocal;

  /// The request came from inside the server's LAN.
  final bool isInNetwork;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds an endpoint info from already-parsed components.
  const JellyfinEndpointInfo({
    required this.isLocal,
    required this.isInNetwork,
    required this.raw,
  });

  /// Decodes `{IsLocal, IsInNetwork}`.
  factory JellyfinEndpointInfo.fromJson(Map<String, Object?> json) =>
      JellyfinEndpointInfo(
        isLocal: json['IsLocal'] == true,
        isInNetwork: json['IsInNetwork'] == true,
        raw: json,
      );
}

/// The server clock (`/GetUtcTime`), for clock-skew correction.
final class JellyfinUtcTime {
  /// When the server received the request.
  final DateTime? requestReceptionTime;

  /// When the server sent the answer.
  final DateTime? responseTransmissionTime;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a server time from already-parsed components.
  const JellyfinUtcTime({
    required this.requestReceptionTime,
    required this.responseTransmissionTime,
    required this.raw,
  });

  /// Decodes `{RequestReceptionTime, ResponseTransmissionTime}`.
  factory JellyfinUtcTime.fromJson(Map<String, Object?> json) =>
      JellyfinUtcTime(
        requestReceptionTime: asUtcDateTime(json['RequestReceptionTime']),
        responseTransmissionTime:
            asUtcDateTime(json['ResponseTransmissionTime']),
        raw: json,
      );
}

/// How many items of each kind a user can see (`/Items/Counts`).
final class JellyfinItemCounts {
  /// Tracks (`SongCount`).
  final int songCount;

  /// Albums (`AlbumCount`).
  final int albumCount;

  /// Artists (`ArtistCount`).
  final int artistCount;

  /// Music videos (`MusicVideoCount`).
  final int musicVideoCount;

  /// Movies (`MovieCount`).
  final int movieCount;

  /// Series (`SeriesCount`).
  final int seriesCount;

  /// Episodes (`EpisodeCount`).
  final int episodeCount;

  /// Collections (`BoxSetCount`).
  final int boxSetCount;

  /// Books (`BookCount`).
  final int bookCount;

  /// Every item (`ItemCount`).
  final int itemCount;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds item counts from already-parsed components.
  const JellyfinItemCounts({
    required this.songCount,
    required this.albumCount,
    required this.artistCount,
    required this.musicVideoCount,
    required this.movieCount,
    required this.seriesCount,
    required this.episodeCount,
    required this.boxSetCount,
    required this.bookCount,
    required this.itemCount,
    required this.raw,
  });

  /// Decodes an `ItemCounts` body; a missing count is 0.
  factory JellyfinItemCounts.fromJson(Map<String, Object?> json) =>
      JellyfinItemCounts(
        songCount: asInt(json['SongCount']) ?? 0,
        albumCount: asInt(json['AlbumCount']) ?? 0,
        artistCount: asInt(json['ArtistCount']) ?? 0,
        musicVideoCount: asInt(json['MusicVideoCount']) ?? 0,
        movieCount: asInt(json['MovieCount']) ?? 0,
        seriesCount: asInt(json['SeriesCount']) ?? 0,
        episodeCount: asInt(json['EpisodeCount']) ?? 0,
        boxSetCount: asInt(json['BoxSetCount']) ?? 0,
        bookCount: asInt(json['BookCount']) ?? 0,
        itemCount: asInt(json['ItemCount']) ?? 0,
        raw: json,
      );
}

/// A scheduled task (`TaskInfo`) — library scans, "Audio Normalization"
/// (which fills `JellyfinItem.normalizationGain` in libraries with
/// `EnableLUFSScan` on), image extraction, …
final class JellyfinScheduledTask {
  /// Task id, for `scheduledTasks.start` / `stop`.
  final String id;

  /// Stable key, e.g. `AudioNormalization`, `RefreshLibrary`.
  final String key;

  /// Display name.
  final String name;

  /// `Idle`, `Cancelling` or `Running`.
  final String state;

  /// Progress 0–100 while [isRunning].
  final double? currentProgressPercentage;

  /// e.g. `Library`, `Maintenance`.
  final String? category;

  /// What the task does.
  final String? description;

  /// Hidden from the dashboard.
  final bool isHidden;

  /// The last run, when there was one.
  final JellyfinTaskResult? lastExecutionResult;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a task from already-parsed components.
  const JellyfinScheduledTask({
    required this.id,
    required this.key,
    required this.name,
    required this.state,
    required this.isHidden,
    required this.raw,
    this.currentProgressPercentage,
    this.category,
    this.description,
    this.lastExecutionResult,
  });

  /// Decodes a `TaskInfo`.
  factory JellyfinScheduledTask.fromJson(Map<String, Object?> json) {
    final last = json['LastExecutionResult'];
    return JellyfinScheduledTask(
      id: asString(json['Id']) ?? '',
      key: asString(json['Key']) ?? '',
      name: asString(json['Name']) ?? '',
      state: asString(json['State']) ?? '',
      currentProgressPercentage: asDouble(json['CurrentProgressPercentage']),
      category: asString(json['Category']),
      description: asString(json['Description']),
      isHidden: json['IsHidden'] == true,
      lastExecutionResult: last is Map<String, Object?>
          ? JellyfinTaskResult.fromJson(last)
          : null,
      raw: json,
    );
  }

  /// The task is running now.
  bool get isRunning => state == 'Running';
}

/// The outcome of a [JellyfinScheduledTask] run (`TaskResult`).
final class JellyfinTaskResult {
  /// `Completed`, `Failed`, `Cancelled` or `Aborted`.
  final String status;

  /// When the run started.
  final DateTime? startTime;

  /// When the run ended.
  final DateTime? endTime;

  /// The error, for a failed run.
  final String? errorMessage;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a task result from already-parsed components.
  const JellyfinTaskResult({
    required this.status,
    required this.raw,
    this.startTime,
    this.endTime,
    this.errorMessage,
  });

  /// Decodes a `TaskResult`.
  factory JellyfinTaskResult.fromJson(Map<String, Object?> json) =>
      JellyfinTaskResult(
        status: asString(json['Status']) ?? '',
        startTime: asUtcDateTime(json['StartTimeUtc']),
        endTime: asUtcDateTime(json['EndTimeUtc']),
        errorMessage: asString(json['ErrorMessage']),
        raw: json,
      );
}

/// A device that has signed in (`DeviceInfoDto`).
final class JellyfinDevice {
  /// Device id — the `DeviceId` of its auth header.
  final String id;

  /// Device name as reported.
  final String? name;

  /// Name the admin gave it, when set.
  final String? customName;

  /// Client app name.
  final String? appName;

  /// Client app version.
  final String? appVersion;

  /// Last user on the device.
  final String? lastUserName;

  /// That user's id.
  final String? lastUserId;

  /// Last activity.
  final DateTime? dateLastActivity;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a device from already-parsed components.
  const JellyfinDevice({
    required this.id,
    required this.raw,
    this.name,
    this.customName,
    this.appName,
    this.appVersion,
    this.lastUserName,
    this.lastUserId,
    this.dateLastActivity,
  });

  /// Decodes a `DeviceInfoDto`.
  factory JellyfinDevice.fromJson(Map<String, Object?> json) => JellyfinDevice(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        customName: asString(json['CustomName']),
        appName: asString(json['AppName']),
        appVersion: asString(json['AppVersion']),
        lastUserName: asString(json['LastUserName']),
        lastUserId: asString(json['LastUserId']),
        dateLastActivity: asUtcDateTime(json['DateLastActivity']),
        raw: json,
      );
}

/// One entry of the server activity log (`ActivityLogEntry`).
final class JellyfinActivityLogEntry {
  /// Entry id.
  final int id;

  /// e.g. `test_admin has finished playing Test Artist - Track 1 on …`.
  final String name;

  /// e.g. `AudioPlaybackStopped`, `SessionStarted`.
  final String type;

  /// When it happened.
  final DateTime? date;

  /// The item concerned, when there is one.
  final String? itemId;

  /// The user concerned, when there is one.
  final String? userId;

  /// `Information`, `Warning`, `Error`, …
  final String? severity;

  /// Longer text, when sent.
  final String? overview;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a log entry from already-parsed components.
  const JellyfinActivityLogEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.raw,
    this.date,
    this.itemId,
    this.userId,
    this.severity,
    this.overview,
  });

  /// Decodes an `ActivityLogEntry`.
  factory JellyfinActivityLogEntry.fromJson(Map<String, Object?> json) =>
      JellyfinActivityLogEntry(
        id: asInt(json['Id']) ?? 0,
        name: asString(json['Name']) ?? '',
        type: asString(json['Type']) ?? '',
        date: asUtcDateTime(json['Date']),
        itemId: asString(json['ItemId']),
        userId: asString(json['UserId']),
        severity: asString(json['Severity']),
        overview: asString(json['Overview']),
        raw: json,
      );
}

/// One image of an item (`ImageInfo`, from `images.listItemImages`).
final class JellyfinImageInfo {
  /// `Primary`, `Backdrop`, `Logo`, …
  final String type;

  /// Index among images of the same type, when there are several.
  final int? index;

  /// Image tag — the version to pass as `tag`.
  final String? tag;

  /// BlurHash placeholder.
  final String? blurHash;

  /// Pixel width.
  final int? width;

  /// Pixel height.
  final int? height;

  /// File size in bytes.
  final int? size;

  /// Path on the server.
  final String? path;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds an image info from already-parsed components.
  const JellyfinImageInfo({
    required this.type,
    required this.raw,
    this.index,
    this.tag,
    this.blurHash,
    this.width,
    this.height,
    this.size,
    this.path,
  });

  /// Decodes an `ImageInfo`.
  factory JellyfinImageInfo.fromJson(Map<String, Object?> json) =>
      JellyfinImageInfo(
        type: asString(json['ImageType']) ?? '',
        index: asInt(json['ImageIndex']),
        tag: asString(json['ImageTag']),
        blurHash: asString(json['BlurHash']),
        width: asInt(json['Width']),
        height: asInt(json['Height']),
        size: asInt(json['Size']),
        path: asString(json['Path']),
        raw: json,
      );
}

/// A lyric found by a lyric provider plugin (`RemoteLyricInfoDto`).
final class JellyfinRemoteLyric {
  /// Id to pass to `lyrics.downloadRemote` / `previewRemote`.
  final String id;

  /// The provider that found it.
  final String? providerName;

  /// The lyric itself, when the provider sent it with the result.
  final JellyfinLyrics? lyrics;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a remote lyric from already-parsed components.
  const JellyfinRemoteLyric({
    required this.id,
    required this.raw,
    this.providerName,
    this.lyrics,
  });

  /// Decodes a `RemoteLyricInfoDto`.
  factory JellyfinRemoteLyric.fromJson(Map<String, Object?> json) {
    final lyrics = json['Lyrics'];
    return JellyfinRemoteLyric(
      id: asString(json['Id']) ?? '',
      providerName: asString(json['ProviderName']),
      lyrics: lyrics is Map<String, Object?>
          ? JellyfinLyrics.fromJson(lyrics)
          : null,
      raw: json,
    );
  }
}

/// A SyncPlay group (`GroupInfoDto`).
final class JellyfinSyncPlayGroup {
  /// Group id.
  final String id;

  /// Group name.
  final String name;

  /// `Idle`, `Waiting`, `Paused` or `Playing`.
  final String state;

  /// Display names of the participants.
  final List<String> participants;

  /// When the group last changed.
  final DateTime? lastUpdatedAt;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a group from already-parsed components.
  const JellyfinSyncPlayGroup({
    required this.id,
    required this.name,
    required this.state,
    required this.participants,
    required this.raw,
    this.lastUpdatedAt,
  });

  /// Decodes a `GroupInfoDto`.
  factory JellyfinSyncPlayGroup.fromJson(Map<String, Object?> json) =>
      JellyfinSyncPlayGroup(
        id: asString(json['GroupId']) ?? '',
        name: asString(json['GroupName']) ?? '',
        state: asString(json['State']) ?? '',
        participants: [
          if (json['Participants'] is List)
            for (final p in json['Participants'] as List)
              if (p != null) '$p',
        ],
        lastUpdatedAt: asUtcDateTime(json['LastUpdatedAt']),
        raw: json,
      );
}

/// A user's access to a shared playlist (`PlaylistUserPermissions`).
final class JellyfinPlaylistUserPermission {
  /// The user.
  final String userId;

  /// Whether the user may edit the playlist.
  final bool canEdit;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a permission from already-parsed components.
  const JellyfinPlaylistUserPermission({
    required this.userId,
    required this.canEdit,
    required this.raw,
  });

  /// Decodes `{UserId, CanEdit}`.
  factory JellyfinPlaylistUserPermission.fromJson(Map<String, Object?> json) =>
      JellyfinPlaylistUserPermission(
        userId: asString(json['UserId']) ?? '',
        canEdit: json['CanEdit'] == true,
        raw: json,
      );
}
