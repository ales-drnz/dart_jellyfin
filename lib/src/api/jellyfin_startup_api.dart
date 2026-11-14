// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
/// @docImport 'jellyfin_configuration_api.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/Startup` — first-run wizard endpoints.
///
/// Wraps the wizard steps of the `Startup` OpenAPI tag. Used only during
/// the initial server setup flow. After [completeWizard] is called
/// these endpoints stop accepting writes.
///
/// Jellyfin 12 marks the configuration-shaped routes obsolete in favour
/// of `/System/Configuration` (see [JellyfinConfigurationApi]), and 0.4.0
/// removed them. A wizard that must still send them uses
/// `JellyfinClient.request`.
///
/// {@category System}
class JellyfinStartupApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinStartupApi(this._http);

  /// `GET /Startup/User` — return the in-progress first user account
  /// being created by the wizard.
  ///
  /// The 12.x API document marks this route obsolete without naming a
  /// replacement, and the 12.x wizard still calls it: the server accepts
  /// [updateStartupUser] only after it.
  Future<JellyfinStartupUser> firstUser() => _http.requestJson(
    '/Startup/User',
    objectOrEmptyOf(JellyfinStartupUser.fromJson),
  );

  /// `POST /Startup/User` — write the first user's name and password.
  Future<void> updateStartupUser({String? name, String? password}) async {
    await _http.request<void>(
      '/Startup/User',
      method: 'POST',
      data: {'Name': ?name, 'Password': ?password},
    );
  }

  /// `POST /Startup/Complete` — finish the wizard. After this call
  /// the server starts accepting normal requests.
  Future<void> completeWizard() async {
    await _http.request<void>('/Startup/Complete', method: 'POST');
  }
}
