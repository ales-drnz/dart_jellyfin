// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// System info
// ---------------------------------------------------------------------------

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

  /// Whether the server reports a password on the account.
  ///
  /// Jellyfin 12 marks `HasPassword` obsolete: it no longer carries
  /// useful information (it is `true` for every account) and may be
  /// dropped from the payload in a later release.
  @Deprecated('Obsolete in Jellyfin 12; the value is no longer meaningful.')
  final bool hasPassword;

  /// Whether the server reports a configured password.
  ///
  /// Obsolete in Jellyfin 12 alongside [hasPassword].
  @Deprecated('Obsolete in Jellyfin 12; the value is no longer meaningful.')
  final bool hasConfiguredPassword;

  /// Whether a numeric easy-password was configured.
  ///
  /// Jellyfin 12 removed the EasyPassword feature, so this is always
  /// `false` on 12.0 and the field is marked obsolete.
  @Deprecated('The EasyPassword feature was removed in Jellyfin 12.')
  final bool hasConfiguredEasyPassword;

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
    @Deprecated('Obsolete in Jellyfin 12; the value is no longer meaningful.')
    this.hasPassword = false,
    @Deprecated('Obsolete in Jellyfin 12; the value is no longer meaningful.')
    this.hasConfiguredPassword = false,
    @Deprecated('The EasyPassword feature was removed in Jellyfin 12.')
    this.hasConfiguredEasyPassword = false,
  });

  /// Decodes a `/Users/{id}` (or `/Users/Me`) payload.
  factory JellyfinUser.fromJson(Map<String, Object?> json) => JellyfinUser(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']) ?? '',
        serverId: asString(json['ServerId']),
        primaryImageTag: asString(json['PrimaryImageTag']),
        hasPassword: json['HasPassword'] == true,
        hasConfiguredPassword: json['HasConfiguredPassword'] == true,
        hasConfiguredEasyPassword: json['HasConfiguredEasyPassword'] == true,
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
          : const JellyfinUser(
              id: '',
              name: '',
              raw: <String, Object?>{},
            ),
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

// ---------------------------------------------------------------------------
// User views (library collections)
// ---------------------------------------------------------------------------

/// Jellyfin's "library" abstraction — what `/UserViews` returns.
///
/// `collectionType` is what tells you the library kind:
/// `'movies' | 'tvshows' | 'music' | 'musicvideos' | 'photos' | 'books' |
///  'livetv' | 'homevideos' | 'boxsets' | 'playlists' | 'folders' | null`.
final class JellyfinView {
  /// Stable server-side library id.
  final String id;

  /// Library display name.
  final String name;

  /// Library kind (`'music'`, `'movies'`, …); see class doc for full set.
  final String? collectionType;

  /// Image tag for the library's `Primary` poster.
  final String? primaryImageTag;

  /// Id of the server this library lives on.
  final String? serverId;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a view from already-parsed components.
  const JellyfinView({
    required this.id,
    required this.name,
    required this.raw,
    this.collectionType,
    this.primaryImageTag,
    this.serverId,
  });

  /// Decodes a `/UserViews` entry, flattening `ImageTags.Primary` for convenience.
  factory JellyfinView.fromJson(Map<String, Object?> json) {
    final tags = json['ImageTags'];
    return JellyfinView(
      id: asString(json['Id']) ?? '',
      name: asString(json['Name']) ?? '',
      collectionType: asString(json['CollectionType']),
      primaryImageTag: tags is Map ? asString(tags['Primary']) : null,
      serverId: asString(json['ServerId']),
      raw: json,
    );
  }

  /// `true` when this view holds music.
  bool get isMusic => collectionType == 'music';

  /// `true` when this view holds movies.
  bool get isMovies => collectionType == 'movies';

  /// `true` when this view holds TV shows.
  bool get isTvShows => collectionType == 'tvshows';

  /// `true` when this view holds photos.
  bool get isPhotos => collectionType == 'photos';
}
