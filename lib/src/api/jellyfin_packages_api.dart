// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import 'jellyfin_plugins_api.dart';

/// `/Packages` and `/Repositories` — install new plugins from a
/// repository.
///
/// Wraps the `Package` OpenAPI tag (6 operations). Admin only.
/// Pairs with [JellyfinPluginsApi]: this sub-API handles
/// discovery/install, that one handles the lifecycle of an installed
/// plugin.
class JellyfinPackagesApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinPackagesApi(this._http);

  /// `GET /Packages` — list every package the server can install.
  Future<List<Map<String, Object?>>> list() async {
    final res = await _http.request<List<Object?>>('/Packages');
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  /// `GET /Packages/{name}` — info for one package (releases,
  /// download urls, dependencies).
  Future<Map<String, Object?>> byName({
    required String name,
    String? assemblyGuid,
  }) async {
    final qp = <String, Object?>{};
    if (assemblyGuid != null) qp['assemblyGuid'] = assemblyGuid;
    final res = await _http.request<Map<String, Object?>>(
      '/Packages/${Uri.encodeComponent(name)}',
      queryParameters: qp.isEmpty ? null : qp,
    );
    return res.data ?? const {};
  }

  /// `POST /Packages/Installed/{name}` — start installing a package.
  Future<void> install({
    required String name,
    String? assemblyGuid,
    String? version,
    String? repositoryUrl,
  }) async {
    final qp = <String, Object?>{};
    if (assemblyGuid != null) qp['assemblyGuid'] = assemblyGuid;
    if (version != null) qp['version'] = version;
    if (repositoryUrl != null) qp['repositoryUrl'] = repositoryUrl;
    await _http.request<void>(
      '/Packages/Installed/${Uri.encodeComponent(name)}',
      method: 'POST',
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  /// `DELETE /Packages/Installing/{packageId}` — cancel an in-flight
  /// install.
  Future<void> cancelInstall({
    required String packageId,
  }) async {
    await _http.request<void>(
      '/Packages/Installing/$packageId',
      method: 'DELETE',
    );
  }

  /// `GET /Repositories` — list configured plugin repositories.
  Future<List<Map<String, Object?>>> repositories() async {
    final res = await _http.request<List<Object?>>('/Repositories');
    final l = res.data ?? const [];
    return [
      for (final e in l)
        if (e is Map<String, Object?>) e,
    ];
  }

  /// `POST /Repositories` — replace the list of configured plugin
  /// repositories. Pass the full new list as [body].
  Future<void> setRepositories(List<Map<String, Object?>> body) async {
    await _http.request<void>(
      '/Repositories',
      method: 'POST',
      data: body,
    );
  }
}
