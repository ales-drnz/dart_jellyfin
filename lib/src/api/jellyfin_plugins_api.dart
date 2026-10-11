// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';

/// `/Plugins` — installed plugin management.
///
/// Wraps the `Plugins` OpenAPI tag (9 operations). Admin only.
/// Plugins are addons that extend Jellyfin: metadata providers,
/// channel sources, image fetchers, etc.
class JellyfinPluginsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinPluginsApi(this._http);

  /// `GET /Plugins` — every installed plugin.
  Future<List<Map<String, Object?>>> list() async {
    final res = await _http.request<List<Object?>>('/Plugins');
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  /// `DELETE /Plugins/{pluginId}` — uninstall every version of a
  /// plugin.
  Future<void> uninstall({
    required String pluginId,
  }) async {
    await _http.request<void>('/Plugins/$pluginId', method: 'DELETE');
  }

  /// `DELETE /Plugins/{pluginId}/{version}` — uninstall a specific
  /// version.
  Future<void> uninstallVersion({
    required String pluginId,
    required String version,
  }) async {
    await _http.request<void>('/Plugins/$pluginId/$version', method: 'DELETE');
  }

  /// `POST /Plugins/{pluginId}/{version}/Enable`.
  Future<void> enable({
    required String pluginId,
    required String version,
  }) async {
    await _http.request<void>(
      '/Plugins/$pluginId/$version/Enable',
      method: 'POST',
    );
  }

  /// `POST /Plugins/{pluginId}/{version}/Disable`.
  Future<void> disable({
    required String pluginId,
    required String version,
  }) async {
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
    return '$base/Plugins/$pluginId/$version/Image?ApiKey=$token';
  }

  /// `GET /Plugins/{pluginId}/Configuration` — fetch a plugin's
  /// current configuration document.
  Future<Map<String, Object?>> configuration({
    required String pluginId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/Plugins/$pluginId/Configuration',
    );
    return res.data ?? const {};
  }

  /// `POST /Plugins/{pluginId}/Configuration` — replace the plugin's
  /// configuration.
  Future<void> updateConfiguration({
    required String pluginId,
    required Map<String, Object?> configuration,
  }) async {
    await _http.request<void>(
      '/Plugins/$pluginId/Configuration',
      method: 'POST',
      data: configuration,
    );
  }

  /// `POST /Plugins/{pluginId}/Manifest` — get the plugin's manifest.
  Future<Map<String, Object?>> manifest({
    required String pluginId,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/Plugins/$pluginId/Manifest',
      method: 'POST',
    );
    return res.data ?? const {};
  }
}
