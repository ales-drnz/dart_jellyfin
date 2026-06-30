// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Items/{itemId}/PlaybackInfo` and `/LiveStreams/Open|Close`.
///
/// Real device-profile negotiation. The server inspects the supplied
/// [JellyfinDeviceProfile] (codecs the client can decode, max bitrate,
/// supported containers, …) and returns one [JellyfinPlaybackInfo]
/// whose `mediaSources` already carries `supportsDirectPlay`,
/// `supportsDirectStream`, `supportsTranscoding` and the
/// `transcodingUrl` to use.
///
/// **Use this before [JellyfinVideosApi.streamUrl] or
/// [JellyfinAudioApi.universalStreamUrl] for any video session** — the
/// universal endpoints work for audio because the server's defaults are
/// good enough for music, but video transcoding decisions depend on
/// codec compatibility that only the device profile knows.
class JellyfinMediaInfoApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinMediaInfoApi(this._http);

  /// GET `/Items/{itemId}/PlaybackInfo`. Lightweight — server uses
  /// generic defaults instead of a device profile.
  ///
  /// The GET operation accepts only `itemId` and `userId`; it cannot honor
  /// bitrate/stream pinning or live-stream auto-open. Use [postedInfo] (the
  /// POST variant) when you need to pin a bitrate, audio/subtitle stream, or
  /// auto-open a live stream.
  Future<JellyfinPlaybackInfo> info({
    required String itemId,
    String? userId,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Items/$itemId/PlaybackInfo',
      queryParameters: {'userId': userId ?? _http.userId},
    );
    return JellyfinPlaybackInfo.fromJson(res.data ?? const {});
  }

  /// POST `/Items/{itemId}/PlaybackInfo`. **Use this for video** — the
  /// JSON body carries the full [JellyfinDeviceProfile] describing what
  /// the client can decode, so the server returns realistic direct-play
  /// decisions.
  ///
  /// The minimal body is `{ "UserId": "…", "DeviceProfile": { … } }`;
  /// all the other fields are optional pinning knobs (see [info]).
  Future<JellyfinPlaybackInfo> postedInfo({
    required String itemId,
    required JellyfinDeviceProfile deviceProfile,
    String? userId,
    int? maxStreamingBitrate,
    int? startTimeTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? maxAudioChannels,
    String? mediaSourceId,
    String? liveStreamId,
    bool autoOpenLiveStream = false,
    bool enableDirectPlay = true,
    bool enableDirectStream = true,
    bool enableTranscoding = true,
    bool allowVideoStreamCopy = true,
    bool allowAudioStreamCopy = true,
  }) async {
    final body = <String, dynamic>{
      'UserId': userId ?? _http.userId,
      'DeviceProfile': deviceProfile.toJson(),
      'AutoOpenLiveStream': autoOpenLiveStream,
      'EnableDirectPlay': enableDirectPlay,
      'EnableDirectStream': enableDirectStream,
      'EnableTranscoding': enableTranscoding,
      'AllowVideoStreamCopy': allowVideoStreamCopy,
      'AllowAudioStreamCopy': allowAudioStreamCopy,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': maxStreamingBitrate,
      if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
      if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': subtitleStreamIndex,
      if (maxAudioChannels != null) 'MaxAudioChannels': maxAudioChannels,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (liveStreamId != null) 'LiveStreamId': liveStreamId,
    };
    final res = await _http.request<Map<String, dynamic>>(
      '/Items/$itemId/PlaybackInfo',
      method: 'POST',
      data: body,
    );
    return JellyfinPlaybackInfo.fromJson(res.data ?? const {});
  }

  /// Open a live stream once `postedInfo()` returned a
  /// [JellyfinPlaybackInfo] whose `mediaSources[0].requiresOpening` is
  /// true. The server allocates a stream id and `mediaSourceId` you can
  /// then pass to [JellyfinVideosApi.streamUrl].
  Future<JellyfinPlaybackInfo> openLiveStream({
    required String openToken,
    String? userId,
    String? playSessionId,
    int? maxStreamingBitrate,
    int? startTimeTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? maxAudioChannels,
    String? itemId,
    JellyfinDeviceProfile? deviceProfile,
  }) async {
    final body = <String, dynamic>{
      'OpenToken': openToken,
      if (userId != null || _http.userId != null)
        'UserId': userId ?? _http.userId,
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': maxStreamingBitrate,
      if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
      if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': subtitleStreamIndex,
      if (maxAudioChannels != null) 'MaxAudioChannels': maxAudioChannels,
      if (itemId != null) 'ItemId': itemId,
      if (deviceProfile != null) 'DeviceProfile': deviceProfile.toJson(),
    };
    final res = await _http.request<Map<String, dynamic>>(
      '/LiveStreams/Open',
      method: 'POST',
      data: body,
    );
    return JellyfinPlaybackInfo.fromJson(res.data ?? const {});
  }

  /// Tear down a live stream previously opened via [openLiveStream].
  Future<void> closeLiveStream({required String liveStreamId}) async {
    await _http.request<void>(
      '/LiveStreams/Close',
      method: 'POST',
      queryParameters: {'liveStreamId': liveStreamId},
    );
  }

  /// Tiny endpoint that streams zeros — useful for measuring throughput
  /// when picking a streaming bitrate. The server returns `[size]` bytes
  /// filled with `0`; [size] is caller-controlled and defaults to ~100 KB
  /// (102400 bytes, the spec default), up to a spec maximum of 100000000.
  Future<int?> bitrateTestBytesLength({int size = 102400}) async {
    final res = await _http.request<List<int>>(
      '/Playback/BitrateTest',
      queryParameters: {'size': size},
    );
    return res.data?.length;
  }
}
