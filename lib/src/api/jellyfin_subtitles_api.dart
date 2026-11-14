// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import 'jellyfin_query_helpers.dart';
import 'jellyfin_url_helpers.dart';
import 'jellyfin_videos_api.dart';

/// Subtitle endpoints — `Subtitle` OpenAPI tag.
///
/// Subtitles live alongside a video's `mediaSources[*].mediaStreams`
/// (entries where `type == 'Subtitle'`). The `index` you pass here is
/// the stream's `index` field — same value you'd use as
/// `subtitleStreamIndex` in [JellyfinVideosApi.streamUrl].
///
/// Besides reading and streaming them, the class uploads and deletes a
/// video's subtitles and searches the server's remote providers
/// ([upload], [delete], [searchRemote], [downloadRemote]).
///
/// {@category Video and subtitles}
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
  ///
  /// [vttTimestampMapMpegts] sets the MPEG-TS value of the WebVTT
  /// `X-TIMESTAMP-MAP` header (the server's default is 900000). Jellyfin
  /// 13.0 reads it; 12.x ignores it.
  String streamUrl({
    required String itemId,
    required String mediaSourceId,
    required int index,
    String format = formatVtt,
    int? startPositionTicks,
    bool copyTimestamps = false,
    bool addVttTimeMap = false,
    int? vttTimestampMapMpegts,
  }) {
    final base = _http.requireBaseUrl();
    final qp = <String, String>{
      'ApiKey': _http.requireToken(),
      if (startPositionTicks != null)
        'StartPositionTicks': '$startPositionTicks',
      if (copyTimestamps) 'CopyTimestamps': 'true',
      if (addVttTimeMap) 'AddVttTimeMap': 'true',
      if (vttTimestampMapMpegts != null)
        'vttTimestampMapMpegts': '$vttTimestampMapMpegts',
    };
    return '$base/Videos/$itemId/$mediaSourceId/Subtitles/$index/Stream.$format?${encodeQuery(qp)}';
  }

  /// Same as [streamUrl] but the server returns a sub-segment of the
  /// subtitle stream, from [startPositionTicks] to [endPositionTicks].
  /// Used when seeking during transcoded playback.
  ///
  /// [vttTimestampMapMpegts] sets the MPEG-TS value of the WebVTT
  /// `X-TIMESTAMP-MAP` header (the server's default is 900000). Jellyfin
  /// 13.0 reads it; 12.x ignores it.
  String streamWithTicksUrl({
    required String itemId,
    required String mediaSourceId,
    required int index,
    required int startPositionTicks,
    String format = formatVtt,
    int? endPositionTicks,
    int? vttTimestampMapMpegts,
  }) {
    final base = _http.requireBaseUrl();
    final qp = <String, String>{
      'ApiKey': _http.requireToken(),
      'StartPositionTicks': '$startPositionTicks',
      if (endPositionTicks != null) 'EndPositionTicks': '$endPositionTicks',
      if (vttTimestampMapMpegts != null)
        'vttTimestampMapMpegts': '$vttTimestampMapMpegts',
    };
    return '$base/Videos/$itemId/$mediaSourceId/Subtitles/$index/$startPositionTicks/Stream.$format?${encodeQuery(qp)}';
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
  /// Pass a hit's [JellyfinRemoteSubtitle.id] to [downloadRemote].
  Future<List<JellyfinRemoteSubtitle>> searchRemote({
    required String itemId,
    required String language,
    bool isPerfectMatch = false,
  }) => _http.requestJson(
    '/Items/$itemId/RemoteSearch/Subtitles/${seg(language)}',
    queryParameters: {'isPerfectMatch': isPerfectMatch},
    listOf(JellyfinRemoteSubtitle.fromJson),
  );

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
  /// subtitle by id, as text, without installing it on any item.
  /// Returns null on 404 or an empty body.
  ///
  /// The route answers the subtitle file (`text/*`), not JSON; it is
  /// decoded like [fetch].
  Future<String?> getRemote({required String id}) async {
    return _http.requestTextOrNull('/Providers/Subtitles/Subtitles/$id');
  }

  // ─── Fallback fonts (libass) ──────────────────────────────────────

  /// `GET /FallbackFont/Fonts` — fonts the server can serve to clients
  /// that render `.ass` / `.ssa` subtitles via libass.
  Future<List<JellyfinServerFile>> fallbackFonts() => _http.requestJson(
    '/FallbackFont/Fonts',
    listOf(JellyfinServerFile.fromJson),
  );

  /// URL of a single fallback font, suitable for handing to libass.
  String fallbackFontUrl({required String name}) {
    return '${_http.requireBaseUrl()}/FallbackFont/Fonts/${seg(name)}'
        '${_http.apiKeyQuery}';
  }

  // ─── HLS subtitle playlist ────────────────────────────────────────

  /// HLS subtitle playlist — used when subtitles are delivered as a
  /// separate HLS stream rather than burned in.
  ///
  /// [vttTimestampMapMpegts] sets the MPEG-TS value of the WebVTT
  /// `X-TIMESTAMP-MAP` header (the server's default is 900000). Jellyfin
  /// 13.0 reads it; 12.x ignores it.
  String playlistUrl({
    required String itemId,
    required String mediaSourceId,
    required int index,
    required int segmentLength,
    int? vttTimestampMapMpegts,
  }) {
    final base = _http.requireBaseUrl();
    final qp = <String, String>{
      'ApiKey': _http.requireToken(),
      if (vttTimestampMapMpegts != null)
        'vttTimestampMapMpegts': '$vttTimestampMapMpegts',
    };
    return '$base/Videos/$itemId/$mediaSourceId/Subtitles/$index/subtitles.m3u8?segmentLength=$segmentLength&${encodeQuery(qp)}';
  }

  /// Fetch the subtitle body as text. Returns null on 404.
  ///
  /// The bytes are decoded by their byte-order mark, then the response's
  /// `charset`, then as UTF-8 with a Latin-1 fallback, so a UTF-8 file
  /// keeps its accented characters and a BOM is not returned.
  Future<String?> fetch({
    required String itemId,
    required String mediaSourceId,
    required int index,
    String format = formatVtt,
  }) async {
    return _http.requestTextOrNull(
      '/Videos/$itemId/$mediaSourceId/Subtitles/$index/Stream.$format',
    );
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
    return _http.requestTextOrNull(
      '/Videos/$itemId/$mediaSourceId/Subtitles/$index/$ticks/Stream.$format',
    );
  }
}
