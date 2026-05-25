// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Identity of the client app talking to Jellyfin.
///
/// Sent on every request as the four fields of the `Authorization:
/// MediaBrowser` header. `deviceId` MUST be a stable per-installation
/// UUID — Jellyfin tracks sessions by it.
class JellyfinCredentials {
  /// Application name (e.g. `'Finova'`). Goes into `Client="…"`.
  final String client;

  /// Device hardware/category (e.g. `'iPhone'`). Goes into `Device="…"`.
  final String device;

  /// Stable per-install UUID. Goes into `DeviceId="…"`.
  final String deviceId;

  /// Application version (semver). Goes into `Version="…"`.
  final String version;

  /// Creates a credentials bundle from the four header fields.
  const JellyfinCredentials({
    required this.client,
    required this.device,
    required this.deviceId,
    required this.version,
  });

  /// Returns a copy with the given fields overridden.
  JellyfinCredentials copyWith({
    String? client,
    String? device,
    String? deviceId,
    String? version,
  }) =>
      JellyfinCredentials(
        client: client ?? this.client,
        device: device ?? this.device,
        deviceId: deviceId ?? this.deviceId,
        version: version ?? this.version,
      );
}
