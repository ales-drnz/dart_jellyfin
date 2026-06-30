// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Items/{itemId}/RemoteImages*` — fetch images from metadata
/// providers.
///
/// Wraps the `RemoteImage` OpenAPI tag (3 operations). Used by the
/// "Edit images" UI: list candidates from configured providers,
/// then download the chosen one to attach as the item image.
class JellyfinRemoteImageApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinRemoteImageApi(this._http);

  /// `GET /Items/{itemId}/RemoteImages` — list candidate images
  /// from remote providers, optionally filtered by image type and
  /// provider name.
  Future<Map<String, dynamic>> list({
    required String itemId,
    String? type,
    int? startIndex,
    int? limit,
    String? providerName,
    bool includeAllLanguages = false,
  }) async {
    final qp = <String, dynamic>{
      'includeAllLanguages': includeAllLanguages,
    };
    if (type != null) qp['type'] = type;
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (limit != null) qp['limit'] = limit;
    if (providerName != null) qp['providerName'] = providerName;
    final res = await _http.request<Map<String, dynamic>>(
      '/Items/$itemId/RemoteImages',
      queryParameters: qp,
    );
    return res.data ?? const {};
  }

  /// `POST /Items/{itemId}/RemoteImages/Download?type={type}&imageUrl={url}` —
  /// download the picked candidate and attach it to the item.
  Future<void> download({
    required String itemId,
    required String type,
    required String imageUrl,
  }) async {
    await _http.request<void>(
      '/Items/$itemId/RemoteImages/Download',
      method: 'POST',
      queryParameters: {'type': type, 'imageUrl': imageUrl},
    );
  }

  /// `GET /Items/{itemId}/RemoteImages/Providers` — list providers
  /// that can supply remote images for this item.
  Future<List<Map<String, dynamic>>> providers(String itemId) async {
    final res = await _http.request<List<dynamic>>(
      '/Items/$itemId/RemoteImages/Providers',
    );
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
