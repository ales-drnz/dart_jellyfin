// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// HLS master / variant / segment URLs for both audio and video.
///
/// Wraps the `DynamicHls` and `HlsSegment` OpenAPI tags. As with
/// [JellyfinAudioApi] and [JellyfinVideosApi], these methods build
/// signed URLs — they don't fetch segments themselves.
class JellyfinHlsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinHlsApi(this._http);

  // ─── Audio ────────────────────────────────────────────────────────

  /// `GET /Audio/{itemId}/master.m3u8` — adaptive HLS master playlist
  /// for audio. The server can list multiple variants if bandwidth
  /// adaptation is enabled.
  String audioMasterUrl({
    required String itemId,
    String? mediaSourceId,
    int? maxStreamingBitrate,
    int? audioBitRate,
    String? audioCodec,
    int? audioChannels,
    int? maxAudioChannels,
    int? startTimeTicks,
    String? playSessionId,
    String? tag,
    bool breakOnNonKeyFrames = false,
    Map<String, String> params = const {},
  }) {
    final qp = _audioParams(
      mediaSourceId: mediaSourceId,
      maxStreamingBitrate: maxStreamingBitrate,
      audioBitRate: audioBitRate,
      audioCodec: audioCodec,
      audioChannels: audioChannels,
      maxAudioChannels: maxAudioChannels,
      startTimeTicks: startTimeTicks,
      playSessionId: playSessionId,
      tag: tag,
      breakOnNonKeyFrames: breakOnNonKeyFrames,
    )..addAll(params);
    return '${_requireBaseUrl()}/Audio/$itemId/master.m3u8?${_encode(qp)}';
  }

  /// `GET /Audio/{itemId}/main.m3u8` — a single-variant playlist (when
  /// you don't need adaptation; lighter and easier for some clients).
  String audioVariantUrl({
    required String itemId,
    String? mediaSourceId,
    int? maxStreamingBitrate,
    int? audioBitRate,
    String? audioCodec,
    int? audioChannels,
    int? maxAudioChannels,
    int? startTimeTicks,
    String? playSessionId,
    String? tag,
    Map<String, String> params = const {},
  }) {
    final qp = _audioParams(
      mediaSourceId: mediaSourceId,
      maxStreamingBitrate: maxStreamingBitrate,
      audioBitRate: audioBitRate,
      audioCodec: audioCodec,
      audioChannels: audioChannels,
      maxAudioChannels: maxAudioChannels,
      startTimeTicks: startTimeTicks,
      playSessionId: playSessionId,
      tag: tag,
    )..addAll(params);
    return '${_requireBaseUrl()}/Audio/$itemId/main.m3u8?${_encode(qp)}';
  }

  /// `GET /Audio/{itemId}/hls1/{playlistId}/{segmentId}.{container}` —
  /// individual HLS audio segment. The `playlistId` value is sent
  /// inside the variant playlist; you rarely need to build this URL
  /// manually because the player walks the `.m3u8`.
  String audioSegmentUrl({
    required String itemId,
    required String playlistId,
    required int segmentId,
    required String container,
    String? playSessionId,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (playSessionId != null) 'PlaySessionId': playSessionId,
    };
    return '${_requireBaseUrl()}/Audio/$itemId/hls1/$playlistId/$segmentId.$container?${_encode(qp)}';
  }

  // ─── Video ────────────────────────────────────────────────────────

  /// `GET /Videos/{itemId}/master.m3u8` — adaptive HLS master playlist
  /// for video.
  String videoMasterUrl({
    required String itemId,
    String? mediaSourceId,
    int? maxStreamingBitrate,
    String? videoCodec,
    String? audioCodec,
    int? videoBitRate,
    int? audioBitRate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? subtitleMethod,
    int? maxAudioChannels,
    int? width,
    int? height,
    int? maxWidth,
    int? maxHeight,
    int? startTimeTicks,
    String? playSessionId,
    String? tag,
    bool breakOnNonKeyFrames = false,
    Map<String, String> params = const {},
  }) {
    final qp = _videoParams(
      mediaSourceId: mediaSourceId,
      maxStreamingBitrate: maxStreamingBitrate,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      videoBitRate: videoBitRate,
      audioBitRate: audioBitRate,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      subtitleMethod: subtitleMethod,
      maxAudioChannels: maxAudioChannels,
      width: width,
      height: height,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      startTimeTicks: startTimeTicks,
      playSessionId: playSessionId,
      tag: tag,
      breakOnNonKeyFrames: breakOnNonKeyFrames,
    )..addAll(params);
    return '${_requireBaseUrl()}/Videos/$itemId/master.m3u8?${_encode(qp)}';
  }

  /// `GET /Videos/{itemId}/main.m3u8` — single-variant playlist.
  String videoVariantUrl({
    required String itemId,
    String? mediaSourceId,
    int? maxStreamingBitrate,
    String? videoCodec,
    String? audioCodec,
    int? videoBitRate,
    int? audioBitRate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? subtitleMethod,
    int? maxAudioChannels,
    int? width,
    int? height,
    int? maxWidth,
    int? maxHeight,
    int? startTimeTicks,
    String? playSessionId,
    String? tag,
    Map<String, String> params = const {},
  }) {
    final qp = _videoParams(
      mediaSourceId: mediaSourceId,
      maxStreamingBitrate: maxStreamingBitrate,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      videoBitRate: videoBitRate,
      audioBitRate: audioBitRate,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      subtitleMethod: subtitleMethod,
      maxAudioChannels: maxAudioChannels,
      width: width,
      height: height,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      startTimeTicks: startTimeTicks,
      playSessionId: playSessionId,
      tag: tag,
    )..addAll(params);
    return '${_requireBaseUrl()}/Videos/$itemId/main.m3u8?${_encode(qp)}';
  }

  /// `GET /Videos/{itemId}/hls1/{playlistId}/{segmentId}.{container}` —
  /// individual HLS video segment.
  String videoSegmentUrl({
    required String itemId,
    required String playlistId,
    required int segmentId,
    required String container,
    String? playSessionId,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (playSessionId != null) 'PlaySessionId': playSessionId,
    };
    return '${_requireBaseUrl()}/Videos/$itemId/hls1/$playlistId/$segmentId.$container?${_encode(qp)}';
  }

  /// `GET /Videos/{itemId}/live.m3u8` — live (continuously updating)
  /// HLS playlist. Used for live TV and Quick Sync HLS streams.
  String videoLiveUrl({
    required String itemId,
    String? mediaSourceId,
    int? maxStreamingBitrate,
    String? videoCodec,
    String? audioCodec,
    String? container,
    int? maxAudioChannels,
    String? playSessionId,
    Map<String, String> params = const {},
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': '$maxStreamingBitrate',
      if (videoCodec != null) 'VideoCodec': videoCodec,
      if (audioCodec != null) 'AudioCodec': audioCodec,
      if (container != null) 'Container': container,
      if (maxAudioChannels != null) 'MaxAudioChannels': '$maxAudioChannels',
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      ...params,
    };
    return '${_requireBaseUrl()}/Videos/$itemId/live.m3u8?${_encode(qp)}';
  }

  // ─── Legacy HLS (HlsSegment tag) ─────────────────────────────────

  /// `GET /Audio/{itemId}/hls/{segmentId}/stream.aac` — legacy
  /// audio HLS segment in AAC. New clients should prefer
  /// [audioSegmentUrl] (`/hls1/...`).
  String audioLegacyAacSegmentUrl({
    required String itemId,
    required int segmentId,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
    };
    return '${_requireBaseUrl()}/Audio/$itemId/hls/$segmentId/stream.aac?${_encode(qp)}';
  }

  /// `GET /Audio/{itemId}/hls/{segmentId}/stream.mp3` — legacy
  /// audio HLS segment in MP3.
  String audioLegacyMp3SegmentUrl({
    required String itemId,
    required int segmentId,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
    };
    return '${_requireBaseUrl()}/Audio/$itemId/hls/$segmentId/stream.mp3?${_encode(qp)}';
  }

  /// `GET /Videos/{itemId}/hls/{playlistId}/{segmentId}.{segmentContainer}`
  /// — legacy video HLS segment. New clients should prefer
  /// [videoSegmentUrl] (`/hls1/...`).
  String videoLegacySegmentUrl({
    required String itemId,
    required String playlistId,
    required int segmentId,
    required String segmentContainer,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
    };
    return '${_requireBaseUrl()}/Videos/$itemId/hls/$playlistId/$segmentId.$segmentContainer?${_encode(qp)}';
  }

  /// `GET /Videos/{itemId}/hls/{playlistId}/stream.m3u8` — legacy
  /// video HLS playlist.
  String videoLegacyPlaylistUrl({
    required String itemId,
    required String playlistId,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
    };
    return '${_requireBaseUrl()}/Videos/$itemId/hls/$playlistId/stream.m3u8?${_encode(qp)}';
  }

  /// `DELETE /Videos/ActiveEncodings` — stop an active HLS encoding
  /// session on the server. Pass the [deviceId] of the session to
  /// stop (defaults to the connection's device id) and the
  /// [playSessionId] of the encoding to stop. The server marks both
  /// query parameters as required, so [playSessionId] is mandatory.
  Future<void> stopEncoding({
    String? deviceId,
    required String playSessionId,
  }) async {
    final qp = <String, dynamic>{
      'deviceId': deviceId ?? _http.credentials.deviceId,
      'playSessionId': playSessionId,
    };
    await _http.request<void>(
      '/Videos/ActiveEncodings',
      method: 'DELETE',
      queryParameters: qp,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Map<String, String> _audioParams({
    String? mediaSourceId,
    int? maxStreamingBitrate,
    int? audioBitRate,
    String? audioCodec,
    int? audioChannels,
    int? maxAudioChannels,
    int? startTimeTicks,
    String? playSessionId,
    String? tag,
    bool breakOnNonKeyFrames = false,
  }) {
    return <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': '$maxStreamingBitrate',
      if (audioBitRate != null) 'AudioBitRate': '$audioBitRate',
      if (audioCodec != null) 'AudioCodec': audioCodec,
      if (audioChannels != null) 'AudioChannels': '$audioChannels',
      if (maxAudioChannels != null) 'MaxAudioChannels': '$maxAudioChannels',
      if (startTimeTicks != null) 'StartTimeTicks': '$startTimeTicks',
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      if (tag != null) 'Tag': tag,
      if (breakOnNonKeyFrames) 'BreakOnNonKeyFrames': 'true',
    };
  }

  Map<String, String> _videoParams({
    String? mediaSourceId,
    int? maxStreamingBitrate,
    String? videoCodec,
    String? audioCodec,
    int? videoBitRate,
    int? audioBitRate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? subtitleMethod,
    int? maxAudioChannels,
    int? width,
    int? height,
    int? maxWidth,
    int? maxHeight,
    int? startTimeTicks,
    String? playSessionId,
    String? tag,
    bool breakOnNonKeyFrames = false,
  }) {
    return <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': '$maxStreamingBitrate',
      if (videoCodec != null) 'VideoCodec': videoCodec,
      if (audioCodec != null) 'AudioCodec': audioCodec,
      if (videoBitRate != null) 'VideoBitRate': '$videoBitRate',
      if (audioBitRate != null) 'AudioBitRate': '$audioBitRate',
      if (audioStreamIndex != null) 'AudioStreamIndex': '$audioStreamIndex',
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': '$subtitleStreamIndex',
      if (subtitleMethod != null) 'SubtitleMethod': subtitleMethod,
      if (maxAudioChannels != null) 'MaxAudioChannels': '$maxAudioChannels',
      if (width != null) 'Width': '$width',
      if (height != null) 'Height': '$height',
      if (maxWidth != null) 'MaxWidth': '$maxWidth',
      if (maxHeight != null) 'MaxHeight': '$maxHeight',
      if (startTimeTicks != null) 'StartTimeTicks': '$startTimeTicks',
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      if (tag != null) 'Tag': tag,
      if (breakOnNonKeyFrames) 'BreakOnNonKeyFrames': 'true',
    };
  }

  String _requireBaseUrl() {
    final url = _http.baseUrl;
    if (url == null) {
      throw const JellyfinException(
        'No base URL — call JellyfinClient.connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    return url;
  }

  String _requireToken() {
    final t = _http.token;
    if (t == null) {
      throw const JellyfinException(
        'No token — call JellyfinClient.setSession() first.',
        type: JellyfinErrorType.state,
      );
    }
    return t;
  }

  String _encode(Map<String, String> qp) => qp.entries
      .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
}
