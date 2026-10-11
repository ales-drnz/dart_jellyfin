// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_server_models.dart';

/// `/Devices` — admin view of clients that have logged into the
/// server.
///
/// Wraps the `Devices` OpenAPI tag (5 operations). Admin only.
class JellyfinDevicesApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinDevicesApi(this._http);

  /// `GET /Devices` — list registered devices, optionally scoped to
  /// one user.
  Future<List<JellyfinDevice>> list({String? userId}) {
    final qp = <String, dynamic>{};
    if (userId != null) qp['userId'] = userId;
    return _http.requestJson(
      '/Devices',
      queryParameters: qp.isEmpty ? null : qp,
      (json) => queryResultOf(JellyfinDevice.fromJson)(json).items,
    );
  }

  /// `DELETE /Devices?id={id}` — revoke a device (logs it out).
  Future<void> delete(String id) async {
    await _http.request<void>(
      '/Devices',
      method: 'DELETE',
      queryParameters: {'id': id},
    );
  }

  /// `GET /Devices/Info?id={id}` — full info for one device.
  Future<JellyfinDevice?> info(String id) => _http.requestJson(
        '/Devices/Info',
        queryParameters: {'id': id},
        objectOf(JellyfinDevice.fromJson),
      );

  /// `GET /Devices/Options?id={id}` — per-device admin options
  /// (custom name, …).
  Future<Map<String, dynamic>> options(String id) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Devices/Options',
      queryParameters: {'id': id},
    );
    return res.data ?? const {};
  }

  /// `POST /Devices/Options?id={id}` — replace the device options.
  Future<void> updateOptions({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    await _http.request<void>(
      '/Devices/Options',
      method: 'POST',
      queryParameters: {'id': id},
      data: body,
    );
  }
}
