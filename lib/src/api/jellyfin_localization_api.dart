// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';

/// `/Localization/*` — country, culture, and parental-rating
/// catalogs maintained by the server.
///
/// Wraps the `Localization` OpenAPI tag (4 operations). Used by
/// picker UIs ("set parental rating", "choose preferred audio
/// language") so the values match what the server actually accepts.
class JellyfinLocalizationApi {
  final JellyfinConnection _http;

  JellyfinLocalizationApi(this._http);

  /// `GET /Localization/Countries` — every country the server knows
  /// about, each entry returned as a raw map (`Name`,
  /// `DisplayName`, `TwoLetterISORegionName`, …).
  Future<List<Map<String, dynamic>>> countries() => _flatList('/Localization/Countries');

  /// `GET /Localization/Cultures` — every culture/language the
  /// server knows about. Each entry carries the two- and three-letter
  /// ISO codes plus display names.
  Future<List<Map<String, dynamic>>> cultures() => _flatList('/Localization/Cultures');

  /// `GET /Localization/Options` — the localization options
  /// configured on the server (the choices an admin picked for
  /// preferred metadata language, etc.).
  Future<List<Map<String, dynamic>>> options() => _flatList('/Localization/Options');

  /// `GET /Localization/ParentalRatings` — the parental rating
  /// scale the server uses. Each entry maps a numeric value to a
  /// display name (e.g. `'PG-13'`).
  Future<List<Map<String, dynamic>>> parentalRatings() =>
      _flatList('/Localization/ParentalRatings');

  Future<List<Map<String, dynamic>>> _flatList(String path) async {
    final res = await _http.request<List<dynamic>>(path);
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
