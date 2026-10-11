// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Display preferences (`/DisplayPreferences/{id}`)
// ---------------------------------------------------------------------------

/// Per-client UI state stored on the server: view type, sort, scroll
/// direction, sidebar visibility, plus a free-form `customPrefs` map.
final class JellyfinDisplayPreferences {
  /// Display-preferences id; usually the view/library id.
  final String? id;

  /// Client identifier that owns these preferences.
  final String? client;

  /// View layout (`'Poster'`, `'List'`, …).
  final String? viewType;

  /// Sort key (`'SortName'`, `'DateCreated'`, …).
  final String? sortBy;

  /// `'Ascending'` or `'Descending'`.
  final String? sortOrder;

  /// Indexing key for grouped views.
  final String? indexBy;

  /// `'Horizontal'` or `'Vertical'`.
  final String? scrollDirection;

  /// Whether the client should reuse the saved indexing across sessions.
  final bool? rememberIndexing;

  /// Whether the client should reuse the saved sort across sessions.
  final bool? rememberSorting;

  /// Whether to draw the item backdrop behind the view.
  final bool? showBackdrop;

  /// Whether to show the sidebar in this view.
  final bool? showSidebar;

  /// Primary-image render height in pixels.
  final int? primaryImageHeight;

  /// Primary-image render width in pixels.
  final int? primaryImageWidth;

  /// Free-form per-client key/value preferences.
  final Map<String, String> customPrefs;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a display-preferences DTO from already-parsed components.
  const JellyfinDisplayPreferences({
    this.id,
    this.client,
    this.viewType,
    this.sortBy,
    this.sortOrder,
    this.indexBy,
    this.scrollDirection,
    this.rememberIndexing,
    this.rememberSorting,
    this.showBackdrop,
    this.showSidebar,
    this.primaryImageHeight,
    this.primaryImageWidth,
    this.customPrefs = const {},
    this.raw = const {},
  });

  /// Decodes a `/DisplayPreferences/{id}` payload.
  factory JellyfinDisplayPreferences.fromJson(Map<String, Object?> json) {
    final cp = json['CustomPrefs'];
    return JellyfinDisplayPreferences(
      id: asString(json['Id']),
      client: asString(json['Client']),
      viewType: asString(json['ViewType']),
      sortBy: asString(json['SortBy']),
      sortOrder: asString(json['SortOrder']),
      indexBy: asString(json['IndexBy']),
      scrollDirection: asString(json['ScrollDirection']),
      rememberIndexing: json['RememberIndexing'] is bool
          ? json['RememberIndexing'] as bool
          : null,
      rememberSorting: json['RememberSorting'] is bool
          ? json['RememberSorting'] as bool
          : null,
      showBackdrop:
          json['ShowBackdrop'] is bool ? json['ShowBackdrop'] as bool : null,
      showSidebar:
          json['ShowSidebar'] is bool ? json['ShowSidebar'] as bool : null,
      primaryImageHeight: asInt(json['PrimaryImageHeight']),
      primaryImageWidth: asInt(json['PrimaryImageWidth']),
      customPrefs: cp is Map ? asStringMap(cp) : const {},
      raw: json,
    );
  }

  /// JSON shape accepted by `POST /DisplayPreferences/{id}`.
  Map<String, Object?> toJson() => <String, Object?>{
        if (id != null) 'Id': id,
        if (client != null) 'Client': client,
        if (viewType != null) 'ViewType': viewType,
        if (sortBy != null) 'SortBy': sortBy,
        if (sortOrder != null) 'SortOrder': sortOrder,
        if (indexBy != null) 'IndexBy': indexBy,
        if (scrollDirection != null) 'ScrollDirection': scrollDirection,
        if (rememberIndexing != null) 'RememberIndexing': rememberIndexing,
        if (rememberSorting != null) 'RememberSorting': rememberSorting,
        if (showBackdrop != null) 'ShowBackdrop': showBackdrop,
        if (showSidebar != null) 'ShowSidebar': showSidebar,
        if (primaryImageHeight != null)
          'PrimaryImageHeight': primaryImageHeight,
        if (primaryImageWidth != null) 'PrimaryImageWidth': primaryImageWidth,
        if (customPrefs.isNotEmpty) 'CustomPrefs': customPrefs,
      };
}

