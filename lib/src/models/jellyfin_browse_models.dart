// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

library;

import '../jellyfin_json.dart';
import 'jellyfin_item_models.dart';

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

  /// A copy with the given fields replaced, to change one setting and send
  /// the rest back as it came. A field cannot be set to `null` this way.
  JellyfinDisplayPreferences copyWith({
    String? id,
    String? client,
    String? viewType,
    String? sortBy,
    String? sortOrder,
    String? indexBy,
    String? scrollDirection,
    bool? rememberIndexing,
    bool? rememberSorting,
    bool? showBackdrop,
    bool? showSidebar,
    int? primaryImageHeight,
    int? primaryImageWidth,
    Map<String, String>? customPrefs,
  }) => JellyfinDisplayPreferences(
    id: id ?? this.id,
    client: client ?? this.client,
    viewType: viewType ?? this.viewType,
    sortBy: sortBy ?? this.sortBy,
    sortOrder: sortOrder ?? this.sortOrder,
    indexBy: indexBy ?? this.indexBy,
    scrollDirection: scrollDirection ?? this.scrollDirection,
    rememberIndexing: rememberIndexing ?? this.rememberIndexing,
    rememberSorting: rememberSorting ?? this.rememberSorting,
    showBackdrop: showBackdrop ?? this.showBackdrop,
    showSidebar: showSidebar ?? this.showSidebar,
    primaryImageHeight: primaryImageHeight ?? this.primaryImageHeight,
    primaryImageWidth: primaryImageWidth ?? this.primaryImageWidth,
    customPrefs: customPrefs ?? this.customPrefs,
    raw: raw,
  );

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
      showBackdrop: json['ShowBackdrop'] is bool
          ? json['ShowBackdrop'] as bool
          : null,
      showSidebar: json['ShowSidebar'] is bool
          ? json['ShowSidebar'] as bool
          : null,
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
    if (primaryImageHeight != null) 'PrimaryImageHeight': primaryImageHeight,
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

/// One match from `/Search/Hints` — a lightweight pointer into the library.
final class JellyfinSearchHint {
  /// Id of the matched item.
  final String itemId;

  /// Display name of the matched item.
  final String? name;

  /// Substring of the query that triggered the match, when reported.
  final String? matchedTerm;

  /// `BaseItemKind` of the matched item.
  final String? type;

  /// `MediaType` of the matched item.
  final String? mediaType;

  /// Album-artist string, for audio hits.
  final String? albumArtist;

  /// Album title, for audio hits.
  final String? album;

  /// Id of the owning album, for audio hits.
  final String? albumId;

  /// All artist names, for audio hits.
  final List<String> artists;

  /// Duration in ticks (10_000 per millisecond).
  final int? runTimeTicks;

  /// Track/episode number within the parent, when applicable.
  final int? indexNumber;

  /// Disc/season number (parent index) within the parent, when applicable.
  final int? parentIndexNumber;

  /// Release year, when applicable.
  final int? productionYear;

  /// Image tag for the `Primary` image.
  final String? primaryImageTag;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a search hint from already-parsed components.
  const JellyfinSearchHint({
    required this.itemId,
    required this.artists,
    required this.raw,
    this.name,
    this.matchedTerm,
    this.type,
    this.mediaType,
    this.albumArtist,
    this.album,
    this.albumId,
    this.runTimeTicks,
    this.indexNumber,
    this.parentIndexNumber,
    this.productionYear,
    this.primaryImageTag,
  });

  /// Decodes a search-hint entry; accepts both `Id` and legacy `ItemId` keys.
  factory JellyfinSearchHint.fromJson(Map<String, Object?> json) =>
      JellyfinSearchHint(
        itemId: asString(json['Id']) ?? asString(json['ItemId']) ?? '',
        name: asString(json['Name']),
        matchedTerm: asString(json['MatchedTerm']),
        type: asString(json['Type']),
        mediaType: asString(json['MediaType']),
        albumArtist: asString(json['AlbumArtist']),
        album: asString(json['Album']),
        albumId: asString(json['AlbumId']),
        artists: asStringList(json['Artists']),
        runTimeTicks: asInt(json['RunTimeTicks']),
        indexNumber: asInt(json['IndexNumber']),
        parentIndexNumber: asInt(json['ParentIndexNumber']),
        productionYear: asInt(json['ProductionYear']),
        primaryImageTag: asString(json['PrimaryImageTag']),
        raw: json,
      );
}

/// Jellyfin's "library" abstraction — what `/UserViews` returns.
///
/// `collectionType` is what tells you the library kind:
/// `'movies' | 'tvshows' | 'music' | 'musicvideos' | 'photos' | 'books' |
///  'livetv' | 'homevideos' | 'boxsets' | 'playlists' | 'folders' | null`.
final class JellyfinView {
  /// Stable server-side library id.
  final String id;

