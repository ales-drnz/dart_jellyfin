// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The paged answer of the list routes.
library;

import '../jellyfin_json.dart';

// ---------------------------------------------------------------------------
// QueryResult — the standard `{Items, TotalRecordCount, StartIndex}` envelope
// ---------------------------------------------------------------------------

/// Paged `{Items, TotalRecordCount, StartIndex}` envelope returned by most
/// Jellyfin list endpoints.
final class JellyfinQueryResult<T> {
  /// Parsed page of items.
  final List<T> items;

  /// Total matches across all pages on the server (not the size of [items]).
  final int totalRecordCount;

  /// Offset of this page within the full result set, when the server reports it.
  final int? startIndex;

  /// Builds an envelope from already-parsed components.
  const JellyfinQueryResult({
    required this.items,
    required this.totalRecordCount,
    this.startIndex,
  });

  @override
  String toString() =>
      'JellyfinQueryResult<$T>(${items.length} of $totalRecordCount)';

  /// Decodes the envelope, mapping each entry under [itemsKey] through [parser].
  ///
  /// [itemsKey] defaults to `'Items'`; pass a different key for endpoints that
  /// nest the list elsewhere (e.g. `'SearchHints'`).
  factory JellyfinQueryResult.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?>) parser, {
    String itemsKey = 'Items',
  }) {
    final raw = json[itemsKey];
    return JellyfinQueryResult<T>(
      items: asObjectList(raw, parser),
      totalRecordCount:
          asInt(json['TotalRecordCount']) ?? (raw is List ? raw.length : 0),
      startIndex: asInt(json['StartIndex']),
    );
  }
}
