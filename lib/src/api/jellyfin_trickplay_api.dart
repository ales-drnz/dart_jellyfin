// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// `/Videos/{itemId}/Trickplay/{width}/{index}.jpg` — scrubbing
/// thumbnails. Each video item carries one or more trickplay tile
/// resolutions (e.g. 320×, 160×) discoverable on
/// `JellyfinItem.raw['Trickplay']` (the typed `Trickplay` field is not
/// yet promoted onto `JellyfinItem`; read it from `.raw`).
class JellyfinTrickplayApi {
  final JellyfinConnection _http;

  JellyfinTrickplayApi(this._http);

  /// Build a tile image URL.
  ///
  /// [width] is the per-tile width in pixels (must match one of the
  /// resolutions the server has pre-generated for the item).
  /// [index] is the 0-based tile index along the timeline.
  String tileUrl({
    required String itemId,
    required int width,
    required int index,
    String? mediaSourceId,
  }) {
    final qp = <String, String>{
      'api_key': _requireToken(),
      if (mediaSourceId != null) 'mediaSourceId': mediaSourceId,
    };
    return '${_requireBaseUrl()}/Videos/$itemId/Trickplay/$width/$index.jpg?${_encode(qp)}';
  }

  /// `/Videos/{itemId}/{mediaSourceId}/Trickplay/{width}/tiles.m3u8` —
  /// HLS playlist describing every tile. Useful when the player wants
  /// to lazy-load tiles via HTTP range instead of building each URL
  /// itself.
  String hlsPlaylistUrl({
    required String itemId,
    required String mediaSourceId,
    required int width,
  }) {
    final qp = <String, String>{'api_key': _requireToken()};
    return '${_requireBaseUrl()}/Videos/$itemId/$mediaSourceId/Trickplay/$width/tiles.m3u8?${_encode(qp)}';
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
