// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Library/VirtualFolders` — server-side library configuration.
///
/// Wraps the `LibraryStructure` OpenAPI tag (8 operations). Admin
/// only. Used by the dashboard "Libraries" page to add, rename, and
/// remove libraries, and to manage the physical folder roots backing
/// each library.
class JellyfinLibraryStructureApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinLibraryStructureApi(this._http);

  /// `GET /Library/VirtualFolders` — list every configured library.
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _http.request<List<dynamic>>('/Library/VirtualFolders');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `POST /Library/VirtualFolders` — create a new library.
  Future<void> add({
    String? name,
    String? collectionType,
    List<String> paths = const [],
    Map<String, dynamic>? libraryOptions,
    bool refreshLibrary = false,
  }) async {
    final qp = <String, dynamic>{'refreshLibrary': refreshLibrary};
    if (name != null) qp['name'] = name;
    if (collectionType != null) qp['collectionType'] = collectionType;
    if (paths.isNotEmpty) qp['paths'] = paths;
    await _http.request<void>(
      '/Library/VirtualFolders',
      method: 'POST',
      queryParameters: qp,
      data: libraryOptions == null ? null : {'LibraryOptions': libraryOptions},
    );
  }

  /// `DELETE /Library/VirtualFolders?name={name}` — delete a library.
  Future<void> remove({
    required String name,
    bool refreshLibrary = false,
  }) async {
    await _http.request<void>(
      '/Library/VirtualFolders',
      method: 'DELETE',
      queryParameters: {'name': name, 'refreshLibrary': refreshLibrary},
    );
  }

  /// `POST /Library/VirtualFolders/Name?name={old}&newName={new}` —
  /// rename a library.
  Future<void> rename({
    required String name,
    required String newName,
    bool refreshLibrary = false,
  }) async {
    await _http.request<void>(
      '/Library/VirtualFolders/Name',
      method: 'POST',
      queryParameters: {
        'name': name,
        'newName': newName,
        'refreshLibrary': refreshLibrary,
      },
    );
  }

  /// `POST /Library/VirtualFolders/LibraryOptions` — update the
  /// options of a library (metadata fetchers, image fetchers,
  /// chapter image config, …).
  Future<void> updateLibraryOptions(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/Library/VirtualFolders/LibraryOptions',
      method: 'POST',
      data: body,
    );
  }

  /// `POST /Library/VirtualFolders/Paths?refreshLibrary=...` —
  /// add a physical folder to a library.
  Future<void> addMediaPath({
    required Map<String, dynamic> body,
    bool refreshLibrary = false,
  }) async {
    await _http.request<void>(
      '/Library/VirtualFolders/Paths',
      method: 'POST',
      queryParameters: {'refreshLibrary': refreshLibrary},
      data: body,
    );
  }

  /// `DELETE /Library/VirtualFolders/Paths?name=...&path=...` —
  /// remove a physical folder from a library.
  Future<void> removeMediaPath({
    required String name,
    required String path,
    bool refreshLibrary = false,
  }) async {
    await _http.request<void>(
      '/Library/VirtualFolders/Paths',
      method: 'DELETE',
      queryParameters: {
        'name': name,
        'path': path,
        'refreshLibrary': refreshLibrary,
      },
    );
  }

  /// `POST /Library/VirtualFolders/Paths/Update` — update a
  /// physical folder's options (e.g. network credentials).
  Future<void> updateMediaPath(Map<String, dynamic> body) async {
    await _http.request<void>(
      '/Library/VirtualFolders/Paths/Update',
      method: 'POST',
      data: body,
    );
  }
}