  /// Library display name.
  final String name;

  /// Library kind (`'music'`, `'movies'`, …); see class doc for full set.
  final String? collectionType;

  /// Image tag for the library's `Primary` poster.
  final String? primaryImageTag;

  /// Id of the server this library lives on.
  final String? serverId;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a view from already-parsed components.
  const JellyfinView({
    required this.id,
    required this.name,
    required this.raw,
    this.collectionType,
    this.primaryImageTag,
    this.serverId,
  });

  /// Decodes a `/UserViews` entry, flattening `ImageTags.Primary` for convenience.
  factory JellyfinView.fromJson(Map<String, Object?> json) {
    final tags = json['ImageTags'];
    return JellyfinView(
      id: asString(json['Id']) ?? '',
      name: asString(json['Name']) ?? '',
      collectionType: asString(json['CollectionType']),
      primaryImageTag: tags is Map ? asString(tags['Primary']) : null,
      serverId: asString(json['ServerId']),
      raw: json,
    );
  }

  /// `true` when this view holds music.
  bool get isMusic => collectionType == 'music';

  /// `true` when this view holds movies.
  bool get isMovies => collectionType == 'movies';

  /// `true` when this view holds TV shows.
  bool get isTvShows => collectionType == 'tvshows';

  /// `true` when this view holds photos.
  bool get isPhotos => collectionType == 'photos';
}

/// How many items of each kind a user can see (`/Items/Counts`).
final class JellyfinItemCounts {
  /// Tracks (`SongCount`).
  final int songCount;

  /// Albums (`AlbumCount`).
  final int albumCount;

  /// Artists (`ArtistCount`).
  final int artistCount;

  /// Music videos (`MusicVideoCount`).
  final int musicVideoCount;

  /// Movies (`MovieCount`).
  final int movieCount;

  /// Series (`SeriesCount`).
  final int seriesCount;

  /// Episodes (`EpisodeCount`).
  final int episodeCount;

  /// Collections (`BoxSetCount`).
  final int boxSetCount;

  /// Books (`BookCount`).
  final int bookCount;

  /// Audiobooks (`AudioBookCount`). Jellyfin 13.0 sends it; `null` from
  /// 12.x, which counts audiobooks nowhere on their own.
  final int? audioBookCount;

  /// Trailers (`TrailerCount`).
  final int trailerCount;

  /// Live TV programs (`ProgramCount`).
  final int programCount;

  /// Every item (`ItemCount`).
  final int itemCount;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds item counts from already-parsed components.
  const JellyfinItemCounts({
    required this.songCount,
    required this.albumCount,
    required this.artistCount,
    required this.musicVideoCount,
    required this.movieCount,
    required this.seriesCount,
    required this.episodeCount,
    required this.boxSetCount,
    required this.bookCount,
    required this.itemCount,
    required this.raw,
    this.audioBookCount,
    this.trailerCount = 0,
    this.programCount = 0,
  });

  /// Decodes an `ItemCounts` body; a missing count is 0.
  factory JellyfinItemCounts.fromJson(Map<String, Object?> json) =>
      JellyfinItemCounts(
        songCount: asInt(json['SongCount']) ?? 0,
        albumCount: asInt(json['AlbumCount']) ?? 0,
        artistCount: asInt(json['ArtistCount']) ?? 0,
        musicVideoCount: asInt(json['MusicVideoCount']) ?? 0,
        movieCount: asInt(json['MovieCount']) ?? 0,
        seriesCount: asInt(json['SeriesCount']) ?? 0,
        episodeCount: asInt(json['EpisodeCount']) ?? 0,
        boxSetCount: asInt(json['BoxSetCount']) ?? 0,
        bookCount: asInt(json['BookCount']) ?? 0,
        audioBookCount: asInt(json['AudioBookCount']),
        trailerCount: asInt(json['TrailerCount']) ?? 0,
        programCount: asInt(json['ProgramCount']) ?? 0,
        itemCount: asInt(json['ItemCount']) ?? 0,
        raw: json,
      );
}

/// A user's access to a shared playlist (`PlaylistUserPermissions`).
final class JellyfinPlaylistUserPermission {
  /// The user.
  final String userId;

  /// Whether the user may edit the playlist.
  final bool canEdit;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a permission from already-parsed components.
  const JellyfinPlaylistUserPermission({
    required this.userId,
    required this.canEdit,
    required this.raw,
  });

  /// Decodes `{UserId, CanEdit}`.
  factory JellyfinPlaylistUserPermission.fromJson(Map<String, Object?> json) =>
      JellyfinPlaylistUserPermission(
        userId: asString(json['UserId']) ?? '',
        canEdit: json['CanEdit'] == true,
        raw: json,
      );
}
