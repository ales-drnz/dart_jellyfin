// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Metadata lookup and editing
// ---------------------------------------------------------------------------

/// A provider id the metadata editor offers (`ExternalIdInfo`).
final class JellyfinExternalIdInfo {
  /// The provider (`Name`), e.g. `MusicBrainz`.
  final String name;

  /// The key in an item's `ProviderIds` (`Key`), e.g. `MusicBrainzAlbum`.
  final String key;

  /// What the id names (`Type`), e.g. `Album`, `OtherArtist`; absent
  /// for some providers.
  final String? type;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds an external id info from already-parsed components.
  const JellyfinExternalIdInfo({
    required this.name,
    required this.key,
    required this.raw,
    this.type,
  });

  /// Decodes an `ExternalIdInfo`.
  factory JellyfinExternalIdInfo.fromJson(Map<String, Object?> json) =>
      JellyfinExternalIdInfo(
        name: asString(json['Name']) ?? '',
        key: asString(json['Key']) ?? '',
        type: asString(json['Type']),
        raw: json,
      );
}

/// A candidate match from a metadata provider (`RemoteSearchResult`).
///
/// Send [raw] back to `itemLookup.applySearchResult` to apply it.
final class JellyfinRemoteSearchResult {
  /// `Name`.
  final String name;

  /// `ProviderIds`, e.g. `{Tmdb: '603'}`.
  final Map<String, String> providerIds;

  /// `ProductionYear`.
  final int? productionYear;

  /// `IndexNumber`.
  final int? indexNumber;

  /// `IndexNumberEnd`.
  final int? indexNumberEnd;

  /// `ParentIndexNumber`.
  final int? parentIndexNumber;

  /// `PremiereDate`.
  final DateTime? premiereDate;

  /// `ImageUrl`.
  final String? imageUrl;

  /// `SearchProviderName`.
  final String? searchProviderName;

  /// `Overview`.
  final String? overview;

  /// `AlbumArtist`, for albums.
  final JellyfinRemoteSearchResult? albumArtist;

  /// `Artists`.
  final List<JellyfinRemoteSearchResult> artists;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a search result from already-parsed components.
  const JellyfinRemoteSearchResult({
    required this.name,
    required this.providerIds,
    required this.artists,
    required this.raw,
    this.productionYear,
    this.indexNumber,
    this.indexNumberEnd,
    this.parentIndexNumber,
    this.premiereDate,
    this.imageUrl,
    this.searchProviderName,
    this.overview,
    this.albumArtist,
  });

  /// Decodes a `RemoteSearchResult`.
  factory JellyfinRemoteSearchResult.fromJson(Map<String, Object?> json) {
    final albumArtist = json['AlbumArtist'];
    return JellyfinRemoteSearchResult(
      name: asString(json['Name']) ?? '',
      providerIds: asStringMap(json['ProviderIds']),
      productionYear: asInt(json['ProductionYear']),
      indexNumber: asInt(json['IndexNumber']),
      indexNumberEnd: asInt(json['IndexNumberEnd']),
      parentIndexNumber: asInt(json['ParentIndexNumber']),
      premiereDate: asUtcDateTime(json['PremiereDate']),
      imageUrl: asString(json['ImageUrl']),
      searchProviderName: asString(json['SearchProviderName']),
      overview: asString(json['Overview']),
      albumArtist: albumArtist is Map<String, Object?>
          ? JellyfinRemoteSearchResult.fromJson(albumArtist)
          : null,
      artists: asObjectList(
        json['Artists'],
        JellyfinRemoteSearchResult.fromJson,
      ),
      raw: json,
    );
  }
}

/// What the metadata editor needs for one item (`MetadataEditorInfo`).
final class JellyfinMetadataEditorInfo {
  /// `ParentalRatingOptions`.
  final List<JellyfinParentalRating> parentalRatingOptions;

  /// `Countries`.
  final List<JellyfinCountry> countries;

  /// `Cultures`.
  final List<JellyfinCulture> cultures;

  /// `ExternalIdInfos`.
  final List<JellyfinExternalIdInfo> externalIdInfos;

  /// The item's library content type (`ContentType`), for folders.
  final String? contentType;

  /// The content types a folder may take (`ContentTypeOptions`).
  final List<JellyfinNameValuePair> contentTypeOptions;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds editor info from already-parsed components.
  const JellyfinMetadataEditorInfo({
    required this.parentalRatingOptions,
    required this.countries,
    required this.cultures,
    required this.externalIdInfos,
    required this.contentTypeOptions,
    required this.raw,
    this.contentType,
  });

