// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../api/jellyfin_sessions_api.dart';
library;

import '../jellyfin_json.dart';
import 'jellyfin_item_models.dart';

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

  /// The client's play queue (`NowPlayingQueue`), as item ids. Jellyfin 12
  /// removed `NowPlayingQueueFullItems`, so the queue no longer carries
  /// the items themselves: fetch them with `items.list(ids:)`.
  final List<JellyfinQueueItem> nowPlayingQueue;

  /// The queue entry playing now (`PlaylistItemId`), matching the
  /// [JellyfinQueueItem.playlistItemId] of one of [nowPlayingQueue].
  ///
  /// A queue entry id, a plain `String`: not the
  /// [JellyfinPlaylistEntryId] of [JellyfinItem.playlistItemId], which
  /// names an entry of a playlist item.
  final String? playlistItemId;

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
    this.nowPlayingQueue = const [],
    this.playlistItemId,
  });

  @override
  String toString() =>
      'JellyfinSession($id, ${client ?? '?'} on ${deviceName ?? '?'})';

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
      nowPlayingItem: npi is Map<String, Object?>
          ? JellyfinItem.fromJson(npi)
          : null,
      playState: json['PlayState'] is Map<String, Object?>
          ? json['PlayState'] as Map<String, Object?>
          : null,
      nowPlayingQueue: asObjectList(
        json['NowPlayingQueue'],
        JellyfinQueueItem.fromJson,
      ),
      playlistItemId: asString(json['PlaylistItemId']),
      raw: json,
    );
  }

  /// `true` when this session is actively playing media.
  bool get isPlaying => nowPlayingItem != null;
}

/// One entry of [JellyfinSession.nowPlayingQueue] (`QueueItem`).
final class JellyfinQueueItem {
  /// The item (`Id`).
  final String itemId;

  /// The entry's id in the queue (`PlaylistItemId`), which tells apart two
  /// entries of the same item. A queue entry id, not a
  /// [JellyfinPlaylistEntryId].
  final String? playlistItemId;

  /// The entry as the server sent it.
  final Map<String, Object?> raw;

  /// Builds a queue entry from already-parsed components.
  const JellyfinQueueItem({
    required this.itemId,
    required this.raw,
    this.playlistItemId,
  });

  /// Decodes a `{Id, PlaylistItemId}` entry.
  factory JellyfinQueueItem.fromJson(Map<String, Object?> json) =>
      JellyfinQueueItem(
        itemId: asString(json['Id']) ?? '',
        playlistItemId: asString(json['PlaylistItemId']),
        raw: json,
      );
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
