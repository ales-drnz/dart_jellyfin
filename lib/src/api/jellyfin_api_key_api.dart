// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import 'jellyfin_url_helpers.dart';

/// `/Auth/Keys` — API key management.
///
/// Wraps the `ApiKey` OpenAPI tag (3 operations). Admin only.
/// API keys grant headless access (CI scripts, integrations) without
/// going through the user-login flow.
///
/// {@category System}
class JellyfinApiKeyApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinApiKeyApi(this._http);

  /// `GET /Auth/Keys` — list active API keys.
  ///
  /// The server wraps the keys in a `QueryResult` envelope
  /// (`{Items, TotalRecordCount}`); this answers its `Items`.
  Future<List<JellyfinApiKey>> list() => _http.requestJson(
    '/Auth/Keys',
    (json) => queryResultOf(JellyfinApiKey.fromJson)(json).items,
  );

  /// `POST /Auth/Keys?app={app}` — create a new API key for [app].
  Future<void> create({required String app}) async {
    await _http.request<void>(
      '/Auth/Keys',
      method: 'POST',
      queryParameters: {'app': app},
    );
  }

  /// `DELETE /Auth/Keys/{key}` — revoke an API key by its value.
  Future<void> revoke({required String key}) async {
    await _http.request<void>('/Auth/Keys/${seg(key)}', method: 'DELETE');
  }
}
