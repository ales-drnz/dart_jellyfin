// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The server itself: its identity, clock, tasks, devices and activity log.
///
/// Every model keeps the decoded body in `raw`, so a field not lifted here
/// is still one map lookup away. Shapes were checked against Jellyfin 12.2
/// and 12.4 responses, not only the API document.
library;

import '../jellyfin_json.dart';

/// Subset of `/System/Info` describing the remote server build.
final class JellyfinSystemInfo {
  /// Stable server-side id.
  final String? id;

  /// Operator-configured display name.
  final String? serverName;

  /// Server build version (e.g. `'10.9.11'`).
  final String? version;

  /// Product brand string (typically `'Jellyfin Server'`).
  final String? productName;

  /// Host operating system identifier.
  final String? operatingSystem;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a system-info DTO from already-parsed components.
  const JellyfinSystemInfo({
    required this.raw,
    this.id,
    this.serverName,
    this.version,
    this.productName,
    this.operatingSystem,
  });

  /// Decodes the flat `/System/Info` payload.
  factory JellyfinSystemInfo.fromJson(Map<String, Object?> json) =>
      JellyfinSystemInfo(
        id: asString(json['Id']),
        serverName: asString(json['ServerName']),
        version: asString(json['Version']),
        productName: asString(json['ProductName']),
        operatingSystem: asString(json['OperatingSystem']),
        raw: json,
      );
}

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
        responseTransmissionTime: asUtcDateTime(
          json['ResponseTransmissionTime'],
        ),
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

  /// The task's key, stable across servers (`RefreshLibrary`, …).
  final String? key;

  /// The task's id on this server.
  final String? id;

  /// The task's display name.
  final String? name;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a task result from already-parsed components.
  const JellyfinTaskResult({
    required this.status,
    required this.raw,
    this.startTime,
    this.endTime,
    this.errorMessage,
    this.key,
    this.id,
    this.name,
  });

  /// Decodes a `TaskResult`.
  factory JellyfinTaskResult.fromJson(Map<String, Object?> json) =>
      JellyfinTaskResult(
        status: asString(json['Status']) ?? '',
        startTime: asUtcDateTime(json['StartTimeUtc']),
        endTime: asUtcDateTime(json['EndTimeUtc']),
        errorMessage: asString(json['ErrorMessage']),
        key: asString(json['Key']),
        id: asString(json['Id']),
        name: asString(json['Name']),
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
