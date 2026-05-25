// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/web/Configuration*` — admin dashboard configuration pages.
///
/// Wraps the `Dashboard` OpenAPI tag (2 operations). Admin only.
/// Plugin authors register configuration pages with the server; the
/// admin web UI lists them here.
class JellyfinDashboardApi {
  final JellyfinConnection _http;

  JellyfinDashboardApi(this._http);

  /// `GET /web/ConfigurationPage?name={name}` — fetch the HTML body
  /// of one configuration page.
  Future<String?> configurationPage(String name) async {
    final res = await _http.request<String>(
      '/web/ConfigurationPage',
      queryParameters: {'name': name},
    );
    return res.data;
  }

  /// `GET /web/ConfigurationPages` — list configuration pages
  /// registered by plugins.
  Future<List<Map<String, dynamic>>> configurationPages({
    bool? enableInMainMenu,
  }) async {
    final qp = <String, dynamic>{};
    if (enableInMainMenu != null) qp['enableInMainMenu'] = enableInMainMenu;
    final res = await _http.request<List<dynamic>>(
      '/web/ConfigurationPages',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }
}
