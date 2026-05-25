// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/System/*` endpoints — server info, public info, ping.
class JellyfinSystemApi {
  final JellyfinConnection _http;

  JellyfinSystemApi(this._http);

  /// Authenticated server info (`GET /System/Info`).
  Future<JellyfinSystemInfo> info() async {
    final res = await _http.request<Map<String, dynamic>>('/System/Info');
    return JellyfinSystemInfo.fromJson(res.data ?? const {});
  }

  /// Unauthenticated server info (`GET /System/Info/Public`) — useful
  /// for testing reachability and confirming the URL really points at a
  /// Jellyfin server before asking the user for credentials.
  Future<JellyfinSystemInfo> publicInfo() async {
    final res =
        await _http.request<Map<String, dynamic>>('/System/Info/Public');
    return JellyfinSystemInfo.fromJson(res.data ?? const {});
  }

  /// `true` when the server replies to `/System/Info/Public`.
  Future<bool> ping() async {
    try {
      await publicInfo();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// `GET /System/Endpoint` — info about the request endpoint
  /// (whether the request looks local or remote to the server).
  Future<Map<String, dynamic>> endpointInfo() async {
    final res = await _http.request<Map<String, dynamic>>('/System/Endpoint');
    return res.data ?? const {};
  }

  /// `GET /System/Info/Storage` — storage usage on every drive
  /// the server is configured to use.
  Future<Map<String, dynamic>> storage() async {
    final res =
        await _http.request<Map<String, dynamic>>('/System/Info/Storage');
    return res.data ?? const {};
  }

  /// `GET /System/Logs` — list available log files.
  Future<List<Map<String, dynamic>>> logs() async {
    final res = await _http.request<List<dynamic>>('/System/Logs');
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `GET /System/Logs/Log?name={name}` — fetch one log file as
  /// plain text.
  Future<String?> logFile(String name) async {
    final res = await _http.request<String>(
      '/System/Logs/Log',
      queryParameters: {'name': name},
    );
    return res.data;
  }

  /// `GET /System/Ping` — lightweight reachability check that
  /// echoes the server name. Returns null on parse failure.
  Future<String?> pingEcho() async {
    final res = await _http.request<String>('/System/Ping');
    return res.data;
  }

  /// `POST /System/Ping` — round-trip ping with stateless writes
  /// (kept for protocol completeness; the response body is the
  /// server's name).
  Future<String?> pingEchoPost() async {
    final res = await _http.request<String>('/System/Ping', method: 'POST');
    return res.data;
  }

  /// `POST /System/Restart` — restart the server. Admin only.
  Future<void> restart() async {
    await _http.request<void>('/System/Restart', method: 'POST');
  }

  /// `POST /System/Shutdown` — shut the server down. Admin only.
  Future<void> shutdown() async {
    await _http.request<void>('/System/Shutdown', method: 'POST');
  }

  /// `GET /GetUtcTime` — the server's current UTC clock, returned
  /// as `{ RequestReceptionTime, ResponseTransmissionTime }`. Used
  /// for time-sync between clients and server.
  Future<Map<String, dynamic>> utcTime() async {
    final res = await _http.request<Map<String, dynamic>>('/GetUtcTime');
    return res.data ?? const {};
  }
}
