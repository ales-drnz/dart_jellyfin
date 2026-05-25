// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// Video streaming, additional parts, alternate sources.
///
/// Mirrors the `Videos` OpenAPI tag. As with [JellyfinAudioApi], the
/// URL builders here don't fetch the stream themselves — they assemble
/// a fully signed URL you hand to your video engine (mpv, AVPlayer,
/// ExoPlayer, …).
///
/// For real device-profile negotiation (direct-play vs transcoding
/// decisions, exact container/codec the server will produce) call
/// [JellyfinMediaInfoApi.postedInfo] first; the response carries a
/// `transcodingUrl` you can use verbatim instead of building one here.
class JellyfinVideosApi {
  final JellyfinConnection _http;

  JellyfinVideosApi(this._http);

  /// `GET /Videos/{itemId}/stream(.{container})` — direct (or progressive
  /// transcoded) video stream.
  ///
  /// Returns `(url, ext)` where `ext` mirrors [container] for filename
  /// generation. Set [isStatic] = true to force the server to direct-stream
  /// the original file with no muxing; pass [params] (received from
  /// `PlaybackInfoResponse.mediaSources[0].transcodingUrl` query string)
  /// to replay a server-decided transcode.
  (String url, String extension) streamUrl({
    required String itemId,
    String? container,
    String? mediaSourceId,
    int? maxStreamingBitrate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? subtitleMethod,
    int? maxAudioChannels,
    String? videoCodec,
    String? audioCodec,
    int? videoBitRate,
    int? audioBitRate,
    int? width,
    int? height,
    int? maxWidth,
    int? maxHeight,
    int? startTimeTicks,
    bool isStatic = false,
    String? playSessionId,
    String? tag,
    Map<String, String> params = const {},
  }) {
    final base = _requireBaseUrl();
    final ext = container ?? '';
    final path = ext.isEmpty
        ? '/Videos/$itemId/stream'
        : '/Videos/$itemId/stream.$ext';
    final qp = <String, String>{
      'api_key': _requireToken(),
      'DeviceId': _http.credentials.deviceId,
      if (isStatic) 'Static': 'true',
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': '$maxStreamingBitrate',
      if (audioStreamIndex != null) 'AudioStreamIndex': '$audioStreamIndex',
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': '$subtitleStreamIndex',
      if (subtitleMethod != null) 'SubtitleMethod': subtitleMethod,
      if (maxAudioChannels != null) 'MaxAudioChannels': '$maxAudioChannels',
      if (videoCodec != null) 'VideoCodec': videoCodec,
      if (audioCodec != null) 'AudioCodec': audioCodec,
      if (videoBitRate != null) 'VideoBitRate': '$videoBitRate',
      if (audioBitRate != null) 'AudioBitRate': '$audioBitRate',
      if (width != null) 'Width': '$width',
      if (height != null) 'Height': '$height',
      if (maxWidth != null) 'MaxWidth': '$maxWidth',
      if (maxHeight != null) 'MaxHeight': '$maxHeight',
      if (startTimeTicks != null) 'StartTimeTicks': '$startTimeTicks',
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      if (tag != null) 'Tag': tag,
      ...params,
    };
    return ('$base$path?${_encode(qp)}', ext);
  }

  /// "Additional parts" — multi-file movies (CD1/CD2, parts/halves).
  Future<List<Map<String, dynamic>>> additionalParts(String itemId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Videos/$itemId/AdditionalParts',
      queryParameters: {'userId': _http.userId},
    );
    final items = res.data?['Items'];
    if (items is! List) return const [];
    return [
      for (final e in items)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `DELETE /Videos/{itemId}/AlternateSources` — remove the
  /// alternate-source versions linked to this video. Keeps the
  /// primary file; only the links to the alternates are dropped.
  /// Admin / library editor.
  Future<void> deleteAlternateSources(String itemId) async {
    await _http.request<void>(
      '/Videos/$itemId/AlternateSources',
      method: 'DELETE',
    );
  }

  /// `GET /Videos/{videoId}/{mediaSourceId}/Attachments/{index}` —
  /// URL to a font / image / SDH track embedded in the video (used
  /// e.g. by libass for fonts inside MKV).
  String attachmentUrl({
    required String videoId,
    required String mediaSourceId,
    required int index,
  }) {
    final base = _requireBaseUrl();
    final token = _http.token ?? '';
    return '$base/Videos/$videoId/$mediaSourceId/Attachments/$index?api_key=$token';
  }

  /// `POST /Videos/MergeVersions?ids={ids}` — merge several videos
  /// into one "Versions" group so the player can present them as
  /// alternate sources of the same title. Admin / library editor.
  Future<void> mergeVersions({required List<String> ids}) async {
    await _http.request<void>(
      '/Videos/MergeVersions',
      method: 'POST',
      queryParameters: {'ids': ids.join(',')},
    );
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
