// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Branding` — branding configuration and custom CSS.
///
/// Wraps the `Branding` OpenAPI tag (3 operations).
class JellyfinBrandingApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinBrandingApi(this._http);

  /// `GET /Branding/Configuration` — branding options the admin
  /// configured (login wording, custom CSS body, splashscreen toggle).
  Future<Map<String, dynamic>> configuration() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Branding/Configuration',
    );
    return res.data ?? const {};
  }

  /// `GET /Branding/Css` — server's custom CSS as plain text.
  Future<String?> css() async {
    final res = await _http.request<String>('/Branding/Css');
    return res.data;
  }

  /// `GET /Branding/Css.css` — same as [css] but served with a
  /// `.css` filename so browsers honour it as a stylesheet.
  Future<String?> cssFile() async {
    final res = await _http.request<String>('/Branding/Css.css');
    return res.data;
  }
}
