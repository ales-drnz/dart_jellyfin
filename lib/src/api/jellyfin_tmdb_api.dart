// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';

/// `/Tmdb/ClientConfiguration` — TMDB client configuration.
///
/// Returns the configuration the TMDB metadata plugin uses (image
/// base URL, supported image sizes, …).
///
/// The route is hidden from the Jellyfin 12 OpenAPI document. It
/// still answers on 12.0 but may be removed in any major release
/// without notice; there is no replacement.
class JellyfinTmdbApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinTmdbApi(this._http);

  /// `GET /Tmdb/ClientConfiguration` — TMDB metadata-provider
  /// configuration as a raw map.
  @Deprecated(
    'Hidden from the Jellyfin 12 API and may be removed without notice; '
    'no replacement exists.',
  )
  Future<Map<String, Object?>> clientConfiguration() async {
    final res = await _http.request<Map<String, Object?>>(
      '/Tmdb/ClientConfiguration',
    );
    return res.data ?? const {};
  }
}
