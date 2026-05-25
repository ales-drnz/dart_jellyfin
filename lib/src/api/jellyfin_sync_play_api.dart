// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/SyncPlay/*` — synchronised playback across multiple clients.
///
/// SyncPlay groups multiple Jellyfin sessions so they advance their
/// playback in lock-step ("watch party"). One client creates a group,
/// others join; pause/seek/track-change actions propagate to every
/// member.
///
/// Wraps the consumer-facing slice of the `SyncPlay` OpenAPI tag
/// (22 operations upstream; this wrapper covers the ~16 a typical
/// client needs). Admin-only knobs (access policies, IgnoreWait)
/// stay behind the escape hatch.
class JellyfinSyncPlayApi {
  final JellyfinConnection _http;

  JellyfinSyncPlayApi(this._http);

  // ─── Discovery ─────────────────────────────────────────────────────

  /// `GET /SyncPlay/List` — list groups the current user can join.
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _http.request<List<dynamic>>('/SyncPlay/List');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  // ─── Group lifecycle ───────────────────────────────────────────────

  /// `POST /SyncPlay/New` — create a new group.
  Future<void> createGroup({required String groupName}) async {
    await _http.request<void>(
      '/SyncPlay/New',
      method: 'POST',
      data: {'GroupName': groupName},
    );
  }

  /// `POST /SyncPlay/Join` — join a group.
  Future<void> joinGroup({required String groupId}) async {
    await _http.request<void>(
      '/SyncPlay/Join',
      method: 'POST',
      data: {'GroupId': groupId},
    );
  }

  /// `POST /SyncPlay/Leave` — leave the current group.
  Future<void> leaveGroup() async {
    await _http.request<void>('/SyncPlay/Leave', method: 'POST');
  }

  // ─── Playback control (all group members react) ────────────────────

  /// `POST /SyncPlay/Pause` — pause every client in the group.
  Future<void> pause() async {
    await _http.request<void>('/SyncPlay/Pause', method: 'POST');
  }

  /// `POST /SyncPlay/Unpause` — resume every client.
  Future<void> unpause() async {
    await _http.request<void>('/SyncPlay/Unpause', method: 'POST');
  }

  /// `POST /SyncPlay/Stop` — stop and clear the queue.
  Future<void> stop() async {
    await _http.request<void>('/SyncPlay/Stop', method: 'POST');
  }

  /// `POST /SyncPlay/Seek` — seek every client to [positionTicks].
  Future<void> seek({required int positionTicks}) async {
    await _http.request<void>(
      '/SyncPlay/Seek',
      method: 'POST',
      data: {'PositionTicks': positionTicks},
    );
  }

  // ─── Queue ─────────────────────────────────────────────────────────

  /// `POST /SyncPlay/Queue` — replace the group queue (the items every
  /// member will play, in order).
  ///
  /// [mode] is `'Default' | 'Next' | 'Last'` — see the upstream
  /// `PlayMode` enum.
  Future<void> queue({
    required List<String> itemIds,
    String mode = 'Default',
  }) async {
    await _http.request<void>(
      '/SyncPlay/Queue',
      method: 'POST',
      data: {
        'ItemIds': itemIds,
        'Mode': mode,
      },
    );
  }

  /// `POST /SyncPlay/NextItem`.
  Future<void> nextItem({required String playlistItemId}) async {
    await _http.request<void>(
      '/SyncPlay/NextItem',
      method: 'POST',
      data: {'PlaylistItemId': playlistItemId},
    );
  }

  /// `POST /SyncPlay/PreviousItem`.
  Future<void> previousItem({required String playlistItemId}) async {
    await _http.request<void>(
      '/SyncPlay/PreviousItem',
      method: 'POST',
      data: {'PlaylistItemId': playlistItemId},
    );
  }

  /// `POST /SyncPlay/SetPlaylistItem` — jump to a specific entry.
  Future<void> setPlaylistItem({required String playlistItemId}) async {
    await _http.request<void>(
      '/SyncPlay/SetPlaylistItem',
      method: 'POST',
      data: {'PlaylistItemId': playlistItemId},
    );
  }

