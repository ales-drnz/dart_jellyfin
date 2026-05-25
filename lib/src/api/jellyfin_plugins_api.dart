// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Plugins` — installed plugin management.
///
/// Wraps the `Plugins` OpenAPI tag (9 operations). Admin only.
/// Plugins are addons that extend Jellyfin: metadata providers,
/// channel sources, image fetchers, etc.
class JellyfinPluginsApi {
  final JellyfinConnection _http;

  JellyfinPluginsApi(this._http);

  /// `GET /Plugins` — every installed plugin.
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _http.request<List<dynamic>>('/Plugins');
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `DELETE /Plugins/{pluginId}` — uninstall every version of a
  /// plugin.
  Future<void> uninstall(String pluginId) async {
    await _http.request<void>('/Plugins/$pluginId', method: 'DELETE');
  }

  /// `DELETE /Plugins/{pluginId}/{version}` — uninstall a specific
  /// version.
  Future<void> uninstallVersion(String pluginId, String version) async {
    await _http.request<void>('/Plugins/$pluginId/$version', method: 'DELETE');
  }

  /// `POST /Plugins/{pluginId}/{version}/Enable`.
  Future<void> enable(String pluginId, String version) async {
    await _http.request<void>(
      '/Plugins/$pluginId/$version/Enable',
      method: 'POST',
    );
  }

  /// `POST /Plugins/{pluginId}/{version}/Disable`.
  Future<void> disable(String pluginId, String version) async {
    await _http.request<void>(
      '/Plugins/$pluginId/$version/Disable',
      method: 'POST',
    );
  }

  /// `GET /Plugins/{pluginId}/{version}/Image` — URL to the plugin
  /// thumbnail (signed with the session token).
  String imageUrl({required String pluginId, required String version}) {
    final base = _http.baseUrl;
    final token = _http.token ?? '';
    return '$base/Plugins/$pluginId/$version/Image?api_key=$token';
  }

  /// `GET /Plugins/{pluginId}/Configuration` — fetch a plugin's
  /// current configuration document.
  Future<Map<String, dynamic>> configuration(String pluginId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Plugins/$pluginId/Configuration',
    );
    return res.data ?? const {};
  }

  /// `POST /Plugins/{pluginId}/Configuration` — replace the plugin's
  /// configuration.
  Future<void> updateConfiguration({
    required String pluginId,
    required Map<String, dynamic> configuration,
  }) async {
    await _http.request<void>(
      '/Plugins/$pluginId/Configuration',
      method: 'POST',
      data: configuration,
    );
  }

  /// `POST /Plugins/{pluginId}/Manifest` — get the plugin's manifest.
  Future<Map<String, dynamic>> manifest(String pluginId) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Plugins/$pluginId/Manifest',
      method: 'POST',
    );
    return res.data ?? const {};
  }
}
