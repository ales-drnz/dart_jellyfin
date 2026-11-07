// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_admin_models.dart';
import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_parsing.dart';
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
  Future<List<JellyfinPackageInfo>> list() => _http.requestJson(
    '/Packages',
    listOf(JellyfinPackageInfo.fromJson),
  );

  /// `GET /Packages/{name}` — info for one package (releases,
  /// download urls, dependencies).
  Future<JellyfinPackageInfo> byName({
    required String name,
    String? assemblyGuid,
  }) {
    final qp = <String, Object?>{};
    if (assemblyGuid != null) qp['assemblyGuid'] = assemblyGuid;
    return _http.requestJson(
      '/Packages/${Uri.encodeComponent(name)}',
      queryParameters: qp.isEmpty ? null : qp,
      (json) =>
          objectOf(JellyfinPackageInfo.fromJson)(json) ??
          JellyfinPackageInfo.fromJson(const {}),
    );
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
  Future<List<JellyfinRepository>> repositories() => _http.requestJson(
    '/Repositories',
    listOf(JellyfinRepository.fromJson),
  );

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
