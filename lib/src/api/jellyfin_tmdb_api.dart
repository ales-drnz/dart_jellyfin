// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Tmdb/ClientConfiguration` — TMDB client configuration.
///
/// Wraps the `Tmdb` OpenAPI tag (1 operation). Returns the
/// configuration the TMDB metadata plugin uses (image base URL,
/// supported image sizes, …).
class JellyfinTmdbApi {
  final JellyfinConnection _http;

  JellyfinTmdbApi(this._http);

  /// `GET /Tmdb/ClientConfiguration` — TMDB metadata-provider
  /// configuration as a raw map.
  Future<Map<String, dynamic>> clientConfiguration() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Tmdb/ClientConfiguration',
    );
    return res.data ?? const {};
  }
}
