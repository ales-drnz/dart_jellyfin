// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dio/dio.dart' show ResponseType;

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// Subtitle endpoints — `Subtitle` OpenAPI tag.
///
/// Subtitles live alongside a video's `mediaSources[*].mediaStreams`
/// (entries where `type == 'Subtitle'`). The `index` you pass here is
/// the stream's `index` field — same value you'd use as
/// `subtitleStreamIndex` in [JellyfinVideosApi.streamUrl].
///
/// The library currently exposes only the read paths. Upload / delete /
/// remote search live behind the escape hatch.
class JellyfinSubtitlesApi {
  /// SubRip — the universal sidecar format.
  static const String formatSrt = 'srt';

  /// WebVTT — the format the HTML5 `<video>` element consumes.
  static const String formatVtt = 'vtt';

  /// Advanced SubStation Alpha — required for libass styling.
  static const String formatAss = 'ass';

  /// SubStation Alpha (predecessor of ASS).
  static const String formatSsa = 'ssa';

  /// MicroDVD / legacy `.sub` text format.
  static const String formatSub = 'sub';

  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinSubtitlesApi(this._http);

  /// Build a subtitle stream URL.
  ///
  /// `GET /Videos/{itemId}/{mediaSourceId}/Subtitles/{index}/Stream.{format}`
  ///
  /// `format` should be one of [formatSrt] (recommended for sidecar
  /// rendering), [formatVtt] (HTML5 video tag), [formatAss] / [formatSsa]
  /// (libass for advanced styling), or [formatSub] (legacy).
  String streamUrl({
    required String itemId,
    required String mediaSourceId,
    required int index,
    String format = formatVtt,
    int? startPositionTicks,
    bool copyTimestamps = false,
    bool addVttTimeMap = false,
  }) {
    final base = _requireBaseUrl();
    final qp = <String, String>{
      'api_key': _requireToken(),
      if (startPositionTicks != null)
        'StartPositionTicks': '$startPositionTicks',
      if (copyTimestamps) 'CopyTimestamps': 'true',
      if (addVttTimeMap) 'AddVttTimeMap': 'true',
    };
    return '$base/Videos/$itemId/$mediaSourceId/Subtitles/$index/Stream.$format?${_encode(qp)}';
  }

  /// Same as [streamUrl] but the server returns a sub-segment of the
  /// subtitle stream, starting at a tick offset. Used when seeking
  /// during transcoded playback.
  String streamWithTicksUrl({
    required String itemId,
    required String mediaSourceId,
    required int index,
    required int startPositionTicks,
    String format = formatVtt,
    int? segmentLength,
  }) {
    final base = _requireBaseUrl();
    final qp = <String, String>{
      'api_key': _requireToken(),
      'StartPositionTicks': '$startPositionTicks',
      if (segmentLength != null) 'SegmentLength': '$segmentLength',
    };
    return '$base/Videos/$itemId/$mediaSourceId/Subtitles/$index/$startPositionTicks/Stream.$format?${_encode(qp)}';
  }

  // ─── Upload / delete ──────────────────────────────────────────────

  /// `POST /Videos/{itemId}/Subtitles` — upload a sidecar subtitle.
  ///
  /// [data] is the base64-encoded subtitle file. [format] is the
  /// extension (`srt`, `vtt`, `ass`, …). Admin tokens only.
  Future<void> upload({
    required String itemId,
    required String language,
    required String format,
    required String data,
    bool isForced = false,
    bool isHearingImpaired = false,
  }) async {
    await _http.request<void>(
      '/Videos/$itemId/Subtitles',
      method: 'POST',
      data: {
        'Language': language,
        'Format': format,
        'Data': data,
        'IsForced': isForced,
        'IsHearingImpaired': isHearingImpaired,
      },
    );
  }

  /// `DELETE /Videos/{itemId}/Subtitles/{index}` — remove an embedded
  /// or sidecar subtitle stream from the item.
  Future<void> delete({required String itemId, required int index}) async {
    await _http.request<void>(
      '/Videos/$itemId/Subtitles/$index',
      method: 'DELETE',
    );
  }

