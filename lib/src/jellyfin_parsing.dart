// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Parsers for `JellyfinConnection.requestJson`. Not exported.
///
/// Each one returns a closure that captures only its arguments — `fromJson`
/// tear-offs and strings — so it can be sent to the isolate that decodes a
/// large response. A closure written inline in a sub-API method would be
/// just as sendable as long as it touches nothing but its own arguments;
/// these exist so that the rule has one obvious way to be followed.
library;

import 'jellyfin_models.dart';

/// Parses a `{Items: [...], TotalRecordCount, StartIndex}` envelope.
JellyfinQueryResult<T> Function(Object? json) queryResultOf<T>(
  T Function(Map<String, Object?>) parser, {
  String itemsKey = 'Items',
}) =>
    (json) => JellyfinQueryResult.fromJson(
          json is Map<String, Object?> ? json : const <String, Object?>{},
          parser,
          itemsKey: itemsKey,
        );

/// Parses a bare JSON array, skipping entries that are not objects.
List<T> Function(Object? json) listOf<T>(
  T Function(Map<String, Object?>) parser,
) =>
    (json) => [
          if (json is List)
            for (final e in json)
              if (e is Map<String, Object?>) parser(e),
        ];

/// Parses one JSON object, or `null` for an empty body.
T? Function(Object? json) objectOf<T>(
  T Function(Map<String, Object?>) parser,
) =>
    (json) => json is Map<String, Object?> ? parser(json) : null;
