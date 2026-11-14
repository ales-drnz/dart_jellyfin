// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport '../jellyfin_client.dart';
library;

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';
import '../jellyfin_parsing.dart';

/// `/Collections` — manage Jellyfin's "Collection" item type.
///
/// Wraps the `Collection` OpenAPI tag (3 operations). Collections are
/// hand-curated groupings (e.g. "Star Wars saga", "Best of 2024").
/// They live as `BoxSet`-typed items and can be browsed through
/// `items.list()` like any other item.
///
/// {@category Library}
class JellyfinCollectionApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinCollectionApi(this._http);

  /// `POST /Collections` — create a new collection.
  ///
  /// Answers the new collection's id in
  /// [JellyfinCollectionCreationResult.id]. An answer without an id
  /// throws a `parse` error.
  Future<JellyfinCollectionCreationResult> create({
    String? name,
    List<String> ids = const [],
    String? parentId,
    bool? isLocked,
  }) {
    final qp = <String, Object?>{
      'name': ?name,
      if (ids.isNotEmpty) 'ids': ids,
      'parentId': ?parentId,
      'isLocked': ?isLocked,
    };

    return _http.requestJson(
      '/Collections',
      method: 'POST',
      queryParameters: qp,
      requiredObjectOf(JellyfinCollectionCreationResult.fromJson, keys: ['Id']),
    );
  }

  /// `POST /Collections/{collectionId}/Items?ids={ids}` — splice
  /// items into the collection.
  Future<void> addItems({
    required String collectionId,
    required List<String> ids,
  }) async {
    await _http.request<void>(
      '/Collections/$collectionId/Items',
      method: 'POST',
      queryParameters: {'ids': ids},
    );
  }

  /// `DELETE /Collections/{collectionId}/Items?ids={ids}` — remove
  /// items from the collection (they keep existing as library items).
  Future<void> removeItems({
    required String collectionId,
    required List<String> ids,
  }) async {
    await _http.request<void>(
      '/Collections/$collectionId/Items',
      method: 'DELETE',
      queryParameters: {'ids': ids},
    );
  }
}
