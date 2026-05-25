// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Audio/.../Lyrics` and `/Providers/Lyrics/{id}` — lyric upload,
/// removal, and remote (provider) search/download.
///
/// Wraps the `Lyrics` OpenAPI tag (6 operations). The read-side
/// `GET /Audio/{id}/Lyrics` is also available via
/// [JellyfinAudioApi.lyrics] for callers that already work in the
/// audio sub-API; this sub-API focuses on the write and remote
/// operations.
class JellyfinLyricsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinLyricsApi(this._http);

  /// `GET /Audio/{itemId}/Lyrics` — fetch the currently-stored lyrics
  /// for a track. Mirror of [JellyfinAudioApi.lyrics] for
  /// `lyrics`-only call sites.
  ///
  /// Returns `null` when the server has no lyrics for this item (404),
  /// matching [JellyfinAudioApi.lyrics]'s behaviour.
  Future<JellyfinLyrics?> forItem(String itemId) async {
    try {
      final res = await _http.request<Map<String, dynamic>>(
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

  /// `POST /Audio/{itemId}/Lyrics?fileName={name}` — upload a lyric
  /// file body (e.g. `.lrc`) and attach it to the track.
  ///
  /// [body] is the raw file bytes. The server picks the parser from
  /// [fileName]'s extension.
  Future<JellyfinLyrics?> upload({
    required String itemId,
    required String fileName,
    required Uint8List body,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Audio/$itemId/Lyrics',
      method: 'POST',
      queryParameters: {'fileName': fileName},
      data: body,
      extraHeaders: const {'Content-Type': 'application/octet-stream'},
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinLyrics.fromJson(data);
  }

  /// `DELETE /Audio/{itemId}/Lyrics` — remove the lyrics currently
  /// attached to the track.
  Future<void> delete(String itemId) async {
    await _http.request<void>(
      '/Audio/$itemId/Lyrics',
      method: 'DELETE',
    );
  }

  /// `GET /Audio/{itemId}/RemoteSearch/Lyrics` — search the
  /// configured lyric provider plugins for matches against this
  /// track. Each result map carries an `Id` to feed into
  /// [downloadRemote].
  Future<List<Map<String, dynamic>>> searchRemote(String itemId) async {
    final res = await _http.request<List<dynamic>>(
      '/Audio/$itemId/RemoteSearch/Lyrics',
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `POST /Audio/{itemId}/RemoteSearch/Lyrics/{lyricId}` — download
  /// a remote lyric result (id from [searchRemote]) and attach it to
  /// the track.
  Future<JellyfinLyrics?> downloadRemote({
    required String itemId,
    required String lyricId,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Audio/$itemId/RemoteSearch/Lyrics/$lyricId',
      method: 'POST',
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinLyrics.fromJson(data);
  }

  /// `GET /Providers/Lyrics/{lyricId}` — preview a remote lyric
  /// result without attaching it. Same id as [downloadRemote].
  Future<JellyfinLyrics?> previewRemote(String lyricId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Providers/Lyrics/$lyricId',
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinLyrics.fromJson(data);
  }
}
