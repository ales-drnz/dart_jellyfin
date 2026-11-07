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

import 'jellyfin_error_type.dart';
import 'jellyfin_exception.dart';
import 'jellyfin_models.dart';

/// Parses a `{Items: [...], TotalRecordCount, StartIndex}` envelope; an
/// empty body is an empty result.
JellyfinQueryResult<T> Function(Object? json) queryResultOf<T>(
  T Function(Map<String, Object?>) parser, {
  String itemsKey = 'Items',
}) =>
    (json) => JellyfinQueryResult.fromJson(
      json == null ? const <String, Object?>{} : _map(json),
      parser,
      itemsKey: itemsKey,
    );

/// Parses a bare JSON array, skipping entries that are not objects; an
/// empty body is an empty list.
List<T> Function(Object? json) listOf<T>(
  T Function(Map<String, Object?>) parser,
) =>
    (json) => [
      for (final e in json == null ? const <Object?>[] : _list(json))
        if (e is Map<String, Object?>) parser(e),
    ];

/// Parses one JSON object, or `null` for an empty body.
T? Function(Object? json) objectOf<T>(
  T Function(Map<String, Object?>) parser,
) =>
    (json) => json == null ? null : parser(_map(json));

/// Parses one JSON object; an empty body is the model's defaults, as
/// [parser] reads `{}`.
T Function(Object? json) objectOrEmptyOf<T>(
  T Function(Map<String, Object?>) parser,
) =>
    (json) => parser(json == null ? const <String, Object?>{} : _map(json));

/// Parses one JSON object that must carry each of [keys]. An empty body,
/// or a missing, null or empty key, is a `parse` error.
T Function(Object? json) requiredObjectOf<T>(
  T Function(Map<String, Object?>) parser, {
  List<String> keys = const [],
}) => (json) {
  if (json == null) throw _parse('Expected a JSON object, got no body');
  final map = _map(json);
  for (final key in keys) {
    final value = map[key];
    if (value == null || value == '') {
      throw _parse('Expected `$key` in the answer');
    }
  }
  return parser(map);
};

// A body of the wrong shape is a malformed answer, never an empty one: an
// empty result must mean the server said "nothing".

Map<String, Object?> _map(Object json) {
  if (json is Map<String, Object?>) return json;
  throw _shape('object', json);
}

List<Object?> _list(Object json) {
  if (json is List<Object?>) return json;
  throw _shape('array', json);
}

JellyfinException _shape(String expected, Object json) =>
    _parse('Expected a JSON $expected, got ${json.runtimeType}');

JellyfinException _parse(String message) =>
    JellyfinException(message, type: JellyfinErrorType.parse);
