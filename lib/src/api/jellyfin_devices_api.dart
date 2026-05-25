// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Devices` — admin view of clients that have logged into the
/// server.
///
/// Wraps the `Devices` OpenAPI tag (5 operations). Admin only.
class JellyfinDevicesApi {
  final JellyfinConnection _http;

  JellyfinDevicesApi(this._http);

  /// `GET /Devices` — list registered devices, optionally scoped to
  /// one user.
  Future<List<Map<String, dynamic>>> list({String? userId}) async {
    final qp = <String, dynamic>{};
    if (userId != null) qp['userId'] = userId;
    final res = await _http.request<Map<String, dynamic>>(
      '/Devices',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final items = res.data?['Items'];
    if (items is! List) return const [];
    return [for (final e in items) if (e is Map<String, dynamic>) e];
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
  Future<Map<String, dynamic>> info(String id) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Devices/Info',
      queryParameters: {'id': id},
    );
    return res.data ?? const {};
  }

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