  /// `POST /SyncPlay/MovePlaylistItem` — reorder one entry.
  Future<void> movePlaylistItem({
    required String playlistItemId,
    required int newIndex,
  }) async {
    await _http.request<void>(
      '/SyncPlay/MovePlaylistItem',
      method: 'POST',
      data: {
        'PlaylistItemId': playlistItemId,
        'NewIndex': newIndex,
      },
    );
  }

  /// `POST /SyncPlay/RemoveFromPlaylist` — remove a list of entries.
  Future<void> removeFromPlaylist({
    required List<String> playlistItemIds,
  }) async {
    await _http.request<void>(
      '/SyncPlay/RemoveFromPlaylist',
      method: 'POST',
      data: {'PlaylistItemIds': playlistItemIds},
    );
  }

  // ─── Group settings ────────────────────────────────────────────────

  /// `POST /SyncPlay/SetRepeatMode` — `RepeatNone | RepeatAll |
  /// RepeatOne`.
  Future<void> setRepeatMode({required String mode}) async {
    await _http.request<void>(
      '/SyncPlay/SetRepeatMode',
      method: 'POST',
      data: {'Mode': mode},
    );
  }

  /// `POST /SyncPlay/SetShuffleMode` — `Sorted | Shuffle`.
  Future<void> setShuffleMode({required String mode}) async {
    await _http.request<void>(
      '/SyncPlay/SetShuffleMode',
      method: 'POST',
      data: {'Mode': mode},
    );
  }

  // ─── Sync / heartbeat ──────────────────────────────────────────────

  /// `POST /SyncPlay/Ping` — measure clock skew between this client
  /// and the server.
  Future<void> ping({required int ping}) async {
    await _http.request<void>(
      '/SyncPlay/Ping',
      method: 'POST',
      data: {'Ping': ping},
    );
  }

  /// `POST /SyncPlay/Buffering` — tell the server this client started
  /// buffering. The group either waits (default) or proceeds without
  /// it (admin policy).
  Future<void> buffering({
    required String playlistItemId,
    required int positionTicks,
    required bool isPlaying,
  }) async {
    await _http.request<void>(
      '/SyncPlay/Buffering',
      method: 'POST',
      data: {
        'When': DateTime.now().toUtc().toIso8601String(),
        'PlaylistItemId': playlistItemId,
        'PositionTicks': positionTicks,
        'IsPlaying': isPlaying,
      },
    );
  }

  /// `POST /SyncPlay/Ready` — declare this client ready to resume.
  Future<void> ready({
    required String playlistItemId,
    required int positionTicks,
    required bool isPlaying,
  }) async {
    await _http.request<void>(
      '/SyncPlay/Ready',
      method: 'POST',
      data: {
        'When': DateTime.now().toUtc().toIso8601String(),
        'PlaylistItemId': playlistItemId,
        'PositionTicks': positionTicks,
        'IsPlaying': isPlaying,
      },
    );
  }

  /// `POST /SyncPlay/SetIgnoreWait` — toggle the server's
  /// "ignore wait" behaviour for a sluggish client in the group.
  Future<void> setIgnoreWait({required bool ignoreWait}) async {
    await _http.request<void>(
      '/SyncPlay/SetIgnoreWait',
      method: 'POST',
      data: {'IgnoreWait': ignoreWait},
    );
  }

  /// `GET /SyncPlay/{id}` — fetch a single SyncPlay group by id.
  Future<Map<String, dynamic>> group(String id) async {
    final res = await _http.request<Map<String, dynamic>>('/SyncPlay/$id');
    return res.data ?? const {};
  }

  /// `POST /SyncPlay/SetNewQueue` — replace the group's playback
  /// queue with a new set of items.
  Future<void> setNewQueue({
    required List<String> playingQueue,
    int? playingItemPosition,
    int? startPositionTicks,
  }) async {
    final body = <String, dynamic>{
      'PlayingQueue': playingQueue,
    };
    if (playingItemPosition != null) {
      body['PlayingItemPosition'] = playingItemPosition;
    }
    if (startPositionTicks != null) {
      body['StartPositionTicks'] = startPositionTicks;
    }
    await _http.request<void>(
      '/SyncPlay/SetNewQueue',
      method: 'POST',
      data: body,
    );
  }
}
