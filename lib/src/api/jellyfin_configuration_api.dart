// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/System/Configuration` — server-wide configuration.
///
/// Wraps the `Configuration` OpenAPI tag (6 operations). Admin only.
/// The "named" configuration endpoints store/retrieve plugin-style
/// configuration documents keyed by name.
class JellyfinConfigurationApi {
  final JellyfinConnection _http;

  JellyfinConfigurationApi(this._http);

  /// `GET /System/Configuration` — full server configuration as a
  /// raw map.
  Future<Map<String, dynamic>> get() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/System/Configuration',
    );
    return res.data ?? const {};
  }

  /// `POST /System/Configuration` — replace the full configuration.
  Future<void> update(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/System/Configuration',
      method: 'POST',
      data: body,
    );
  }

  /// `GET /System/Configuration/{key}` — one named configuration
  /// document (used by plugins for per-plugin settings).
  Future<Map<String, dynamic>> getNamed(String key) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/System/Configuration/${Uri.encodeComponent(key)}',
    );
    return res.data ?? const {};
  }

  /// `POST /System/Configuration/{key}` — write a named document.
  Future<void> updateNamed(String key, Map<String, dynamic> body) async {
    await _http.request<void>(
      '/System/Configuration/${Uri.encodeComponent(key)}',
      method: 'POST',
      data: body,
    );
  }

  /// `POST /System/Configuration/Branding` — update branding-only
  /// configuration (login screen wording, custom CSS).
  Future<void> updateBranding(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/System/Configuration/Branding',
      method: 'POST',
      data: body,
    );
  }

  /// `GET /System/Configuration/MetadataOptions/Default` — default
  /// metadata options the server ships with (used as a template
  /// when creating new libraries).
  Future<Map<String, dynamic>> defaultMetadataOptions() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/System/Configuration/MetadataOptions/Default',
    );
    return res.data ?? const {};
  }
}
