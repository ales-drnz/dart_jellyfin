// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Search hints
// ---------------------------------------------------------------------------

/// One match from `/Search/Hints` — a lightweight pointer into the library.
final class JellyfinSearchHint {
  /// Id of the matched item.
  final String itemId;

  /// Display name of the matched item.
  final String? name;

  /// Substring of the query that triggered the match, when reported.
  final String? matchedTerm;

  /// `BaseItemKind` of the matched item.
  final String? type;

  /// `MediaType` of the matched item.
  final String? mediaType;

  /// Album-artist string, for audio hits.
  final String? albumArtist;

  /// Album title, for audio hits.
  final String? album;

  /// Id of the owning album, for audio hits.
  final String? albumId;

  /// All artist names, for audio hits.
  final List<String> artists;

  /// Duration in ticks (10_000 per millisecond).
  final int? runTimeTicks;

  /// Track/episode number within the parent, when applicable.
  final int? indexNumber;

  /// Disc/season number (parent index) within the parent, when applicable.
  final int? parentIndexNumber;

  /// Release year, when applicable.
  final int? productionYear;

  /// Image tag for the `Primary` image.
  final String? primaryImageTag;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a search hint from already-parsed components.
  const JellyfinSearchHint({
    required this.itemId,
    required this.artists,
    required this.raw,
    this.name,
    this.matchedTerm,
    this.type,
    this.mediaType,
    this.albumArtist,
    this.album,
    this.albumId,
    this.runTimeTicks,
    this.indexNumber,
    this.parentIndexNumber,
    this.productionYear,
    this.primaryImageTag,
  });

  /// Decodes a search-hint entry; accepts both `Id` and legacy `ItemId` keys.
  factory JellyfinSearchHint.fromJson(Map<String, Object?> json) =>
      JellyfinSearchHint(
        itemId: asString(json['Id']) ?? asString(json['ItemId']) ?? '',
        name: asString(json['Name']),
        matchedTerm: asString(json['MatchedTerm']),
        type: asString(json['Type']),
        mediaType: asString(json['MediaType']),
        albumArtist: asString(json['AlbumArtist']),
        album: asString(json['Album']),
        albumId: asString(json['AlbumId']),
        artists: asStringList(json['Artists']),
        runTimeTicks: asInt(json['RunTimeTicks']),
        indexNumber: asInt(json['IndexNumber']),
        parentIndexNumber: asInt(json['ParentIndexNumber']),
        productionYear: asInt(json['ProductionYear']),
        primaryImageTag: asString(json['PrimaryImageTag']),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Sessions (now playing / remote control)
// ---------------------------------------------------------------------------

/// One entry from `GET /Sessions`. The server reports every active
/// client (Jellyfin Web, Jellyfin Mobile, Jellyfin Media Player, …)
/// along with what it's currently playing.
///
/// Use [JellyfinSessionsApi.play] etc. with [JellyfinSession.id] to
/// cast or remote-control a target.
final class JellyfinSession {
  /// Stable session id; pass to `/Sessions/{id}/...` endpoints.
  final String id;

  /// Id of the user this session is signed in as.
  final String? userId;

  /// Display name of the signed-in user.
  final String? userName;

  /// Client application name (`'Jellyfin Web'`, `'Finova'`, …).
  final String? client;

  /// Client-supplied device id.
  final String? deviceId;

  /// Client-supplied device display name.
  final String? deviceName;

  /// Client application version.
  final String? applicationVersion;

  /// Client's reported remote IP/host.
  final String? remoteEndPoint;

  /// Last activity timestamp from the client, in UTC.
  final DateTime? lastActivityDate;

  /// Last playback check-in timestamp, in UTC.
  final DateTime? lastPlaybackCheckIn;

  /// `true` when the server still considers the session live.
  final bool isActive;

  /// `true` when the client accepts play/pause/seek commands.
  final bool supportsMediaControl;

  /// `true` when the client accepts arbitrary remote-control commands.
  final bool supportsRemoteControl;

  /// `MediaType` strings the client can play (`'Audio'`, `'Video'`, …).
  final List<String> playableMediaTypes;

  /// `GeneralCommandType` names the client advertises support for.
  final List<String> supportedCommands;

  /// `NowPlayingItem` parsed as a [JellyfinItem]. Null when the session
  /// isn't playing anything.
  final JellyfinItem? nowPlayingItem;

  /// `PlayState` — `PositionTicks`, `IsPaused`, `IsMuted`, `VolumeLevel`,
  /// `AudioStreamIndex`, `SubtitleStreamIndex`, `PlayMethod`,
  /// `RepeatMode`, `PlaybackOrder`.
  final Map<String, Object?>? playState;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a session from already-parsed components.
  const JellyfinSession({
    required this.id,
    required this.isActive,
    required this.supportsMediaControl,
    required this.supportsRemoteControl,
    required this.playableMediaTypes,
    required this.supportedCommands,
    required this.raw,
    this.userId,
    this.userName,
    this.client,
    this.deviceId,
    this.deviceName,
    this.applicationVersion,
    this.remoteEndPoint,
    this.lastActivityDate,
    this.lastPlaybackCheckIn,
    this.nowPlayingItem,
    this.playState,
  });

  /// Decodes a `/Sessions` entry, recursing into `NowPlayingItem` when present.
  factory JellyfinSession.fromJson(Map<String, Object?> json) {
    final npi = json['NowPlayingItem'];
    return JellyfinSession(
      id: asString(json['Id']) ?? '',
      userId: asString(json['UserId']),
      userName: asString(json['UserName']),
      client: asString(json['Client']),
      deviceId: asString(json['DeviceId']),
      deviceName: asString(json['DeviceName']),
      applicationVersion: asString(json['ApplicationVersion']),
      remoteEndPoint: asString(json['RemoteEndPoint']),
      lastActivityDate: asUtcDateTime(json['LastActivityDate']),
      lastPlaybackCheckIn: asUtcDateTime(json['LastPlaybackCheckIn']),
      isActive: json['IsActive'] == true,
      supportsMediaControl: json['SupportsMediaControl'] == true,
      supportsRemoteControl: json['SupportsRemoteControl'] == true,
      playableMediaTypes: asStringList(json['PlayableMediaTypes']),
      supportedCommands: asStringList(json['SupportedCommands']),
      nowPlayingItem:
          npi is Map<String, Object?> ? JellyfinItem.fromJson(npi) : null,
      playState: json['PlayState'] is Map<String, Object?>
          ? json['PlayState'] as Map<String, Object?>
          : null,
      raw: json,
    );
  }

  /// `true` when this session is actively playing media.
  bool get isPlaying => nowPlayingItem != null;
}
