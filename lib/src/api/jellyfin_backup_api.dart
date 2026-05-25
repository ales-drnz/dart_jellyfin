// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Backup` — server-side backup and restore.
///
/// Wraps the `Backup` OpenAPI tag (4 operations). Admin only.
class JellyfinBackupApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinBackupApi(this._http);

  /// `GET /Backup` — list backup files known to the server.
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _http.request<List<dynamic>>('/Backup');
    final l = res.data ?? const [];
    return [for (final e in l) if (e is Map<String, dynamic>) e];
  }

  /// `POST /Backup/Create` — create a new backup. [body] carries
  /// the inclusion options (metadata, plugins, library, …).
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Backup/Create',
      method: 'POST',
      data: body,
    );
    return res.data ?? const {};
  }

  /// `GET /Backup/Manifest?path={path}` — read the manifest of a
  /// specific backup file.
  Future<Map<String, dynamic>> manifest(String path) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Backup/Manifest',
      queryParameters: {'path': path},
    );
    return res.data ?? const {};
  }

  /// `POST /Backup/Restore` — restore from a backup file. [body]
  /// describes which file and which sections to restore.
  Future<void> restore(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/Backup/Restore',
      method: 'POST',
      data: body,
    );
  }
}
