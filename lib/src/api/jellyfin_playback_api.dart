// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Sessions/Playing/*` — playback reporting.
///
/// Jellyfin uses 100-nanosecond "ticks" everywhere. 1 ms = 10_000 ticks,
/// 1 s = 10_000_000 ticks. Helpers below convert from [Duration].
class JellyfinPlaybackApi {
  final JellyfinConnection _http;

  JellyfinPlaybackApi(this._http);

  /// Report playback start.
  Future<void> start({
    required String itemId,
    String? playSessionId,
    String? mediaSourceId,
    String playMethod = 'DirectPlay', // DirectPlay | DirectStream | Transcode
    bool canSeek = true,
  }) async {
    await _http.request<void>(
      '/Sessions/Playing',
      method: 'POST',
      data: {
        'ItemId': itemId,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        'PlayMethod': playMethod,
        'CanSeek': canSeek,
      },
    );
  }

  /// Report playback progress (heartbeat). Recommended every 10 s.
  Future<void> progress({
    required String itemId,
    required Duration position,
    required bool isPaused,
    int? volumeLevel,
    bool isMuted = false,
    String? playSessionId,
    String? mediaSourceId,
    String playMethod = 'DirectPlay',
    String? playbackOrder, // Default | Shuffle
    String? repeatMode, // RepeatNone | RepeatAll | RepeatOne
  }) async {
    await _http.request<void>(
      '/Sessions/Playing/Progress',
      method: 'POST',
      data: {
        'ItemId': itemId,
        'PositionTicks': _ticks(position),
        'IsPaused': isPaused,
        'IsMuted': isMuted,
        if (volumeLevel != null) 'VolumeLevel': volumeLevel,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        'PlayMethod': playMethod,
        if (playbackOrder != null) 'PlaybackOrder': playbackOrder,
        if (repeatMode != null) 'RepeatMode': repeatMode,
      },
    );
  }

  /// Report playback stopped.
  Future<void> stopped({
    required String itemId,
    required Duration position,
    String? playSessionId,
    String? mediaSourceId,
  }) async {
    await _http.request<void>(
      '/Sessions/Playing/Stopped',
      method: 'POST',
      data: {
        'ItemId': itemId,
        'PositionTicks': _ticks(position),
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      },
    );
  }

  /// Keep an active transcode session alive while the player buffers.
  Future<void> ping({required String playSessionId}) async {
    await _http.request<void>(
      '/Sessions/Playing/Ping',
      method: 'POST',
      queryParameters: {'playSessionId': playSessionId},
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy `/PlayingItems/{id}` aliases (Playstate tag)
  // ---------------------------------------------------------------------------

  /// `POST /PlayingItems/{itemId}` — legacy alias for [start].
  /// Modern clients should prefer the `/Sessions/Playing` endpoints,
  /// but older PMS/Plex-style integrations still use this path.
  Future<void> legacyStart({
    required String itemId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String playMethod = 'DirectPlay',
    String? liveStreamId,
    String? playSessionId,
    bool canSeek = true,
  }) async {
    final qp = <String, dynamic>{
      'playMethod': playMethod,
      'canSeek': canSeek,
    };
    if (mediaSourceId != null) qp['mediaSourceId'] = mediaSourceId;
    if (audioStreamIndex != null) qp['audioStreamIndex'] = audioStreamIndex;
    if (subtitleStreamIndex != null) {
      qp['subtitleStreamIndex'] = subtitleStreamIndex;
    }
    if (liveStreamId != null) qp['liveStreamId'] = liveStreamId;
    if (playSessionId != null) qp['playSessionId'] = playSessionId;
    await _http.request<void>(
      '/PlayingItems/$itemId',
      method: 'POST',
      queryParameters: qp,
    );
  }

  /// `POST /PlayingItems/{itemId}/Progress` — legacy alias for
  /// [progress].
  Future<void> legacyProgress({
    required String itemId,
    required Duration position,
    bool isPaused = false,
    bool isMuted = false,
    String? mediaSourceId,
    String? playSessionId,
  }) async {
    final qp = <String, dynamic>{
      'positionTicks': _ticks(position),
      'isPaused': isPaused,
      'isMuted': isMuted,
    };
    if (mediaSourceId != null) qp['mediaSourceId'] = mediaSourceId;
    if (playSessionId != null) qp['playSessionId'] = playSessionId;
    await _http.request<void>(
      '/PlayingItems/$itemId/Progress',
      method: 'POST',
      queryParameters: qp,
    );
  }

  /// `DELETE /PlayingItems/{itemId}` — legacy alias for [stopped].
  Future<void> legacyStopped({
    required String itemId,
    Duration? position,
    String? mediaSourceId,
    String? playSessionId,
  }) async {
    final qp = <String, dynamic>{};
    if (position != null) qp['positionTicks'] = _ticks(position);
    if (mediaSourceId != null) qp['mediaSourceId'] = mediaSourceId;
    if (playSessionId != null) qp['playSessionId'] = playSessionId;
    await _http.request<void>(
      '/PlayingItems/$itemId',
      method: 'DELETE',
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  static int _ticks(Duration d) => d.inMilliseconds * 10000;
}
