// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';

/// `/Sessions/Playing/*` — playback reporting.
///
/// Jellyfin uses 100-nanosecond "ticks" everywhere. 1 ms = 10_000 ticks,
/// 1 s = 10_000_000 ticks. Helpers below convert from [Duration].
class JellyfinPlaybackApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinPlaybackApi(this._http);

  /// Report playback start (`POST /Sessions/Playing`).
  ///
  /// [method] is how the client plays the item (default
  /// [JellyfinPlayMethod.directPlay]); the `String` [playMethod] is
  /// deprecated.
  Future<void> start({
    required String itemId,
    String? playSessionId,
    String? mediaSourceId,
    JellyfinPlayMethod? method,
    @Deprecated('Use method (a JellyfinPlayMethod)') String? playMethod,
    bool canSeek = true,
  }) async {
    await _http.request<void>(
      '/Sessions/Playing',
      method: 'POST',
      data: {
        'ItemId': itemId,
        if (playSessionId != null) 'PlaySessionId': playSessionId,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
        'PlayMethod': _method(method, playMethod),
        'CanSeek': canSeek,
      },
    );
  }

  /// Report playback progress (`POST /Sessions/Playing/Progress`) — the
  /// heartbeat, recommended every 10 s, and on pause and resume.
  ///
  /// [method], [order] and [repeat] replace the deprecated `String`
  /// parameters [playMethod], [playbackOrder] and [repeatMode].
  Future<void> progress({
    required String itemId,
    required Duration position,
    required bool isPaused,
    int? volumeLevel,
    bool isMuted = false,
    String? playSessionId,
    String? mediaSourceId,
    JellyfinPlayMethod? method,
    JellyfinPlaybackOrder? order,
    JellyfinRepeatMode? repeat,
    @Deprecated('Use method (a JellyfinPlayMethod)') String? playMethod,
    @Deprecated('Use order (a JellyfinPlaybackOrder)') String? playbackOrder,
    @Deprecated('Use repeat (a JellyfinRepeatMode)') String? repeatMode,
  }) async {
    final effectiveOrder = _either(order?.wire, playbackOrder, 'order');
    final effectiveRepeat = _either(repeat?.wire, repeatMode, 'repeat');
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
        'PlayMethod': _method(method, playMethod),
        if (effectiveOrder != null) 'PlaybackOrder': effectiveOrder,
        if (effectiveRepeat != null) 'RepeatMode': effectiveRepeat,
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

  /// `POST /Sessions/Playing/Ping` — tell the server the transcode of
  /// [playSessionId] is still wanted.
  ///
  /// When it matters, measured on Jellyfin 12.0 with an HLS audio
  /// transcode (`hls.audioVariantUrl`):
  ///
  /// * The job is filed under the `DeviceId` of the stream URL. The
  ///   library's URL builders use the auth header's device id, so the job
  ///   shows on this client's session (`/Sessions` → `TranscodingInfo`)
  ///   and ping, [progress] and [stopped] reach it. A URL carrying another
  ///   device id (a constant) leaves the job attached to no session.
  /// * A paused session that sent one [progress] with `isPaused: true` and
  ///   then nothing kept its job for the 130 s observed, without ping, and
  ///   resumed at once.
  /// * With a ping every 10 s the job also stayed up (100 s observed);
  ///   [stopped] ends it.
  ///
  /// So a player that keeps sending [progress] every ~10 s, as
  /// recommended, needs no ping. Ping covers the stretches with nothing to
  /// report — a long pause longer than you want to trust, buffering before
  /// the first `start` — at the cost of one tiny request.
  Future<void> ping({required String playSessionId}) async {
    await _http.request<void>(
      '/Sessions/Playing/Ping',
      method: 'POST',
      queryParameters: {'playSessionId': playSessionId},
    );
  }

  static int _ticks(Duration d) => d.inMilliseconds * 10000;

  static String _method(JellyfinPlayMethod? method, String? legacy) =>
      _either(method?.wire, legacy, 'method') ??
      JellyfinPlayMethod.directPlay.wire;

  static String? _either(String? typed, String? legacy, String name) {
    if (typed != null && legacy != null) {
      throw ArgumentError(
        'Pass $name or its deprecated String form, not both.',
      );
    }
    return typed ?? legacy;
  }
}

/// How a client plays an item (`PlayMethod`).
enum JellyfinPlayMethod {
  /// The file as it is.
  directPlay('DirectPlay'),

  /// Remuxed into another container, streams copied.
  directStream('DirectStream'),

  /// Re-encoded by the server.
  transcode('Transcode');

  /// The wire value.
  final String wire;

  const JellyfinPlayMethod(this.wire);
}

/// Queue order (`PlaybackOrder`).
enum JellyfinPlaybackOrder {
  /// In order.
  defaultOrder('Default'),

  /// Shuffled.
  shuffle('Shuffle');

  /// The wire value.
  final String wire;

  const JellyfinPlaybackOrder(this.wire);
}

/// Repeat mode (`RepeatMode`).
enum JellyfinRepeatMode {
  /// No repeat.
  none('RepeatNone'),

  /// Repeat the queue.
  all('RepeatAll'),

  /// Repeat the current item.
  one('RepeatOne');

  /// The wire value.
  final String wire;

  const JellyfinRepeatMode(this.wire);
}
