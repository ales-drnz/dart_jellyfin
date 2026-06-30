// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../jellyfin_connection.dart';

/// `/ClientLog` — upload a client-side log file to the server.
///
/// Wraps the `ClientLog` OpenAPI tag (1 operation). Useful for crash
/// reporting from native clients.
class JellyfinClientLogApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinClientLogApi(this._http);

  /// `POST /ClientLog/Document` — upload a log document. [body] is
  /// the raw text/bytes of the log.
  ///
  /// Returns the `FileName` the server stored the log under (from the
  /// `ClientLogDocumentResponseDto`), or `null` if the server omits it.
  Future<String?> upload({
    required Uint8List body,
    String contentType = 'text/plain',
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/ClientLog/Document',
      method: 'POST',
      data: body,
      extraHeaders: {'Content-Type': contentType},
    );
    return res.data?['FileName'] as String?;
  }
}