// ---------------------------------------------------------------------------
// Query filters (`/Items/Filters` and `/Items/Filters2`)
// ---------------------------------------------------------------------------

/// `{Name, Id}` pair used in faceted filter responses.
final class JellyfinNameGuidPair {
  /// Display name.
  final String? name;

  /// Stable server-side id.
  final String? id;

  /// Builds a name/id pair from already-parsed components.
  const JellyfinNameGuidPair({this.name, this.id});

  /// Decodes a `{Name, Id}` entry.
  factory JellyfinNameGuidPair.fromJson(Map<String, Object?> json) =>
      JellyfinNameGuidPair(
        name: asString(json['Name']),
        id: asString(json['Id']),
      );
}

/// Modern facet response from `/Items/Filters2` — genres carry ids so
/// the client can filter back through `items.list(genreIds: …)`.
final class JellyfinQueryFilters {
  /// Genres available in the queried scope, each with a filterable id.
  final List<JellyfinNameGuidPair> genres;

  /// Tag strings available in the queried scope.
  final List<String> tags;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a filters facet from already-parsed components.
  const JellyfinQueryFilters({
    this.genres = const [],
    this.tags = const [],
    this.raw = const {},
  });

  /// Decodes a `/Items/Filters2` response.
  factory JellyfinQueryFilters.fromJson(Map<String, Object?> json) =>
      JellyfinQueryFilters(
        genres: asObjectList(json['Genres'], JellyfinNameGuidPair.fromJson),
        tags: asStringList(json['Tags']),
        raw: json,
      );
}

/// Legacy facet response from `/Items/Filters` — flat string arrays.
final class JellyfinQueryFiltersLegacy {
  /// Genre names available in the queried scope.
  final List<String> genres;

  /// Tag strings available in the queried scope.
  final List<String> tags;

  /// Distinct official ratings (`'PG-13'`, `'TV-MA'`, …) in scope.
  final List<String> officialRatings;

  /// Distinct release years in scope.
  final List<int> years;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a legacy filters facet from already-parsed components.
  const JellyfinQueryFiltersLegacy({
    this.genres = const [],
    this.tags = const [],
    this.officialRatings = const [],
    this.years = const [],
    this.raw = const {},
  });

  /// Decodes a `/Items/Filters` response.
  factory JellyfinQueryFiltersLegacy.fromJson(Map<String, Object?> json) {
    final rawYears = json['Years'];
    return JellyfinQueryFiltersLegacy(
      genres: asStringList(json['Genres']),
      tags: asStringList(json['Tags']),
      officialRatings: asStringList(json['OfficialRatings']),
      years: [
        if (rawYears is List)
          for (final e in rawYears)
            if (asInt(e) != null) asInt(e)!,
      ],
      raw: json,
    );
  }
}

// ---------------------------------------------------------------------------
// Movie recommendations (`/Movies/Recommendations`)
// ---------------------------------------------------------------------------

/// One recommendation bucket from `/Movies/Recommendations`.
final class JellyfinMovieRecommendation {
  /// Bucket id (e.g. the seed item or person id).
  final String? categoryId;

  /// Name of the seed item used to build this bucket.
  final String? baselineItemName;

  /// `'SimilarToRecentlyPlayed' | 'SimilarToLikedItem' | 'HasDirectorFromRecentlyPlayed' | 'HasActorFromRecentlyPlayed' | 'HasLikedDirector' | 'HasLikedActor'`.
  final String? recommendationType;

  /// Recommended items in this bucket.
  final List<JellyfinItem> items;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a recommendation bucket from already-parsed components.
  const JellyfinMovieRecommendation({
    this.categoryId,
    this.baselineItemName,
    this.recommendationType,
    this.items = const [],
    this.raw = const {},
  });

  /// Decodes a recommendation entry, recursing into each `Items` element.
  factory JellyfinMovieRecommendation.fromJson(Map<String, Object?> json) =>
      JellyfinMovieRecommendation(
        categoryId: asString(json['CategoryId']),
        baselineItemName: asString(json['BaselineItemName']),
        recommendationType: asString(json['RecommendationType']),
        items: asObjectList(json['Items'], JellyfinItem.fromJson),
        raw: json,
      );
}
