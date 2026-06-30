// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// Internal helper shared by the `byName` lookups on Genres, MusicGenres,
/// Studios, Artists, and Persons.
///
/// Issues `GET {basePath}/{name}` (with the current `userId` attached when
/// available), decodes the body into a [JellyfinItem], and returns null when
/// the server responds 404 (no item matches [name]).
///
/// Not exported from the package barrel; intended for use only by the API
/// wrappers in this directory.
Future<JellyfinItem?> lookupItemByName(
  String basePath,
  String name,
  JellyfinConnection http,
) async {
  final qp = <String, dynamic>{};
  final userId = http.userId;
  if (userId != null) qp['userId'] = userId;
  try {
    final res = await http.request<Map<String, dynamic>>(
      '$basePath/${Uri.encodeComponent(name)}',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final data = res.data;
    if (data == null) return null;
    return JellyfinItem.fromJson(data);
  } on JellyfinException catch (e) {
    if (e.type == JellyfinErrorType.notFound) return null;
    rethrow;
  }
}
