// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// What the URL builders share: the URLs a player or an image widget
/// opens itself, signed with `ApiKey` because it sends no auth header.
/// Not exported.
library;

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';

/// The base URL and the token a URL builder needs, or a `state` error.
extension JellyfinUrlParts on JellyfinConnection {
  /// The server root, or a [JellyfinException] of type
  /// [JellyfinErrorType.state] before [JellyfinClient.connect].
  String requireBaseUrl() {
    final url = baseUrl;
    if (url == null) {
      throw const JellyfinException(
        'No base URL — call JellyfinClient.connect() first.',
        type: JellyfinErrorType.state,
      );
    }
    return url;
  }

  /// The access token, or a [JellyfinException] of type
  /// [JellyfinErrorType.state] before [JellyfinClient.setSession].
  String requireToken() {
    final t = token;
    if (t == null) {
      throw const JellyfinException(
        'No token — call JellyfinClient.setSession() first.',
        type: JellyfinErrorType.state,
      );
    }
    return t;
  }

  /// `?ApiKey=<token>`, the whole query of a URL signed and nothing else.
  String get apiKeyQuery =>
      '?ApiKey=${Uri.encodeQueryComponent(requireToken())}';
}

/// [qp] as `k=v&k2=v2`, each value form-encoded.
String encodeQuery(Map<String, String> qp) => qp.entries
    .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
    .join('&');

/// A path segment that is not an id — a name, a language, a command —
/// percent-encoded, so a space or a `/` in it cannot change the route.
String seg(String value) => Uri.encodeComponent(value);