  /// Decodes a `MetadataEditorInfo`; a missing list is empty.
  factory JellyfinMetadataEditorInfo.fromJson(Map<String, Object?> json) =>
      JellyfinMetadataEditorInfo(
        parentalRatingOptions: asObjectList(
          json['ParentalRatingOptions'],
          JellyfinParentalRating.fromJson,
        ),
        countries: asObjectList(json['Countries'], JellyfinCountry.fromJson),
        cultures: asObjectList(json['Cultures'], JellyfinCulture.fromJson),
        externalIdInfos: asObjectList(
          json['ExternalIdInfos'],
          JellyfinExternalIdInfo.fromJson,
        ),
        contentType: asString(json['ContentType']),
        contentTypeOptions: asObjectList(
          json['ContentTypeOptions'],
          JellyfinNameValuePair.fromJson,
        ),
        raw: json,
      );
}

/// A candidate image from a metadata provider (`RemoteImageInfo`).
final class JellyfinRemoteImage {
  /// `ProviderName`.
  final String? providerName;

  /// The image, for `remoteImage.download` (`Url`).
  final String url;

  /// `ThumbnailUrl`.
  final String? thumbnailUrl;

  /// `Primary`, `Backdrop`, … (`Type`).
  final String? type;

  /// `Width`.
  final int? width;

  /// `Height`.
  final int? height;

  /// `CommunityRating`.
  final double? communityRating;

  /// `VoteCount`.
  final int? voteCount;

  /// `Language`.
  final String? language;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a remote image from already-parsed components.
  const JellyfinRemoteImage({
    required this.url,
    required this.raw,
    this.providerName,
    this.thumbnailUrl,
    this.type,
    this.width,
    this.height,
    this.communityRating,
    this.voteCount,
    this.language,
  });

  /// Decodes a `RemoteImageInfo`.
  factory JellyfinRemoteImage.fromJson(Map<String, Object?> json) =>
      JellyfinRemoteImage(
        providerName: asString(json['ProviderName']),
        url: asString(json['Url']) ?? '',
        thumbnailUrl: asString(json['ThumbnailUrl']),
        type: asString(json['Type']),
        width: asInt(json['Width']),
        height: asInt(json['Height']),
        communityRating: asDouble(json['CommunityRating']),
        voteCount: asInt(json['VoteCount']),
        language: asString(json['Language']),
        raw: json,
      );
}

/// A page of candidate images (`RemoteImageResult`).
final class JellyfinRemoteImageResult {
  /// `Images`.
  final List<JellyfinRemoteImage> images;

  /// Every match on the server (`TotalRecordCount`).
  final int totalRecordCount;

  /// The providers asked (`Providers`).
  final List<String> providers;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a result from already-parsed components.
  const JellyfinRemoteImageResult({
    required this.images,
    required this.totalRecordCount,
    required this.providers,
    required this.raw,
  });

  /// Decodes a `RemoteImageResult`.
  factory JellyfinRemoteImageResult.fromJson(Map<String, Object?> json) {
    final images = asObjectList(json['Images'], JellyfinRemoteImage.fromJson);
    return JellyfinRemoteImageResult(
      images: images,
      totalRecordCount: asInt(json['TotalRecordCount']) ?? images.length,
      providers: asStringList(json['Providers']),
      raw: json,
    );
  }
}

/// A provider of remote images (`ImageProviderInfo`).
final class JellyfinImageProviderInfo {
  /// `Name`.
  final String name;

  /// The image types it supplies (`SupportedImages`).
  final List<String> supportedImages;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a provider from already-parsed components.
  const JellyfinImageProviderInfo({
    required this.name,
    required this.supportedImages,
    required this.raw,
  });

