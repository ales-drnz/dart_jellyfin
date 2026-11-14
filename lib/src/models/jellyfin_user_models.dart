// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

library;

import '../jellyfin_json.dart';

// ---------------------------------------------------------------------------
// Users & authentication
// ---------------------------------------------------------------------------

/// One Jellyfin user account.
final class JellyfinUser {
  /// Stable server-side user id (GUID).
  final String id;

  /// Display name shown in the login screen and headers.
  final String name;

  /// Id of the server this user belongs to.
  final String? serverId;

  /// Image tag for the user's avatar; combine with `/Users/{id}/Images/Primary`.
  final String? primaryImageTag;

  /// Last successful login timestamp, in UTC.
  final DateTime? lastLoginDate;

  /// Last activity timestamp, in UTC.
  final DateTime? lastActivityDate;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a user DTO from already-parsed components.
  const JellyfinUser({
    required this.id,
    required this.name,
    required this.raw,
    this.serverId,
    this.primaryImageTag,
    this.lastLoginDate,
    this.lastActivityDate,
  });

  @override
  String toString() => 'JellyfinUser($id, $name)';

  /// Decodes a `/Users/{id}` (or `/Users/Me`) payload.
  factory JellyfinUser.fromJson(Map<String, Object?> json) => JellyfinUser(
    id: asString(json['Id']) ?? '',
    name: asString(json['Name']) ?? '',
    serverId: asString(json['ServerId']),
    primaryImageTag: asString(json['PrimaryImageTag']),
    lastLoginDate: asUtcDateTime(json['LastLoginDate']),
    lastActivityDate: asUtcDateTime(json['LastActivityDate']),
    raw: json,
  );
}

/// Result of `POST /Users/AuthenticateByName` (and Quick Connect).
final class JellyfinAuthResult {
  /// Authenticated user record.
  final JellyfinUser user;

  /// Access token carried as `Token="…"` inside the
  /// `Authorization: MediaBrowser` header.
  final String accessToken;

  /// Id of the server that issued the token.
  final String serverId;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds an auth result from already-parsed components.
  const JellyfinAuthResult({
    required this.user,
    required this.accessToken,
    required this.serverId,
    required this.raw,
  });

  /// Decodes the envelope `{User, AccessToken, ServerId}`. A missing `User`
  /// is tolerated and replaced with a blank [JellyfinUser].
  factory JellyfinAuthResult.fromJson(Map<String, Object?> json) {
    final userJson = json['User'];
    return JellyfinAuthResult(
      user: userJson is Map<String, Object?>
          ? JellyfinUser.fromJson(userJson)
          : const JellyfinUser(id: '', name: '', raw: <String, Object?>{}),
      accessToken: asString(json['AccessToken']) ?? '',
      serverId: asString(json['ServerId']) ?? '',
      raw: json,
    );
  }
}

/// Result of `POST /QuickConnect/Initiate` and `GET /QuickConnect/Connect`.
final class JellyfinQuickConnectState {
  /// `true` once the user has approved the pairing on another device.
  final bool authenticated;

  /// Opaque secret used to poll `/QuickConnect/Connect`.
  final String secret;

  /// Short human-readable code displayed to the user for approval.
  final String code;

  /// Initiating device id, as supplied by this client.
  final String? deviceId;

  /// Initiating device display name.
  final String? deviceName;

  /// Initiating application name.
  final String? appName;

  /// Initiating application version.
  final String? appVersion;

  /// Timestamp when the pairing request was created, in UTC.
  final DateTime? dateAdded;

  /// Builds a quick-connect state from already-parsed components.
  const JellyfinQuickConnectState({
    required this.authenticated,
    required this.secret,
    required this.code,
    this.deviceId,
    this.deviceName,
    this.appName,
    this.appVersion,
    this.dateAdded,
  });

  /// Decodes a flat quick-connect state payload.
  factory JellyfinQuickConnectState.fromJson(Map<String, Object?> json) =>
      JellyfinQuickConnectState(
        authenticated: json['Authenticated'] == true,
        secret: asString(json['Secret']) ?? '',
        code: asString(json['Code']) ?? '',
        deviceId: asString(json['DeviceId']),
        deviceName: asString(json['DeviceName']),
        appName: asString(json['AppName']),
        appVersion: asString(json['AppVersion']),
        dateAdded: asUtcDateTime(json['DateAdded']),
      );
}
