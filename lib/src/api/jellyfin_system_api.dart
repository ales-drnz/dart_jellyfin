// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_admin_models.dart';
import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';
import '../jellyfin_server_models.dart';

/// `/System/*` endpoints — server info, public info, ping.
///
/// {@category System}
class JellyfinSystemApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinSystemApi(this._http);

  /// Authenticated server info (`GET /System/Info`).
  Future<JellyfinSystemInfo> info() async {
    final res = await _http.request<Map<String, Object?>>('/System/Info');
    return JellyfinSystemInfo.fromJson(res.data ?? const {});
  }

  /// Unauthenticated server info (`GET /System/Info/Public`) — useful
  /// for testing reachability and confirming the URL really points at a
  /// Jellyfin server before asking the user for credentials.
  Future<JellyfinSystemInfo> publicInfo() async {
    final res = await _http.request<Map<String, Object?>>(
      '/System/Info/Public',
    );
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
  Future<JellyfinEndpointInfo> endpointInfo() => _http.requestJson(
    '/System/Endpoint',
    (json) => JellyfinEndpointInfo.fromJson(_object(json)),
  );

  /// `GET /System/Info/Storage` — storage usage on every drive
  /// the server is configured to use.
  Future<JellyfinSystemStorage> storage() => _http.requestJson(
    '/System/Info/Storage',
    (json) => JellyfinSystemStorage.fromJson(_object(json)),
  );

  /// `GET /System/Logs` — list available log files, for [logFile].
  Future<List<JellyfinServerFile>> logs() => _http.requestJson(
    '/System/Logs',
    listOf(JellyfinServerFile.fromJson),
  );

  /// `GET /System/Logs/Log?name={name}` — fetch one log file as
  /// plain text; `''` for an empty file.
  Future<String?> logFile({
    required String name,
  }) async {
    final res = await _http.request<String>(
      '/System/Logs/Log',
      queryParameters: {'name': name},
    );
    return res.data ?? '';
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
  Future<JellyfinUtcTime> utcTime() => _http.requestJson(
    '/GetUtcTime',
    (json) => JellyfinUtcTime.fromJson(_object(json)),
  );
}

Map<String, Object?> _object(Object? json) =>
    json is Map<String, Object?> ? json : const <String, Object?>{};
