// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/Items/{itemId}/RemoteImages*` — fetch images from metadata
/// providers.
///
/// Wraps the `RemoteImage` OpenAPI tag (3 operations). Used by the
/// "Edit images" UI: list candidates from configured providers,
/// then download the chosen one to attach as the item image.
///
/// {@category System}
class JellyfinRemoteImageApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinRemoteImageApi(this._http);

  /// `GET /Items/{itemId}/RemoteImages` — list candidate images
  /// from remote providers, optionally filtered by image type and
  /// provider name.
  Future<JellyfinRemoteImageResult> list({
    required String itemId,
    String? type,
    int? startIndex,
    int? limit,
    String? providerName,
    bool includeAllLanguages = false,
  }) {
    final qp = <String, Object?>{
      'includeAllLanguages': includeAllLanguages,
      'type': ?type,
      'startIndex': ?startIndex,
      'limit': ?limit,
      'providerName': ?providerName,
    };
    return _http.requestJson(
      '/Items/$itemId/RemoteImages',
      queryParameters: qp,
      objectOrEmptyOf(JellyfinRemoteImageResult.fromJson),
    );
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
  Future<List<JellyfinImageProviderInfo>> providers({required String itemId}) =>
      _http.requestJson(
        '/Items/$itemId/RemoteImages/Providers',
        listOf(JellyfinImageProviderInfo.fromJson),
      );
}