  // ─── Remote search (OpenSubtitles, etc.) ──────────────────────────

  /// `GET /Items/{itemId}/RemoteSearch/Subtitles/{language}` — ask
  /// upstream providers (OpenSubtitles, Addic7ed, …) for matching
  /// subtitles. Requires server-side plugin configuration.
  ///
  /// Returns raw search hit maps; each carries `Id`, `ProviderName`,
  /// `Name`, `Format`, `DownloadCount`, `CommunityRating`, …
  Future<List<Map<String, dynamic>>> searchRemote({
    required String itemId,
    required String language,
    bool isPerfectMatch = false,
  }) async {
    final res = await _http.request<List<dynamic>>(
      '/Items/$itemId/RemoteSearch/Subtitles/$language',
      queryParameters: {'isPerfectMatch': isPerfectMatch},
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `POST /Items/{itemId}/RemoteSearch/Subtitles/{subtitleId}` —
  /// download a remote subtitle and install it on the item.
  ///
  /// [subtitleId] comes from the `Id` field of a hit returned by
  /// [searchRemote].
  Future<void> downloadRemote({
    required String itemId,
    required String subtitleId,
  }) async {
    await _http.request<void>(
      '/Items/$itemId/RemoteSearch/Subtitles/$subtitleId',
      method: 'POST',
    );
  }

  /// `GET /Providers/Subtitles/Subtitles/{id}` — fetch a remote
  /// subtitle preview by id (without installing it on any item).
  Future<Map<String, dynamic>?> getRemote(String id) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Providers/Subtitles/Subtitles/$id',
    );
    return res.data;
  }

  // ─── Fallback fonts (libass) ──────────────────────────────────────

  /// `GET /FallbackFont/Fonts` — fonts the server can serve to clients
  /// that render `.ass` / `.ssa` subtitles via libass.
  Future<List<Map<String, dynamic>>> fallbackFonts() async {
    final res = await _http.request<List<dynamic>>('/FallbackFont/Fonts');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// URL of a single fallback font, suitable for handing to libass.
  String fallbackFontUrl({required String name}) {
    return '${_requireBaseUrl()}/FallbackFont/Fonts/$name?api_key=${_requireToken()}';
  }

  // ─── HLS subtitle playlist ────────────────────────────────────────

  /// HLS subtitle playlist — used when subtitles are delivered as a
  /// separate HLS stream rather than burned in.
  String playlistUrl({
    required String itemId,
    required String mediaSourceId,
    required int index,
    required int segmentLength,
  }) {
    final base = _requireBaseUrl();
    final qp = <String, String>{'api_key': _requireToken()};
    return '$base/Videos/$itemId/$mediaSourceId/Subtitles/$index/subtitles.m3u8?segmentLength=$segmentLength&${_encode(qp)}';
  }

  /// Fetch the subtitle body as raw text. Returns null on 404.
  Future<String?> fetch({
    required String itemId,
    required String mediaSourceId,
    required int index,
    String format = formatVtt,
  }) async {
    try {
      final res = await _http.request<List<int>>(
        '/Videos/$itemId/$mediaSourceId/Subtitles/$index/Stream.$format',
        responseType: ResponseType.bytes,
      );
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      return String.fromCharCodes(body);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
  }

  /// `GET /Videos/{itemId}/{mediaSourceId}/Subtitles/{index}/{startPositionTicks}/Stream.{format}` —
  /// fetch the subtitle body starting at [startPosition] instead of
  /// the beginning. Useful when the player seeks and only needs the
  /// remaining cues.
  Future<String?> fetchFromPosition({
    required String itemId,
    required String mediaSourceId,
    required int index,
    required Duration startPosition,
    String format = formatVtt,
  }) async {
    final ticks = startPosition.inMilliseconds * 10000;
    try {
      final res = await _http.request<List<int>>(
        '/Videos/$itemId/$mediaSourceId/Subtitles/$index/$ticks/Stream.$format',
        responseType: ResponseType.bytes,
      );
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      return String.fromCharCodes(body);
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
