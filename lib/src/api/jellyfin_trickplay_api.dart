// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import 'jellyfin_url_helpers.dart';

/// `/Videos/{itemId}/Trickplay/{width}/{index}.jpg` — scrubbing
/// thumbnails. A video item lists the resolutions the server generated
/// (e.g. 320, 160) in `JellyfinItem.trickplay`: `items.byId` sends it, a
/// list sends it when `fields` has `JellyfinItemField.trickplay`.
///
/// ```dart
/// final item = (await jf.items.byId(itemId: id))!;
/// final info = item.trickplay[item.mediaSources.first.id]?[320];
/// if (info != null) {
///   final url = jf.trickplay.tileUrl(
///     itemId: id,
///     width: info.width,
///     index: info.tileIndexAt(position),
///   );
/// }
/// ```
///
/// {@category Video and subtitles}
class JellyfinTrickplayApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
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
      'ApiKey': _http.requireToken(),
      'mediaSourceId': ?mediaSourceId,
    };
    return '${_http.requireBaseUrl()}/Videos/$itemId/Trickplay/$width/$index.jpg?${encodeQuery(qp)}';
  }

  /// `/Videos/{itemId}/Trickplay/{width}/tiles.m3u8` — HLS playlist
  /// describing every tile. Useful when the player wants to lazy-load
  /// tiles via HTTP range instead of building each URL itself.
  ///
  /// [mediaSourceId] is optional and, per the server route, is passed
  /// as a query parameter (not a path segment).
  String hlsPlaylistUrl({
    required String itemId,
    required int width,
    String? mediaSourceId,
  }) {
    final qp = <String, String>{
      'ApiKey': _http.requireToken(),
      'mediaSourceId': ?mediaSourceId,
    };
    return '${_http.requireBaseUrl()}/Videos/$itemId/Trickplay/$width/tiles.m3u8?${encodeQuery(qp)}';
  }
}
