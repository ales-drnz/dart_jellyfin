// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// What the sub-APIs share when they ask and read. Not exported.
library;

import '../jellyfin_connection.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_vocabulary.dart';
import 'jellyfin_text_body.dart';

/// The answer of [call], or `null` when the server answers `404`: for a
/// read of one thing by its id or name, a confirmed absence is an answer,
/// not a failure. Every other error is thrown as it came.
Future<T?> nullOnNotFound<T>(Future<T?> Function() call) async {
  try {
    return await call();
  } on JellyfinException catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}

/// Requests that read one thing.
extension JellyfinLookups on JellyfinConnection {
  /// [JellyfinConnection.requestJson], answering `null` on a `404` (see
  /// [nullOnNotFound]) and for an empty body, as [parse] decides.
  Future<R?> requestJsonOrNull<R>(
    String path,
    R? Function(Object? json) parse, {
    Map<String, Object?>? queryParameters,
  }) => nullOnNotFound(
    () => requestJson(path, parse, queryParameters: queryParameters),
  );

  /// The body of a `GET` to [path] as text — a subtitle or lyric file —
  /// decoded by its byte-order mark, then the response's `charset`, then
  /// as UTF-8 with a Latin-1 fallback (see [decodeTextBody]). `null` on a
  /// `404` and for an empty body.
  Future<String?> requestTextOrNull(String path) => nullOnNotFound(() async {
    final res = await requestBytes(path, absoluteUrl: false);
    final body = res.data;
    if (body == null || body.isEmpty) return null;
    return decodeTextBody(body, contentType: res.contentType);
  });
}

/// The query entries the list routes for genres, studios, people, years
/// and artists have in common, each left out when its argument is `null`
/// or empty. A route's own entries go beside it:
/// `{'startIndex': startIndex, ...browseQuery(...)}`.
///
/// [searchTerm] is left out when empty too, and `sortOrder` travels only
/// with a [sortBy]: the server ignores an order without a column.
Map<String, Object?> browseQuery({
  String? userId,
  String? parentId,
  String? searchTerm,
  int? limit,
  List<JellyfinSortField> sortBy = const [],
  bool descending = false,
  List<JellyfinItemField> fields = const [],
  List<JellyfinItemFilter> filters = const [],
  List<JellyfinItemKind> includeItemTypes = const [],
  List<JellyfinItemKind> excludeItemTypes = const [],
  bool? isFavorite,
  int? imageTypeLimit,
  List<String> enableImageTypes = const [],
  String? nameStartsWith,
  String? nameStartsWithOrGreater,
  String? nameLessThan,
}) => {
  'userId': ?userId,
  'parentId': ?parentId,
  if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
  'limit': ?limit,
  if (sortBy.isNotEmpty) ...{
    'sortBy': sortBy,
    'sortOrder': descending ? 'Descending' : 'Ascending',
  },
  if (fields.isNotEmpty) 'fields': fields,
  if (filters.isNotEmpty) 'filters': filters,
  if (includeItemTypes.isNotEmpty) 'includeItemTypes': includeItemTypes,
  if (excludeItemTypes.isNotEmpty) 'excludeItemTypes': excludeItemTypes,
  'isFavorite': ?isFavorite,
  'imageTypeLimit': ?imageTypeLimit,
  if (enableImageTypes.isNotEmpty) 'enableImageTypes': enableImageTypes,
  'nameStartsWith': ?nameStartsWith,
  'nameStartsWithOrGreater': ?nameStartsWithOrGreater,
  'nameLessThan': ?nameLessThan,
};
