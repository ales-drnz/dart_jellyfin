// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Auth/Keys` — API key management.
///
/// Wraps the `ApiKey` OpenAPI tag (3 operations). Admin only.
/// API keys grant headless access (CI scripts, integrations) without
/// going through the user-login flow.
class JellyfinApiKeyApi {
  final JellyfinConnection _http;

  JellyfinApiKeyApi(this._http);

  /// `GET /Auth/Keys` — list active API keys.
  ///
  /// The server wraps the keys in a `QueryResult` envelope
  /// (`{Items, TotalRecordCount}`), so we lift the `Items` array out.
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _http.request<Map<String, dynamic>>('/Auth/Keys');
    final items = res.data?['Items'];
    if (items is! List) return const [];
    return [for (final e in items) if (e is Map<String, dynamic>) e];
  }

  /// `POST /Auth/Keys?app={app}` — create a new API key for [app].
  Future<void> create(String app) async {
    await _http.request<void>(
      '/Auth/Keys',
      method: 'POST',
      queryParameters: {'app': app},
    );
  }

  /// `DELETE /Auth/Keys/{key}` — revoke an API key by its value.
  Future<void> revoke(String key) async {
    await _http.request<void>('/Auth/Keys/$key', method: 'DELETE');
  }
}
