// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Plain immutable DTOs for the Jellyfin API.
///
/// Modelled directly on the OpenAPI spec at
/// <https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json> but
/// hand-rolled so the package stays codegen-free. Fields are added on
/// demand — [JellyfinItem.raw] keeps the full server payload around for
/// anything not yet lifted onto a typed property.
library;

import 'api/jellyfin_images_api.dart';
import 'api/jellyfin_sessions_api.dart';
import 'jellyfin_json.dart';
import 'jellyfin_vocabulary.dart';

part 'models/jellyfin_browse_models.dart';
part 'models/jellyfin_item_models.dart';
part 'models/jellyfin_lyrics_models.dart';
part 'models/jellyfin_playback_models.dart';
part 'models/jellyfin_session_models.dart';
part 'models/jellyfin_user_models.dart';

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
      items: [
        if (raw is List)
          for (final e in raw)
            if (e is Map<String, Object?>) parser(e),
      ],
      totalRecordCount:
          asInt(json['TotalRecordCount']) ?? (raw is List ? raw.length : 0),
      startIndex: asInt(json['StartIndex']),
    );
  }
}
