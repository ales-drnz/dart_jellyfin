// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import 'jellyfin_configuration_api.dart';

/// `/Startup` — first-run wizard endpoints.
///
/// Wraps the `Startup` OpenAPI tag (7 operations). Used only during
/// the initial server setup flow. After [completeWizard] is called
/// these endpoints stop accepting writes.
///
/// Jellyfin 12 marks the configuration-shaped routes obsolete
/// ([configuration], [updateInitialConfiguration], [setRemoteAccess],
/// [firstUserAlt]) in favour of `/System/Configuration`; see
/// [JellyfinConfigurationApi]. [firstUser], [updateStartupUser] and
/// [completeWizard] remain the supported wizard steps.
class JellyfinStartupApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinStartupApi(this._http);

  /// `GET /Startup/Configuration` — the wizard's current state
  /// (preferred metadata language/country, etc.).
  ///
  /// Obsolete in Jellyfin 12; read `configuration.get()` instead.
  @Deprecated('Obsolete in Jellyfin 12; use configuration.get() instead.')
  Future<Map<String, dynamic>> configuration() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Startup/Configuration',
    );
    return res.data ?? const {};
  }

  /// `POST /Startup/Configuration` — write the initial server
  /// configuration during the wizard.
  ///
  /// Obsolete in Jellyfin 12; write `configuration.update()` instead.
  @Deprecated('Obsolete in Jellyfin 12; use configuration.update() instead.')
  Future<void> updateInitialConfiguration(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/Startup/Configuration',
      method: 'POST',
      data: body,
    );
  }

  /// `GET /Startup/User` — return the in-progress first user account
  /// being created by the wizard.
  Future<Map<String, dynamic>> firstUser() async {
    final res = await _http.request<Map<String, dynamic>>('/Startup/User');
    return res.data ?? const {};
  }

  /// `GET /Startup/FirstUser` — alternate path for [firstUser]
  /// (the v2 alias preserved for older clients).
  ///
  /// Obsolete in Jellyfin 12; [firstUser] is the supported route.
  @Deprecated('Obsolete in Jellyfin 12; use firstUser() instead.')
  Future<Map<String, dynamic>> firstUserAlt() async {
    final res = await _http.request<Map<String, dynamic>>('/Startup/FirstUser');
    return res.data ?? const {};
  }

  /// `POST /Startup/User` — write the first user's name and password.
  Future<void> updateStartupUser({
    String? name,
    String? password,
  }) async {
    await _http.request<void>(
      '/Startup/User',
      method: 'POST',
      data: {
        if (name != null) 'Name': name,
        if (password != null) 'Password': password,
      },
    );
  }

  /// `POST /Startup/RemoteAccess` — opt the server in or out of
  /// remote access during the wizard.
  ///
  /// Obsolete in Jellyfin 12; write the network section through
  /// `configuration.updateNamed('network', ...)` instead.
  @Deprecated(
    "Obsolete in Jellyfin 12; use configuration.updateNamed('network', …).",
  )
  Future<void> setRemoteAccess(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/Startup/RemoteAccess',
      method: 'POST',
      data: body,
    );
  }

  /// `POST /Startup/Complete` — finish the wizard. After this call
  /// the server starts accepting normal requests.
  Future<void> completeWizard() async {
    await _http.request<void>('/Startup/Complete', method: 'POST');
  }
}
