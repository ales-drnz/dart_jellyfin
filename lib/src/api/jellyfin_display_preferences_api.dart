// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/DisplayPreferences/*` — per-client UI state, stored on the
/// server so layout choices follow the user across devices.
///
/// Wraps the `DisplayPreferences` OpenAPI tag (2 operations). The
/// `displayPreferencesId` is the namespace inside which the
/// preferences live (e.g. `usersettings`, or a library id for
/// library-scoped layout state). The `client` query parameter
/// disambiguates between different clients writing into the same id.
class JellyfinDisplayPreferencesApi {
  final JellyfinConnection _http;

  JellyfinDisplayPreferencesApi(this._http);

  /// `GET /DisplayPreferences/{id}` — fetch one preference document.
  Future<JellyfinDisplayPreferences> get({
    required String displayPreferencesId,
    required String client,
  }) async {
    final qp = <String, dynamic>{'client': client};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    final res = await _http.request<Map<String, dynamic>>(
      '/DisplayPreferences/${Uri.encodeComponent(displayPreferencesId)}',
      queryParameters: qp,
    );
    return JellyfinDisplayPreferences.fromJson(res.data ?? const {});
  }

  /// `POST /DisplayPreferences/{id}` — replace the document.
  Future<void> update({
    required String displayPreferencesId,
    required String client,
    required JellyfinDisplayPreferences preferences,
  }) async {
    final qp = <String, dynamic>{'client': client};
    final userId = _http.userId;
    if (userId != null) qp['userId'] = userId;
    await _http.request<void>(
      '/DisplayPreferences/${Uri.encodeComponent(displayPreferencesId)}',
      method: 'POST',
      queryParameters: qp,
      data: preferences.toJson(),
    );
  }
}