  /// Decodes an `ImageProviderInfo`.
  factory JellyfinImageProviderInfo.fromJson(Map<String, Object?> json) =>
      JellyfinImageProviderInfo(
        name: asString(json['Name']) ?? '',
        supportedImages: asStringList(json['SupportedImages']),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Remote subtitles
// ---------------------------------------------------------------------------

/// A subtitle a provider offers (`RemoteSubtitleInfo`).
final class JellyfinRemoteSubtitle {
  /// `Id`, for `subtitles.downloadRemote`.
  final String id;

  /// `Name`.
  final String? name;

  /// `ProviderName`.
  final String? providerName;

  /// `ThreeLetterISOLanguageName`.
  final String? language;

  /// `srt`, `ass`, … (`Format`).
  final String? format;

  /// `Author`.
  final String? author;

  /// `Comment`.
  final String? comment;

  /// `DateCreated`.
  final DateTime? dateCreated;

  /// `CommunityRating`.
  final double? communityRating;

  /// `FrameRate`.
  final double? frameRate;

  /// `DownloadCount`.
  final int? downloadCount;

  /// Matched by file hash (`IsHashMatch`).
  final bool isHashMatch;

  /// `Forced`.
  final bool forced;

  /// `HearingImpaired`.
  final bool hearingImpaired;

  /// `AiTranslated`.
  final bool aiTranslated;

  /// `MachineTranslated`.
  final bool machineTranslated;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a remote subtitle from already-parsed components.
  const JellyfinRemoteSubtitle({
    required this.id,
    required this.isHashMatch,
    required this.forced,
    required this.hearingImpaired,
    required this.aiTranslated,
    required this.machineTranslated,
    required this.raw,
    this.name,
    this.providerName,
    this.language,
    this.format,
    this.author,
    this.comment,
    this.dateCreated,
    this.communityRating,
    this.frameRate,
    this.downloadCount,
  });

  /// Decodes a `RemoteSubtitleInfo`.
  factory JellyfinRemoteSubtitle.fromJson(Map<String, Object?> json) =>
      JellyfinRemoteSubtitle(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        providerName: asString(json['ProviderName']),
        language: asString(json['ThreeLetterISOLanguageName']),
        format: asString(json['Format']),
        author: asString(json['Author']),
        comment: asString(json['Comment']),
        dateCreated: asUtcDateTime(json['DateCreated']),
        communityRating: asDouble(json['CommunityRating']),
        frameRate: asDouble(json['FrameRate']),
        downloadCount: asInt(json['DownloadCount']),
        isHashMatch: json['IsHashMatch'] == true,
        forced: json['Forced'] == true,
        hearingImpaired: json['HearingImpaired'] == true,
        aiTranslated: json['AiTranslated'] == true,
        machineTranslated: json['MachineTranslated'] == true,
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Libraries
// ---------------------------------------------------------------------------

/// The theme media of an item (`AllThemeMediaResult`).
final class JellyfinThemeMedia {
  /// `ThemeVideosResult`.
  final JellyfinQueryResult<JellyfinItem> themeVideos;

  /// `ThemeSongsResult`.
  final JellyfinQueryResult<JellyfinItem> themeSongs;

  /// `SoundtrackSongsResult`.
  final JellyfinQueryResult<JellyfinItem> soundtrackSongs;

  /// The decoded body. Each result also carries an `OwnerId`.
  final Map<String, Object?> raw;

  /// Builds theme media from already-parsed components.
  const JellyfinThemeMedia({
    required this.themeVideos,
    required this.themeSongs,
    required this.soundtrackSongs,
    required this.raw,
  });

  /// Decodes an `AllThemeMediaResult`; a missing result is empty.
  factory JellyfinThemeMedia.fromJson(Map<String, Object?> json) {
    JellyfinQueryResult<JellyfinItem> page(String key) =>
        JellyfinQueryResult.fromJson(
          asObject(json[key]),
          JellyfinItem.fromJson,
        );
    return JellyfinThemeMedia(
      themeVideos: page('ThemeVideosResult'),
      themeSongs: page('ThemeSongsResult'),
      soundtrackSongs: page('SoundtrackSongsResult'),
      raw: json,
    );
  }
}

/// A saver, reader or fetcher a library can use (`LibraryOptionInfoDto`).
final class JellyfinLibraryOptionInfo {
  /// `Name`.
  final String name;

  /// On by default for a new library (`DefaultEnabled`).
  final bool defaultEnabled;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds an option from already-parsed components.
  const JellyfinLibraryOptionInfo({
    required this.name,
    required this.defaultEnabled,
    required this.raw,
  });

  /// Decodes a `LibraryOptionInfoDto`.
  factory JellyfinLibraryOptionInfo.fromJson(Map<String, Object?> json) =>
      JellyfinLibraryOptionInfo(
        name: asString(json['Name']) ?? '',
        defaultEnabled: json['DefaultEnabled'] == true,
        raw: json,
      );
}

/// The fetchers and image types of one item kind
/// (`LibraryTypeOptionsDto`).
final class JellyfinLibraryTypeOptions {
  /// The item kind (`Type`), e.g. `Series`.
  final String type;

  /// `MetadataFetchers`.
  final List<JellyfinLibraryOptionInfo> metadataFetchers;

  /// `ImageFetchers`.
  final List<JellyfinLibraryOptionInfo> imageFetchers;

  /// `SimilarItemProviders`.
  final List<JellyfinLibraryOptionInfo> similarItemProviders;

  /// `SupportedImageTypes`.
  final List<String> supportedImageTypes;

  /// The decoded body; `DefaultImageOptions` is there.
  final Map<String, Object?> raw;

  /// Builds type options from already-parsed components.
  const JellyfinLibraryTypeOptions({
    required this.type,
    required this.metadataFetchers,
    required this.imageFetchers,
    required this.similarItemProviders,
    required this.supportedImageTypes,
    required this.raw,
  });

  /// Decodes a `LibraryTypeOptionsDto`.
  factory JellyfinLibraryTypeOptions.fromJson(Map<String, Object?> json) =>
      JellyfinLibraryTypeOptions(
        type: asString(json['Type']) ?? '',
        metadataFetchers: asObjectList(
          json['MetadataFetchers'],
          JellyfinLibraryOptionInfo.fromJson,
        ),
        imageFetchers: asObjectList(
          json['ImageFetchers'],
          JellyfinLibraryOptionInfo.fromJson,
        ),
        similarItemProviders: asObjectList(
          json['SimilarItemProviders'],
          JellyfinLibraryOptionInfo.fromJson,
        ),
        supportedImageTypes: asStringList(json['SupportedImageTypes']),
        raw: json,
      );
}

/// What a library can be set up with (`LibraryOptionsResultDto`).
final class JellyfinLibraryAvailableOptions {
  /// `MetadataSavers`.
  final List<JellyfinLibraryOptionInfo> metadataSavers;

  /// `MetadataReaders`.
  final List<JellyfinLibraryOptionInfo> metadataReaders;

  /// `SubtitleFetchers`.
  final List<JellyfinLibraryOptionInfo> subtitleFetchers;

  /// `LyricFetchers`.
  final List<JellyfinLibraryOptionInfo> lyricFetchers;

  /// `MediaSegmentProviders`.
  final List<JellyfinLibraryOptionInfo> mediaSegmentProviders;

  /// Per item kind (`TypeOptions`).
  final List<JellyfinLibraryTypeOptions> typeOptions;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the options from already-parsed components.
  const JellyfinLibraryAvailableOptions({
    required this.metadataSavers,
    required this.metadataReaders,
    required this.subtitleFetchers,
    required this.lyricFetchers,
    required this.mediaSegmentProviders,
    required this.typeOptions,
    required this.raw,
  });

  /// Decodes a `LibraryOptionsResultDto`; a missing list is empty.
  factory JellyfinLibraryAvailableOptions.fromJson(Map<String, Object?> json) {
    List<JellyfinLibraryOptionInfo> infos(String key) =>
        asObjectList(json[key], JellyfinLibraryOptionInfo.fromJson);
    return JellyfinLibraryAvailableOptions(
      metadataSavers: infos('MetadataSavers'),
      metadataReaders: infos('MetadataReaders'),
      subtitleFetchers: infos('SubtitleFetchers'),
      lyricFetchers: infos('LyricFetchers'),
      mediaSegmentProviders: infos('MediaSegmentProviders'),
      typeOptions: asObjectList(
        json['TypeOptions'],
        JellyfinLibraryTypeOptions.fromJson,
      ),
      raw: json,
    );
  }
}

/// A library as the admin configured it (`VirtualFolderInfo`).
final class JellyfinVirtualFolder {
  /// `Name`, for the `libraryStructure` calls.
  final String name;

  /// The folders it reads (`Locations`).
  final List<String> locations;

  /// `music`, `movies`, `tvshows`, … (`CollectionType`).
  final String? collectionType;

  /// The library item (`ItemId`), the id `items.list(parentId:)` takes.
  final String? itemId;

  /// `PrimaryImageItemId`.
  final String? primaryImageItemId;

  /// Scan progress 0–100 while scanning (`RefreshProgress`).
  final double? refreshProgress;

  /// `RefreshStatus`, e.g. `Idle`.
  final String? refreshStatus;

  /// `LibraryOptions`, left as a map: dozens of settings, sent back
  /// whole to `libraryStructure.updateLibraryOptions`.
  final Map<String, Object?> libraryOptions;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a virtual folder from already-parsed components.
  const JellyfinVirtualFolder({
    required this.name,
    required this.locations,
    required this.libraryOptions,
    required this.raw,
    this.collectionType,
    this.itemId,
    this.primaryImageItemId,
    this.refreshProgress,
    this.refreshStatus,
  });

  /// Decodes a `VirtualFolderInfo`.
  factory JellyfinVirtualFolder.fromJson(Map<String, Object?> json) =>
      JellyfinVirtualFolder(
        name: asString(json['Name']) ?? '',
        locations: asStringList(json['Locations']),
        collectionType: asString(json['CollectionType']),
        itemId: asString(json['ItemId']),
        primaryImageItemId: asString(json['PrimaryImageItemId']),
        refreshProgress: asDouble(json['RefreshProgress']),
        refreshStatus: asString(json['RefreshStatus']),
        libraryOptions: asObject(json['LibraryOptions']),
        raw: json,
      );
}
