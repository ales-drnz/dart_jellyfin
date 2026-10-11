// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';
import '../transport/jellyfin_response.dart';
import 'jellyfin_text_body.dart';

/// Audio streaming, lyrics, instant mix.
///
/// These methods primarily BUILD URLs — they don't fetch the audio
/// stream itself. Hand the URL to your audio engine (mpv, AVPlayer, …).
class JellyfinAudioApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinAudioApi(this._http);

  /// `GET /Audio/{itemId}/universal` — the recommended streaming
  /// endpoint. The server decides whether to direct-play or transcode
  /// based on the supplied parameters.
  ///
  /// Returns a fully signed URL with `ApiKey` set so `<audio>` /
  /// `Uri.parse` users don't need extra headers.
  String universalStreamUrl({
    required String itemId,
    List<String> containers = const ['mp3', 'aac', 'flac', 'ogg', 'opus'],
    String? mediaSourceId,
    int? maxStreamingBitrate,
    int? audioBitRate,
    String? audioCodec,
    int? maxAudioChannels,
    int? transcodingAudioChannels,
    int? maxAudioSampleRate,
    int? maxAudioBitDepth,
    String transcodingContainer = 'ts',
    String transcodingProtocol = 'hls',
    int? startTimeTicks,
    String? playSessionId,
    bool enableAudioVbrEncoding = true,
    bool enableRedirection = true,
    bool enableRemoteMedia = false,
    bool breakOnNonKeyFrames = false,
  }) {
    final base = _requireBaseUrl();
    final qp = <String, String>{
      'UserId': _http.requireUserId(),
      'DeviceId': _http.credentials.deviceId,
      'ApiKey': _requireToken(),
      'Container': containers.join(','),
      'TranscodingContainer': transcodingContainer,
      'TranscodingProtocol': transcodingProtocol,
      'EnableAudioVbrEncoding': '$enableAudioVbrEncoding',
      'EnableRedirection': '$enableRedirection',
      'EnableRemoteMedia': '$enableRemoteMedia',
      'BreakOnNonKeyFrames': '$breakOnNonKeyFrames',
    };
    if (mediaSourceId != null) qp['MediaSourceId'] = mediaSourceId;
    if (maxStreamingBitrate != null) {
      qp['MaxStreamingBitrate'] = '$maxStreamingBitrate';
    }
    if (audioBitRate != null) qp['AudioBitRate'] = '$audioBitRate';
    if (audioCodec != null) qp['AudioCodec'] = audioCodec;
    if (maxAudioChannels != null) qp['MaxAudioChannels'] = '$maxAudioChannels';
    if (transcodingAudioChannels != null) {
      qp['TranscodingAudioChannels'] = '$transcodingAudioChannels';
    }
    if (maxAudioSampleRate != null) {
      qp['MaxAudioSampleRate'] = '$maxAudioSampleRate';
    }
    if (maxAudioBitDepth != null) {
      qp['MaxAudioBitDepth'] = '$maxAudioBitDepth';
    }
    if (startTimeTicks != null) qp['StartTimeTicks'] = '$startTimeTicks';
    if (playSessionId != null) qp['PlaySessionId'] = playSessionId;
    return '$base/Audio/$itemId/universal?${_encode(qp)}';
  }

  /// Direct (non-transcoded) audio stream URL — `/Audio/{id}/stream`.
  /// Best quality + smallest CPU on the server, but the client must be
  /// able to decode whatever the file contains.
  ///
  /// Returns `(url, ext)` where `ext` mirrors [container] for downstream
  /// filename generation.
  (String url, String extension) directStreamUrl({
    required String itemId,
    String? container,
    bool isStatic = true,
  }) {
    final base = _requireBaseUrl();
    final ext = container ?? '';
    final path =
        ext.isEmpty ? '/Audio/$itemId/stream' : '/Audio/$itemId/stream.$ext';
    final qp = <String, String>{
      'ApiKey': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (isStatic) 'Static': 'true',
    };
    return ('$base$path?${_encode(qp)}', ext);
  }

  /// Lyrics for a track, parsed into [JellyfinLyrics].
  ///
  /// Returns `null` when:
  ///   - the server returns 404, or
  ///   - the response body is empty.
  ///
  /// Jellyfin answers 404 both for a track without lyrics and for an id
  /// that names no item (12.2), so `null` does not tell the two apart.
  /// Other errors (a malformed id is a 400) are thrown.
  Future<JellyfinLyrics?> lyrics({
    required String itemId,
  }) async {
    try {
      final res = await _http.request<Map<String, Object?>>(
        '/Audio/$itemId/Lyrics',
      );
      final data = res.data;
      if (data == null) return null;
      return JellyfinLyrics.fromJson(data);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
  }

  /// The body of `GET /Audio/{itemId}/Lyrics` as text, decoded as UTF-8
  /// (see [lyrics] for when it is null).
  ///
  /// Despite the name this is not the lyric file: the route answers the
  /// server's parsed `LyricDto` as JSON, whatever the `Accept` header, and
  /// no route in the 12.x API serves the original `.lrc` / `.txt`
  /// (checked on 12.2). Use [lyrics] and [JellyfinLyrics.toLrc] or
  /// [JellyfinLyrics.toPlainText] instead.
  @Deprecated(
    'Answers the parsed LyricDto JSON, not the lyric file; use lyrics() '
    'and JellyfinLyrics.toLrc() / toPlainText() instead.',
  )
  Future<String?> lyricsRaw({
    required String itemId,
  }) async {
    try {
      final res = await _http.request<List<int>>(
        '/Audio/$itemId/Lyrics',
        responseType: JellyfinResponseType.bytes,
      );
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      return decodeTextBody(body, contentType: res.contentType);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
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
