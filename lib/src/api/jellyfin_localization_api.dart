// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_admin_models.dart';
import '../jellyfin_client.dart';
import '../jellyfin_connection.dart';
import '../jellyfin_parsing.dart';

/// `/Localization/*` — country, culture, and parental-rating
/// catalogs maintained by the server.
///
/// Wraps the `Localization` OpenAPI tag (4 operations). Used by
/// picker UIs ("set parental rating", "choose preferred audio
/// language") so the values match what the server actually accepts.
///
/// {@category System}
class JellyfinLocalizationApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinLocalizationApi(this._http);

  /// `GET /Localization/Countries` — every country the server knows
  /// about.
  Future<List<JellyfinCountry>> countries() => _http.requestJson(
    '/Localization/Countries',
    listOf(JellyfinCountry.fromJson),
  );

  /// `GET /Localization/Cultures` — every culture/language the
  /// server knows about, with its two- and three-letter ISO codes.
  Future<List<JellyfinCulture>> cultures() => _http.requestJson(
    '/Localization/Cultures',
    listOf(JellyfinCulture.fromJson),
  );

  /// `GET /Localization/Options` — the dashboard languages the server
  /// offers, as `{Name, Value}` pairs (`Value` is the culture code).
  Future<List<JellyfinNameValuePair>> options() => _http.requestJson(
    '/Localization/Options',
    listOf(JellyfinNameValuePair.fromJson),
  );

  /// `GET /Localization/ParentalRatings` — the parental rating
  /// scale the server uses. Each entry maps a display name (e.g.
  /// `'PG-13'`) to a numeric value.
  Future<List<JellyfinParentalRating>> parentalRatings() => _http.requestJson(
    '/Localization/ParentalRatings',
    listOf(JellyfinParentalRating.fromJson),
  );
}
