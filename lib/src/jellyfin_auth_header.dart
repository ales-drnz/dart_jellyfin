// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'jellyfin_credentials.dart';

/// Builds the `Authorization: MediaBrowser …` header.
///
/// Pre-login (no token yet):
///
/// ```
/// MediaBrowser Client="Finova", Device="iPhone", DeviceId="…uuid…", Version="1.0"
/// ```
///
/// Post-login:
///
/// ```
/// MediaBrowser Client="Finova", Device="iPhone", DeviceId="…uuid…", Version="1.0", Token="…"
/// ```
///
/// Each value is percent-encoded with [Uri.encodeComponent] before being
/// quoted. Jellyfin's server-side parser runs `WebUtility.UrlDecode` on every
/// extracted value and splits the comma-separated list on unescaped `,`/`"`,
/// so raw values would corrupt the header: a `+` (e.g. semver build metadata
/// `1.0.0+42`) decodes to a space, and an embedded `"` desyncs the tokenizer
/// and merges fields. Encoding round-trips cleanly through `UrlDecode` while
/// leaving unreserved characters (letters, digits, `.`, `-`, `_`) untouched.
abstract final class JellyfinAuthHeader {
  /// Modern `Authorization: MediaBrowser …` payload, with optional `Token`.
  static String build(JellyfinCredentials c, {String? token}) {
    final tokenPart =
        token != null ? ', Token="${Uri.encodeComponent(token)}"' : '';
    return 'MediaBrowser '
        'Client="${Uri.encodeComponent(c.client)}", '
        'Device="${Uri.encodeComponent(c.device)}", '
        'DeviceId="${Uri.encodeComponent(c.deviceId)}", '
        'Version="${Uri.encodeComponent(c.version)}"'
        '$tokenPart';
  }
}
