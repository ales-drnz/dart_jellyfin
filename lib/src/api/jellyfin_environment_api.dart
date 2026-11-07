// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_admin_models.dart';
import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_parsing.dart';

/// `/Environment` — server-host filesystem browse helpers.
///
/// Wraps the `Environment` OpenAPI tag (5 operations). Admin only.
/// Used by the dashboard "Add library" flow to browse the server's
/// filesystem when choosing a media folder root.
class JellyfinEnvironmentApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinEnvironmentApi(this._http);

  /// `GET /Environment/DirectoryContents` — entries under [path].
  ///
  /// Tuned for the directory-browse UI: this client defaults
  /// [includeDirectories] to `true`, unlike the OpenAPI spec which
  /// defaults it to `false`. [includeFiles] keeps the spec default of
  /// `false`. Both are always sent on the wire.
  Future<List<JellyfinFileSystemEntry>> directoryContents({
    required String path,
    bool includeFiles = false,
    bool includeDirectories = true,
  }) => _http.requestJson(
    '/Environment/DirectoryContents',
    queryParameters: {
      'path': path,
      'includeFiles': includeFiles,
      'includeDirectories': includeDirectories,
    },
    listOf(JellyfinFileSystemEntry.fromJson),
  );

  /// `GET /Environment/DefaultDirectoryBrowser` — server's
  /// suggested starting directory for the browse UI.
  Future<JellyfinDefaultDirectoryBrowser> defaultDirectoryBrowser() =>
      _http.requestJson(
        '/Environment/DefaultDirectoryBrowser',
        (json) =>
            objectOf(JellyfinDefaultDirectoryBrowser.fromJson)(json) ??
            JellyfinDefaultDirectoryBrowser.fromJson(const {}),
      );

  /// `GET /Environment/Drives` — every drive mounted on the server.
  Future<List<JellyfinFileSystemEntry>> drives() => _http.requestJson(
    '/Environment/Drives',
    listOf(JellyfinFileSystemEntry.fromJson),
  );

  /// `GET /Environment/ParentPath?path={path}` — the parent
  /// directory of [path] (or the platform root if [path] is the
  /// root).
  Future<String?> parentPath({required String path}) async {
    final res = await _http.request<String>(
      '/Environment/ParentPath',
      queryParameters: {'path': path},
    );
    return res.data;
  }

  /// `POST /Environment/ValidatePath` — ask the server whether
  /// [body] describes a valid, accessible path.
  Future<void> validatePath(Map<String, Object?> body) async {
    await _http.request<void>(
      '/Environment/ValidatePath',
      method: 'POST',
      data: body,
    );
  }
}
