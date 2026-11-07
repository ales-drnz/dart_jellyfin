// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/Backup` — server-side backup and restore.
///
/// Wraps the `Backup` OpenAPI tag (4 operations). Admin only.
class JellyfinBackupApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinBackupApi(this._http);

  /// `GET /Backup` — list backup files known to the server.
  Future<List<JellyfinBackupManifest>> list() =>
      _http.requestJson('/Backup', listOf(JellyfinBackupManifest.fromJson));

  /// `POST /Backup/Create` — create a new backup. [body] carries
  /// the inclusion options (`BackupOptionsDto`: `Metadata`, `Trickplay`,
  /// `Subtitles`, `Database`). Answers the new backup's manifest.
  Future<JellyfinBackupManifest> create(Map<String, Object?> body) =>
      _http.requestJson(
        '/Backup/Create',
        method: 'POST',
        data: body,
        objectOrEmptyOf(JellyfinBackupManifest.fromJson),
      );

  /// `GET /Backup/Manifest?path={path}` — read the manifest of a
  /// specific backup file.
  Future<JellyfinBackupManifest> manifest({required String path}) =>
      _http.requestJson(
        '/Backup/Manifest',
        queryParameters: {'path': path},
        objectOrEmptyOf(JellyfinBackupManifest.fromJson),
      );

  /// `POST /Backup/Restore` — restore from a backup file. [body]
  /// describes which file and which sections to restore.
  Future<void> restore(Map<String, Object?> body) async {
    await _http.request<void>('/Backup/Restore', method: 'POST', data: body);
  }
}
