// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_admin_models.dart';
import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_parsing.dart';

/// `/System/Configuration` — server-wide configuration.
///
/// Wraps the `Configuration` OpenAPI tag (6 operations). Admin only.
/// The "named" configuration endpoints store/retrieve plugin-style
/// configuration documents keyed by name.
class JellyfinConfigurationApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinConfigurationApi(this._http);

  /// `GET /System/Configuration` — the full server configuration.
  ///
  /// To change it, edit a copy of [JellyfinServerConfiguration.raw] and
  /// send it to [update].
  Future<JellyfinServerConfiguration> get() => _http.requestJson(
    '/System/Configuration',
    (json) =>
        objectOf(JellyfinServerConfiguration.fromJson)(json) ??
        JellyfinServerConfiguration.fromJson(const {}),
  );

  /// `POST /System/Configuration` — replace the full configuration.
  Future<void> update(Map<String, Object?> body) async {
    await _http.request<void>(
      '/System/Configuration',
      method: 'POST',
      data: body,
    );
  }

  /// `GET /System/Configuration/{key}` — one named configuration
  /// document (`network`, `encoding`, `livetv`, `metadata`, …).
  ///
  /// Stays a map: each key has its own shape, and the API document
  /// declares the answer as an untyped body.
  Future<Map<String, Object?>> getNamed({
    required String key,
  }) async {
    final res = await _http.request<Map<String, Object?>>(
      '/System/Configuration/${Uri.encodeComponent(key)}',
    );
    return res.data ?? const {};
  }

  /// `POST /System/Configuration/{key}` — write a named document.
  Future<void> updateNamed({
    required String key,
    required Map<String, Object?> body,
  }) async {
    await _http.request<void>(
      '/System/Configuration/${Uri.encodeComponent(key)}',
      method: 'POST',
      data: body,
    );
  }

  /// `POST /System/Configuration/Branding` — update branding-only
  /// configuration (login screen wording, custom CSS).
  Future<void> updateBranding(Map<String, Object?> body) async {
    await _http.request<void>(
      '/System/Configuration/Branding',
      method: 'POST',
      data: body,
    );
  }

  /// `GET /System/Configuration/MetadataOptions/Default` — default
  /// metadata options the server ships with (used as a template
  /// when creating new libraries).
  Future<JellyfinMetadataOptions> defaultMetadataOptions() => _http.requestJson(
    '/System/Configuration/MetadataOptions/Default',
    (json) =>
        objectOf(JellyfinMetadataOptions.fromJson)(json) ??
        JellyfinMetadataOptions.fromJson(const {}),
  );
}
