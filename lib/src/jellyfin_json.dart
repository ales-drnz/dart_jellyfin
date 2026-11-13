// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Lenient readers for the JSON Jellyfin sends, shared by every model. Not
/// exported.
///
/// Each takes whatever arrived and answers `null` (or an empty list or
/// map) for anything it cannot read, so one odd field never fails a whole
/// page.
library;

/// A string, or the [Object.toString] of a number or a boolean. A JSON
/// object or array is not a string: `null`.
String? asString(Object? v) => switch (v) {
  null || Map() || Iterable() => null,
  _ => '$v',
};

/// A boolean; `null` for anything else.
bool? asBool(Object? v) => v is bool ? v : null;

/// An int, from an int, a double (truncated) or a numeric string.
int? asInt(Object? v) => switch (v) {
  int() => v,
  double() => v.toInt(),
  String() => int.tryParse(v),
  _ => null,
};

/// A double, from a double, an int or a numeric string.
double? asDouble(Object? v) => switch (v) {
  double() => v,
  int() => v.toDouble(),
  String() => double.tryParse(v),
  _ => null,
};

/// An ISO-8601 timestamp, in UTC. `0001-01-01T00:00:00Z` — what .NET
/// sends for a date that was never set (`DateTime.MinValue`) — is `null`.
DateTime? asUtcDateTime(Object? v) {
  final parsed = v is String ? DateTime.tryParse(v)?.toUtc() : null;
  return parsed == null || parsed.year <= 1 ? null : parsed;
}

/// A length or position in ticks (100 ns each) as a [Duration].
Duration? asTicksDuration(int? ticks) =>
    ticks == null ? null : Duration(microseconds: ticks ~/ 10);

/// A JSON object, or an empty map for anything else.
Map<String, Object?> asObject(Object? v) =>
    v is Map<String, Object?> ? v : const <String, Object?>{};

/// The strings of a JSON array; anything else in it is skipped.
List<String> asStringList(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is String) e,
];

/// The objects of a JSON array, each read by [parser]; anything else in it
/// is skipped.
List<T> asObjectList<T>(Object? v, T Function(Map<String, Object?>) parser) => [
  if (v is List)
    for (final e in v)
      if (e is Map<String, Object?>) parser(e),
];

/// The string [field] of each object of a JSON array (`Genres` as
/// `[{Name: …}]` → names).
List<String> fieldStrings(Object? v, String field) => [
  if (v is List)
    for (final e in v)
      if (e is Map<String, Object?> && e[field] is String) e[field] as String,
];

/// The string-to-string entries of a JSON object.
Map<String, String> asStringMap(Object? v) => {
  if (v is Map)
    for (final MapEntry(:key, :value) in v.entries)
      if (key is String && value is String) key: value,
};
