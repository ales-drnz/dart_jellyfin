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

/// A string, or the [Object.toString] of anything else.
String? asString(Object? v) => v == null ? null : '$v';

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

/// An ISO-8601 timestamp, in UTC.
DateTime? asUtcDateTime(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;

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
          if (e is Map<String, Object?> && e[field] is String)
            e[field] as String,
    ];

/// The string-to-string entries of a JSON object.
Map<String, String> asStringMap(Object? v) => {
      if (v is Map)
        for (final MapEntry(:key, :value) in v.entries)
          if (key is String && value is String) key: value,
    };
