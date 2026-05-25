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
/// Jellyfin also still accepts the historical `X-Emby-Authorization`
/// header with the same payload (sans the leading `MediaBrowser`).
/// We send both for maximum compatibility.
abstract final class JellyfinAuthHeader {
  static String build(JellyfinCredentials c, {String? token}) {
    final tokenPart = token != null ? ', Token="$token"' : '';
    return 'MediaBrowser '
        'Client="${c.client}", '
        'Device="${c.device}", '
        'DeviceId="${c.deviceId}", '
        'Version="${c.version}"'
        '$tokenPart';
  }

  /// Historical `X-Emby-Authorization` payload — same fields, without
  /// the `MediaBrowser ` prefix.
  static String buildEmby(JellyfinCredentials c, {String? token}) {
    final tokenPart = token != null ? ', Token="$token"' : '';
    return 'Client="${c.client}", '
        'Device="${c.device}", '
        'DeviceId="${c.deviceId}", '
        'Version="${c.version}"'
        '$tokenPart';
  }
}
