// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Typed answers of the admin, metadata, live TV and account endpoints.
///
/// Every model keeps the decoded body in `raw`, so a field not lifted here
/// is still one map lookup away. Field names follow the Jellyfin 12.4 API
/// document; the shapes of the admin answers were checked against a 12.4
/// server.
library;

import 'jellyfin_json.dart';
import 'jellyfin_models.dart';

Map<String, Object?> _object(Object? v) =>
    v is Map<String, Object?> ? v : const <String, Object?>{};

// ---------------------------------------------------------------------------
// Shared small shapes
// ---------------------------------------------------------------------------

/// A `{Name, Id}` pair (`NameIdPair`, `SpecialViewOptionDto`): tuner host
/// types, lineups, auth providers, view grouping options.
final class JellyfinNameIdPair {
  /// `Name`.
  final String name;

  /// `Id`.
  final String id;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a pair from already-parsed components.
  const JellyfinNameIdPair({
    required this.name,
    required this.id,
    required this.raw,
  });

  /// Decodes `{Name, Id}`; a missing value is `''`.
  factory JellyfinNameIdPair.fromJson(Map<String, Object?> json) =>
      JellyfinNameIdPair(
        name: asString(json['Name']) ?? '',
        id: asString(json['Id']) ?? '',
        raw: json,
      );
}

/// A `{Name, Value}` pair (`NameValuePair`, `LocalizationOption`).
final class JellyfinNameValuePair {
  /// `Name`.
  final String name;

  /// `Value`.
  final String? value;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a pair from already-parsed components.
  const JellyfinNameValuePair({
    required this.name,
    required this.raw,
    this.value,
  });

  /// Decodes `{Name, Value}`.
  factory JellyfinNameValuePair.fromJson(Map<String, Object?> json) =>
      JellyfinNameValuePair(
        name: asString(json['Name']) ?? '',
        value: asString(json['Value']),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// API keys, backups, configuration
// ---------------------------------------------------------------------------

/// A long-lived API key (`AuthenticationInfo`; `AuthenticationInfoDto` in
/// Jellyfin 13.0, same fields).
final class JellyfinApiKey {
  /// The key itself (`AccessToken`), for `apiKey.revoke`.
  final String accessToken;

  /// The application it was issued to (`AppName`).
  final String? appName;

  /// `AppVersion`.
  final String? appVersion;

  /// `DeviceId`.
  final String? deviceId;

  /// `DeviceName`.
  final String? deviceName;

  /// `UserId`, for a key tied to a user.
  final String? userId;

  /// `UserName`.
  final String? userName;

  /// `IsActive`.
  final bool isActive;

  /// `DateCreated`.
  final DateTime? dateCreated;

  /// `DateRevoked`.
  final DateTime? dateRevoked;

  /// `DateLastActivity`.
  final DateTime? dateLastActivity;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds an API key from already-parsed components.
  const JellyfinApiKey({
    required this.accessToken,
    required this.isActive,
    required this.raw,
    this.appName,
    this.appVersion,
    this.deviceId,
    this.deviceName,
    this.userId,
    this.userName,
    this.dateCreated,
    this.dateRevoked,
    this.dateLastActivity,
  });

  /// Decodes an `AuthenticationInfo`.
  factory JellyfinApiKey.fromJson(Map<String, Object?> json) => JellyfinApiKey(
    accessToken: asString(json['AccessToken']) ?? '',
    appName: asString(json['AppName']),
    appVersion: asString(json['AppVersion']),
    deviceId: asString(json['DeviceId']),
    deviceName: asString(json['DeviceName']),
    userId: asString(json['UserId']),
    userName: asString(json['UserName']),
    isActive: json['IsActive'] == true,
    dateCreated: asUtcDateTime(json['DateCreated']),
    dateRevoked: asUtcDateTime(json['DateRevoked']),
    dateLastActivity: asUtcDateTime(json['DateLastActivity']),
    raw: json,
  );
}

/// What a backup holds (`BackupOptionsDto`).
final class JellyfinBackupOptions {
  /// `Metadata`.
  final bool metadata;

  /// `Trickplay`.
  final bool trickplay;

  /// `Subtitles`.
  final bool subtitles;

  /// `Database`.
  final bool database;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds backup options from already-parsed components.
  const JellyfinBackupOptions({
    required this.metadata,
    required this.trickplay,
    required this.subtitles,
    required this.database,
    required this.raw,
  });

  /// Decodes a `BackupOptionsDto`; a missing flag is `false`.
  factory JellyfinBackupOptions.fromJson(Map<String, Object?> json) =>
      JellyfinBackupOptions(
        metadata: json['Metadata'] == true,
        trickplay: json['Trickplay'] == true,
        subtitles: json['Subtitles'] == true,
        database: json['Database'] == true,
        raw: json,
      );
}

/// One backup archive (`BackupManifestDto`).
final class JellyfinBackupManifest {
  /// The archive on the server (`Path`), for `backup.manifest` and
  /// `backup.restore`.
  final String? path;

  /// The server version that wrote it (`ServerVersion`).
  final String? serverVersion;

  /// `BackupEngineVersion`.
  final String? backupEngineVersion;

  /// `DateCreated`.
  final DateTime? dateCreated;

  /// What it holds (`Options`).
  final JellyfinBackupOptions? options;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a manifest from already-parsed components.
  const JellyfinBackupManifest({
    required this.raw,
    this.path,
    this.serverVersion,
    this.backupEngineVersion,
    this.dateCreated,
    this.options,
  });

  /// Decodes a `BackupManifestDto`.
  factory JellyfinBackupManifest.fromJson(Map<String, Object?> json) {
    final options = json['Options'];
    return JellyfinBackupManifest(
      path: asString(json['Path']),
      serverVersion: asString(json['ServerVersion']),
      backupEngineVersion: asString(json['BackupEngineVersion']),
      dateCreated: asUtcDateTime(json['DateCreated']),
      options: options is Map<String, Object?>
          ? JellyfinBackupOptions.fromJson(options)
          : null,
      raw: json,
    );
  }
}

/// The metadata savers and fetchers of one item kind (`MetadataOptions`).
final class JellyfinMetadataOptions {
  /// The item kind (`ItemType`); absent in the default template.
  final String? itemType;

  /// `DisabledMetadataSavers`.
  final List<String> disabledMetadataSavers;

  /// `LocalMetadataReaderOrder`.
  final List<String> localMetadataReaderOrder;

  /// `DisabledMetadataFetchers`.
  final List<String> disabledMetadataFetchers;

  /// `MetadataFetcherOrder`.
  final List<String> metadataFetcherOrder;

  /// `DisabledImageFetchers`.
  final List<String> disabledImageFetchers;

  /// `ImageFetcherOrder`.
  final List<String> imageFetcherOrder;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds metadata options from already-parsed components.
  const JellyfinMetadataOptions({
    required this.disabledMetadataSavers,
    required this.localMetadataReaderOrder,
    required this.disabledMetadataFetchers,
    required this.metadataFetcherOrder,
    required this.disabledImageFetchers,
    required this.imageFetcherOrder,
    required this.raw,
    this.itemType,
  });

  /// Decodes a `MetadataOptions`; a missing list is empty.
  factory JellyfinMetadataOptions.fromJson(
    Map<String, Object?> json,
  ) => JellyfinMetadataOptions(
    itemType: asString(json['ItemType']),
    disabledMetadataSavers: asStringList(json['DisabledMetadataSavers']),
    localMetadataReaderOrder: asStringList(json['LocalMetadataReaderOrder']),
    disabledMetadataFetchers: asStringList(json['DisabledMetadataFetchers']),
    metadataFetcherOrder: asStringList(json['MetadataFetcherOrder']),
    disabledImageFetchers: asStringList(json['DisabledImageFetchers']),
    imageFetcherOrder: asStringList(json['ImageFetcherOrder']),
    raw: json,
  );
}

/// A plugin repository (`RepositoryInfo`).
final class JellyfinRepository {
  /// `Name`.
  final String name;

  /// The manifest URL (`Url`).
  final String? url;

  /// `Enabled`.
  final bool enabled;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a repository from already-parsed components.
  const JellyfinRepository({
    required this.name,
    required this.enabled,
    required this.raw,
    this.url,
  });

  /// Decodes a `RepositoryInfo`.
  factory JellyfinRepository.fromJson(Map<String, Object?> json) =>
      JellyfinRepository(
        name: asString(json['Name']) ?? '',
        url: asString(json['Url']),
        enabled: json['Enabled'] == true,
        raw: json,
      );
}

/// The server configuration (`ServerConfiguration`).
///
/// Lifts the settings an app reads; the rest is in [raw]. To change a
/// setting, edit a copy of [raw] and send it to `configuration.update`.
final class JellyfinServerConfiguration {
  /// `ServerName`.
  final String? serverName;

  /// The dashboard language (`UICulture`).
  final String? uiCulture;

  /// `PreferredMetadataLanguage`.
  final String? preferredMetadataLanguage;

  /// `MetadataCountryCode`.
  final String? metadataCountryCode;

  /// `IsStartupWizardCompleted`.
  final bool isStartupWizardCompleted;

  /// `QuickConnectAvailable`.
  final bool quickConnectAvailable;

  /// `EnableLegacyAuthorization`; off by default since Jellyfin 12.
  final bool enableLegacyAuthorization;

  /// `CachePath`.
  final String? cachePath;

  /// `MetadataPath`.
  final String? metadataPath;

  /// The played percentage under which an item has no resume point
  /// (`MinResumePct`).
  final int? minResumePct;

  /// The played percentage over which an item counts as played
  /// (`MaxResumePct`).
  final int? maxResumePct;

  /// `MinResumeDurationSeconds`.
  final int? minResumeDurationSeconds;

  /// The bitrate cap for remote clients, `0` for none
  /// (`RemoteClientBitrateLimit`).
  final int? remoteClientBitrateLimit;

  /// `LogFileRetentionDays`.
  final int? logFileRetentionDays;

  /// `ActivityLogRetentionDays`.
  final int? activityLogRetentionDays;

  /// `PluginRepositories`.
  final List<JellyfinRepository> pluginRepositories;

  /// Per item kind (`MetadataOptions`).
  final List<JellyfinMetadataOptions> metadataOptions;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a configuration from already-parsed components.
  const JellyfinServerConfiguration({
    required this.isStartupWizardCompleted,
    required this.quickConnectAvailable,
    required this.enableLegacyAuthorization,
    required this.pluginRepositories,
    required this.metadataOptions,
    required this.raw,
    this.serverName,
    this.uiCulture,
    this.preferredMetadataLanguage,
    this.metadataCountryCode,
    this.cachePath,
    this.metadataPath,
    this.minResumePct,
    this.maxResumePct,
    this.minResumeDurationSeconds,
    this.remoteClientBitrateLimit,
    this.logFileRetentionDays,
    this.activityLogRetentionDays,
  });

  /// Decodes a `ServerConfiguration`.
  factory JellyfinServerConfiguration.fromJson(Map<String, Object?> json) =>
      JellyfinServerConfiguration(
        serverName: asString(json['ServerName']),
        uiCulture: asString(json['UICulture']),
        preferredMetadataLanguage: asString(json['PreferredMetadataLanguage']),
        metadataCountryCode: asString(json['MetadataCountryCode']),
        isStartupWizardCompleted: json['IsStartupWizardCompleted'] == true,
        quickConnectAvailable: json['QuickConnectAvailable'] == true,
        enableLegacyAuthorization: json['EnableLegacyAuthorization'] == true,
        cachePath: asString(json['CachePath']),
        metadataPath: asString(json['MetadataPath']),
        minResumePct: asInt(json['MinResumePct']),
        maxResumePct: asInt(json['MaxResumePct']),
        minResumeDurationSeconds: asInt(json['MinResumeDurationSeconds']),
        remoteClientBitrateLimit: asInt(json['RemoteClientBitrateLimit']),
        logFileRetentionDays: asInt(json['LogFileRetentionDays']),
        activityLogRetentionDays: asInt(json['ActivityLogRetentionDays']),
        pluginRepositories: asObjectList(
          json['PluginRepositories'],
          JellyfinRepository.fromJson,
        ),
        metadataOptions: asObjectList(
          json['MetadataOptions'],
          JellyfinMetadataOptions.fromJson,
        ),
        raw: json,
      );
}

/// The branding the admin configured (`BrandingOptionsDto`).
final class JellyfinBrandingOptions {
  /// Text shown under the login form (`LoginDisclaimer`).
  final String? loginDisclaimer;

  /// `CustomCss`.
  final String? customCss;

  /// `SplashscreenEnabled`.
  final bool splashscreenEnabled;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds branding options from already-parsed components.
  const JellyfinBrandingOptions({
    required this.splashscreenEnabled,
    required this.raw,
    this.loginDisclaimer,
    this.customCss,
  });

  /// Decodes a `BrandingOptionsDto`; the server leaves unset texts out.
  factory JellyfinBrandingOptions.fromJson(Map<String, Object?> json) =>
      JellyfinBrandingOptions(
        loginDisclaimer: asString(json['LoginDisclaimer']),
        customCss: asString(json['CustomCss']),
        splashscreenEnabled: json['SplashscreenEnabled'] == true,
        raw: json,
      );
}

/// A dashboard page a plugin registers (`ConfigurationPageInfo`).
final class JellyfinConfigurationPage {
  /// The page name, for `dashboard.configurationPage` (`Name`).
  final String name;

  /// `DisplayName`.
  final String? displayName;

  /// `EnableInMainMenu`.
  final bool enableInMainMenu;

  /// `MenuSection`.
  final String? menuSection;

  /// `MenuIcon`.
  final String? menuIcon;

  /// The plugin that owns it (`PluginId`).
  final String? pluginId;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a page from already-parsed components.
  const JellyfinConfigurationPage({
    required this.name,
    required this.enableInMainMenu,
    required this.raw,
    this.displayName,
    this.menuSection,
    this.menuIcon,
    this.pluginId,
  });

  /// Decodes a `ConfigurationPageInfo`.
  factory JellyfinConfigurationPage.fromJson(Map<String, Object?> json) =>
      JellyfinConfigurationPage(
        name: asString(json['Name']) ?? '',
        displayName: asString(json['DisplayName']),
        enableInMainMenu: json['EnableInMainMenu'] == true,
        menuSection: asString(json['MenuSection']),
        menuIcon: asString(json['MenuIcon']),
        pluginId: asString(json['PluginId']),
        raw: json,
      );
}

/// What a channel supports (`ChannelFeatures`).
final class JellyfinChannelFeatures {
  /// The channel (`Id`).
  final String id;

  /// `Name`.
  final String? name;

  /// `CanSearch`.
  final bool canSearch;

  /// `CanFilter`.
  final bool canFilter;

  /// `SupportsLatestMedia`.
  final bool supportsLatestMedia;

  /// `SupportsSortOrderToggle`.
  final bool supportsSortOrderToggle;

  /// `SupportsContentDownloading`.
  final bool supportsContentDownloading;

  /// `Audio`, `Video` or `Photo` (`MediaTypes`).
  final List<String> mediaTypes;

  /// `Song`, `Movie`, `Episode`, … (`ContentTypes`).
  final List<String> contentTypes;

  /// `DefaultSortFields`.
  final List<String> defaultSortFields;

  /// `MaxPageSize`.
  final int? maxPageSize;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds channel features from already-parsed components.
  const JellyfinChannelFeatures({
    required this.id,
    required this.canSearch,
    required this.canFilter,
    required this.supportsLatestMedia,
    required this.supportsSortOrderToggle,
    required this.supportsContentDownloading,
    required this.mediaTypes,
    required this.contentTypes,
    required this.defaultSortFields,
    required this.raw,
    this.name,
    this.maxPageSize,
  });

  /// Decodes a `ChannelFeatures`.
  factory JellyfinChannelFeatures.fromJson(Map<String, Object?> json) =>
      JellyfinChannelFeatures(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        canSearch: json['CanSearch'] == true,
        canFilter: json['CanFilter'] == true,
        supportsLatestMedia: json['SupportsLatestMedia'] == true,
        supportsSortOrderToggle: json['SupportsSortOrderToggle'] == true,
        supportsContentDownloading: json['SupportsContentDownloading'] == true,
        mediaTypes: asStringList(json['MediaTypes']),
        contentTypes: asStringList(json['ContentTypes']),
        defaultSortFields: asStringList(json['DefaultSortFields']),
        maxPageSize: asInt(json['MaxPageSize']),
        raw: json,
      );
}

/// The admin options of a device (`DeviceOptionsDto`).
final class JellyfinDeviceOptions {
  /// `DeviceId`.
  final String? deviceId;

  /// The name the admin gave it (`CustomName`).
  final String? customName;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds device options from already-parsed components.
  const JellyfinDeviceOptions({
    required this.raw,
    this.deviceId,
    this.customName,
  });

  /// Decodes a `DeviceOptionsDto`.
  factory JellyfinDeviceOptions.fromJson(Map<String, Object?> json) =>
      JellyfinDeviceOptions(
        deviceId: asString(json['DeviceId']),
        customName: asString(json['CustomName']),
        raw: json,
      );
}

/// A file, folder or drive on the server's machine
/// (`FileSystemEntryInfo`).
final class JellyfinFileSystemEntry {
  /// `Name`.
  final String name;

  /// The full path (`Path`).
  final String path;

  /// `File`, `Directory`, `NetworkComputer` or `NetworkShare` (`Type`).
  final String? type;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds an entry from already-parsed components.
  const JellyfinFileSystemEntry({
    required this.name,
    required this.path,
    required this.raw,
    this.type,
  });

  /// Decodes a `FileSystemEntryInfo`.
  factory JellyfinFileSystemEntry.fromJson(Map<String, Object?> json) =>
      JellyfinFileSystemEntry(
        name: asString(json['Name']) ?? '',
        path: asString(json['Path']) ?? '',
        type: asString(json['Type']),
        raw: json,
      );

  /// [type] is `Directory`.
  bool get isDirectory => type == 'Directory';
}

/// Where the folder picker should start (`DefaultDirectoryBrowserInfoDto`).
final class JellyfinDefaultDirectoryBrowser {
  /// `Path`; `null` when the server suggests none (12.4 in Docker answers
  /// `{}`).
  final String? path;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the answer from already-parsed components.
  const JellyfinDefaultDirectoryBrowser({required this.raw, this.path});

  /// Decodes `{Path}`.
  factory JellyfinDefaultDirectoryBrowser.fromJson(
    Map<String, Object?> json,
  ) => JellyfinDefaultDirectoryBrowser(
    path: asString(json['Path']),
    raw: json,
  );
}

/// The answer to `collection.create` (`CollectionCreationResult`).
final class JellyfinCollectionCreationResult {
  /// The new collection's id (`Id`).
  final String id;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the result from already-parsed components.
  const JellyfinCollectionCreationResult({
    required this.id,
    required this.raw,
  });

  /// Decodes `{Id}`.
  factory JellyfinCollectionCreationResult.fromJson(
    Map<String, Object?> json,
  ) => JellyfinCollectionCreationResult(
    id: asString(json['Id']) ?? '',
    raw: json,
  );
}

// ---------------------------------------------------------------------------
// Localization
// ---------------------------------------------------------------------------

/// A country (`CountryInfo`).
final class JellyfinCountry {
  /// `Name`, the two-letter code on 12.4.
  final String name;

  /// `DisplayName`.
  final String? displayName;

  /// `TwoLetterISORegionName`.
  final String? twoLetterIsoRegionName;

  /// `ThreeLetterISORegionName`.
  final String? threeLetterIsoRegionName;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a country from already-parsed components.
  const JellyfinCountry({
    required this.name,
    required this.raw,
    this.displayName,
    this.twoLetterIsoRegionName,
    this.threeLetterIsoRegionName,
  });

  /// Decodes a `CountryInfo`.
  factory JellyfinCountry.fromJson(Map<String, Object?> json) =>
      JellyfinCountry(
        name: asString(json['Name']) ?? '',
        displayName: asString(json['DisplayName']),
        twoLetterIsoRegionName: asString(json['TwoLetterISORegionName']),
        threeLetterIsoRegionName: asString(json['ThreeLetterISORegionName']),
        raw: json,
      );
}

/// A language (`CultureDto`).
final class JellyfinCulture {
  /// `Name`.
  final String name;

  /// `DisplayName`.
  final String? displayName;

  /// `TwoLetterISOLanguageName`; `''` for a language without one.
  final String? twoLetterIsoLanguageName;

  /// `ThreeLetterISOLanguageName`.
  final String? threeLetterIsoLanguageName;

  /// Every three-letter code (`ThreeLetterISOLanguageNames`).
  final List<String> threeLetterIsoLanguageNames;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a culture from already-parsed components.
  const JellyfinCulture({
    required this.name,
    required this.threeLetterIsoLanguageNames,
    required this.raw,
    this.displayName,
    this.twoLetterIsoLanguageName,
    this.threeLetterIsoLanguageName,
  });

  /// Decodes a `CultureDto`.
  factory JellyfinCulture.fromJson(Map<String, Object?> json) =>
      JellyfinCulture(
        name: asString(json['Name']) ?? '',
        displayName: asString(json['DisplayName']),
        twoLetterIsoLanguageName: asString(json['TwoLetterISOLanguageName']),
        threeLetterIsoLanguageName: asString(
          json['ThreeLetterISOLanguageName'],
        ),
        threeLetterIsoLanguageNames: asStringList(
          json['ThreeLetterISOLanguageNames'],
        ),
        raw: json,
      );
}

/// A parental rating (`ParentalRating`).
final class JellyfinParentalRating {
  /// `Name`, e.g. `PG-13`.
  final String name;

  /// `Value`; absent for `Unrated`.
  final int? value;

  /// `RatingScore.score`.
  final int? score;

  /// `RatingScore.subScore`.
  final int? subScore;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a rating from already-parsed components.
  const JellyfinParentalRating({
    required this.name,
    required this.raw,
    this.value,
    this.score,
    this.subScore,
  });

  /// Decodes a `ParentalRating`.
  factory JellyfinParentalRating.fromJson(Map<String, Object?> json) {
    final score = _object(json['RatingScore']);
    return JellyfinParentalRating(
      name: asString(json['Name']) ?? '',
      value: asInt(json['Value']),
      score: asInt(score['score']),
      subScore: asInt(score['subScore']),
      raw: json,
    );
  }
}

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
        JellyfinQueryResult.fromJson(_object(json[key]), JellyfinItem.fromJson);
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
        libraryOptions: _object(json['LibraryOptions']),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Plugins and packages
// ---------------------------------------------------------------------------

/// An installed plugin (`PluginInfo`).
final class JellyfinPluginInfo {
  /// `Id`, for the `plugins` calls.
  final String id;

  /// `Name`.
  final String name;

  /// `Version`, e.g. `12.4.0.0`.
  final String version;

  /// `Description`.
  final String? description;

  /// `ConfigurationFileName`.
  final String? configurationFileName;

  /// `CanUninstall`; `false` for the bundled plugins.
  final bool canUninstall;

  /// `HasImage`, for `plugins.imageUrl`.
  final bool hasImage;

  /// `Active`, `Restart`, `Disabled`, `NotSupported`, `Malfunctioned`,
  /// `Superseded` or `Deleted` (`Status`).
  final String? status;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a plugin from already-parsed components.
  const JellyfinPluginInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.canUninstall,
    required this.hasImage,
    required this.raw,
    this.description,
    this.configurationFileName,
    this.status,
  });

  /// Decodes a `PluginInfo`.
  factory JellyfinPluginInfo.fromJson(Map<String, Object?> json) =>
      JellyfinPluginInfo(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']) ?? '',
        version: asString(json['Version']) ?? '',
        description: asString(json['Description']),
        configurationFileName: asString(json['ConfigurationFileName']),
        canUninstall: json['CanUninstall'] == true,
        hasImage: json['HasImage'] == true,
        status: asString(json['Status']),
        raw: json,
      );
}

/// The manifest of an installed plugin (`PluginManifest`; the API document
/// gives no schema, the fields are those 12.4 sends, in camelCase).
final class JellyfinPluginManifest {
  /// `guid`.
  final String guid;

  /// `name`.
  final String name;

  /// `version`.
  final String? version;

  /// `description`.
  final String? description;

  /// `overview`.
  final String? overview;

  /// `owner`.
  final String? owner;

  /// `category`.
  final String? category;

  /// `changelog`.
  final String? changelog;

  /// The server ABI it targets (`targetAbi`).
  final String? targetAbi;

  /// `status`, as in [JellyfinPluginInfo.status].
  final String? status;

  /// `autoUpdate`.
  final bool autoUpdate;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a manifest from already-parsed components.
  const JellyfinPluginManifest({
    required this.guid,
    required this.name,
    required this.autoUpdate,
    required this.raw,
    this.version,
    this.description,
    this.overview,
    this.owner,
    this.category,
    this.changelog,
    this.targetAbi,
    this.status,
  });

  /// Decodes a plugin manifest.
  factory JellyfinPluginManifest.fromJson(Map<String, Object?> json) =>
      JellyfinPluginManifest(
        guid: asString(json['guid']) ?? '',
        name: asString(json['name']) ?? '',
        version: asString(json['version']),
        description: asString(json['description']),
        overview: asString(json['overview']),
        owner: asString(json['owner']),
        category: asString(json['category']),
        changelog: asString(json['changelog']),
        targetAbi: asString(json['targetAbi']),
        status: asString(json['status']),
        autoUpdate: json['autoUpdate'] == true,
        raw: json,
      );
}

/// One release of a package (`VersionInfo`, camelCase on the wire).
final class JellyfinPackageVersion {
  /// `version`, e.g. `13.0.0.0`.
  final String version;

  /// `changelog`.
  final String? changelog;

  /// The server ABI it needs (`targetAbi`).
  final String? targetAbi;

  /// The archive (`sourceUrl`).
  final String? sourceUrl;

  /// `checksum`.
  final String? checksum;

  /// `timestamp`.
  final DateTime? timestamp;

  /// `repositoryName`.
  final String? repositoryName;

  /// `repositoryUrl`, for `packages.install`.
  final String? repositoryUrl;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a version from already-parsed components.
  const JellyfinPackageVersion({
    required this.version,
    required this.raw,
    this.changelog,
    this.targetAbi,
    this.sourceUrl,
    this.checksum,
    this.timestamp,
    this.repositoryName,
    this.repositoryUrl,
  });

  /// Decodes a `VersionInfo`.
  factory JellyfinPackageVersion.fromJson(Map<String, Object?> json) =>
      JellyfinPackageVersion(
        version: asString(json['version'] ?? json['VersionNumber']) ?? '',
        changelog: asString(json['changelog']),
        targetAbi: asString(json['targetAbi']),
        sourceUrl: asString(json['sourceUrl']),
        checksum: asString(json['checksum']),
        timestamp: asUtcDateTime(json['timestamp']),
        repositoryName: asString(json['repositoryName']),
        repositoryUrl: asString(json['repositoryUrl']),
        raw: json,
      );
}

/// A plugin a repository offers (`PackageInfo`, camelCase on the wire).
final class JellyfinPackageInfo {
  /// `name`, for `packages.byName` and `install`.
  final String name;

  /// The plugin id (`guid`), the `assemblyGuid` of `install`.
  final String? guid;

  /// `description`.
  final String? description;

  /// `overview`.
  final String? overview;

  /// `owner`.
  final String? owner;

  /// `category`.
  final String? category;

  /// `imageUrl`.
  final String? imageUrl;

  /// The releases, newest first as the repository lists them
  /// (`versions`).
  final List<JellyfinPackageVersion> versions;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a package from already-parsed components.
  const JellyfinPackageInfo({
    required this.name,
    required this.versions,
    required this.raw,
    this.guid,
    this.description,
    this.overview,
    this.owner,
    this.category,
    this.imageUrl,
  });

  /// Decodes a `PackageInfo`.
  factory JellyfinPackageInfo.fromJson(Map<String, Object?> json) =>
      JellyfinPackageInfo(
        name: asString(json['name']) ?? '',
        guid: asString(json['guid']),
        description: asString(json['description']),
        overview: asString(json['overview']),
        owner: asString(json['owner']),
        category: asString(json['category']),
        imageUrl: asString(json['imageUrl']),
        versions: asObjectList(
          json['versions'],
          JellyfinPackageVersion.fromJson,
        ),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Live TV
// ---------------------------------------------------------------------------

/// A scheduled recording (`TimerInfoDto`).
final class JellyfinTimer {
  /// `Id`, for `liveTv.deleteTimer`.
  final String id;

  /// `Name`.
  final String? name;

  /// `Overview`.
  final String? overview;

  /// `ChannelId`.
  final String? channelId;

  /// `ChannelName`.
  final String? channelName;

  /// `ProgramId`.
  final String? programId;

  /// The series rule that created it (`SeriesTimerId`).
  final String? seriesTimerId;

  /// `StartDate`.
  final DateTime? startDate;

  /// `EndDate`.
  final DateTime? endDate;

  /// `New`, `InProgress`, `Completed`, … (`Status`).
  final String? status;

  /// `Priority`.
  final int? priority;

  /// `PrePaddingSeconds`.
  final int? prePaddingSeconds;

  /// `PostPaddingSeconds`.
  final int? postPaddingSeconds;

  /// `UntilDeleted`, `UntilSpaceNeeded`, … (`KeepUntil`).
  final String? keepUntil;

  /// `RunTimeTicks`.
  final int? runTimeTicks;

  /// The program to record (`ProgramInfo`).
  final JellyfinItem? programInfo;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a timer from already-parsed components.
  const JellyfinTimer({
    required this.id,
    required this.raw,
    this.name,
    this.overview,
    this.channelId,
    this.channelName,
    this.programId,
    this.seriesTimerId,
    this.startDate,
    this.endDate,
    this.status,
    this.priority,
    this.prePaddingSeconds,
    this.postPaddingSeconds,
    this.keepUntil,
    this.runTimeTicks,
    this.programInfo,
  });

  /// Decodes a `TimerInfoDto`.
  factory JellyfinTimer.fromJson(Map<String, Object?> json) {
    final program = json['ProgramInfo'];
    return JellyfinTimer(
      id: asString(json['Id']) ?? '',
      name: asString(json['Name']),
      overview: asString(json['Overview']),
      channelId: asString(json['ChannelId']),
      channelName: asString(json['ChannelName']),
      programId: asString(json['ProgramId']),
      seriesTimerId: asString(json['SeriesTimerId']),
      startDate: asUtcDateTime(json['StartDate']),
      endDate: asUtcDateTime(json['EndDate']),
      status: asString(json['Status']),
      priority: asInt(json['Priority']),
      prePaddingSeconds: asInt(json['PrePaddingSeconds']),
      postPaddingSeconds: asInt(json['PostPaddingSeconds']),
      keepUntil: asString(json['KeepUntil']),
      runTimeTicks: asInt(json['RunTimeTicks']),
      programInfo: program is Map<String, Object?>
          ? JellyfinItem.fromJson(program)
          : null,
      raw: json,
    );
  }
}

/// A recurring recording rule (`SeriesTimerInfoDto`), and the defaults
/// `liveTv.defaultTimer` answers.
final class JellyfinSeriesTimer {
  /// `Id`, for `liveTv.deleteSeriesTimer`.
  final String id;

  /// `Name`.
  final String? name;

  /// `Overview`.
  final String? overview;

  /// `ChannelId`.
  final String? channelId;

  /// `ChannelName`.
  final String? channelName;

  /// `ProgramId`.
  final String? programId;

  /// `StartDate`.
  final DateTime? startDate;

  /// `EndDate`.
  final DateTime? endDate;

  /// `Priority`.
  final int? priority;

  /// `PrePaddingSeconds`.
  final int? prePaddingSeconds;

  /// `PostPaddingSeconds`.
  final int? postPaddingSeconds;

  /// `KeepUntil`.
  final String? keepUntil;

  /// How many recordings to keep, `0` for all (`KeepUpTo`).
  final int? keepUpTo;

  /// `RecordAnyTime`.
  final bool recordAnyTime;

  /// `RecordAnyChannel`.
  final bool recordAnyChannel;

  /// `RecordNewOnly`.
  final bool recordNewOnly;

  /// `SkipEpisodesInLibrary`.
  final bool skipEpisodesInLibrary;

  /// The days it records on, `Sunday` … `Saturday` (`Days`).
  final List<String> days;

  /// `Daily`, `Weekdays` or `Weekends` (`DayPattern`).
  final String? dayPattern;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a series timer from already-parsed components.
  const JellyfinSeriesTimer({
    required this.id,
    required this.recordAnyTime,
    required this.recordAnyChannel,
    required this.recordNewOnly,
    required this.skipEpisodesInLibrary,
    required this.days,
    required this.raw,
    this.name,
    this.overview,
    this.channelId,
    this.channelName,
    this.programId,
    this.startDate,
    this.endDate,
    this.priority,
    this.prePaddingSeconds,
    this.postPaddingSeconds,
    this.keepUntil,
    this.keepUpTo,
    this.dayPattern,
  });

  /// Decodes a `SeriesTimerInfoDto`.
  factory JellyfinSeriesTimer.fromJson(Map<String, Object?> json) =>
      JellyfinSeriesTimer(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        overview: asString(json['Overview']),
        channelId: asString(json['ChannelId']),
        channelName: asString(json['ChannelName']),
        programId: asString(json['ProgramId']),
        startDate: asUtcDateTime(json['StartDate']),
        endDate: asUtcDateTime(json['EndDate']),
        priority: asInt(json['Priority']),
        prePaddingSeconds: asInt(json['PrePaddingSeconds']),
        postPaddingSeconds: asInt(json['PostPaddingSeconds']),
        keepUntil: asString(json['KeepUntil']),
        keepUpTo: asInt(json['KeepUpTo']),
        recordAnyTime: json['RecordAnyTime'] == true,
        recordAnyChannel: json['RecordAnyChannel'] == true,
        recordNewOnly: json['RecordNewOnly'] == true,
        skipEpisodesInLibrary: json['SkipEpisodesInLibrary'] == true,
        days: asStringList(json['Days']),
        dayPattern: asString(json['DayPattern']),
        raw: json,
      );
}

/// A live TV backend (`LiveTvServiceInfo`).
final class JellyfinLiveTvService {
  /// `Name`.
  final String name;

  /// `Ok` or `Unavailable` (`Status`).
  final String? status;

  /// `StatusMessage`.
  final String? statusMessage;

  /// `Version`.
  final String? version;

  /// `IsVisible`.
  final bool isVisible;

  /// `HasUpdateAvailable`.
  final bool hasUpdateAvailable;

  /// `Tuners`.
  final List<String> tuners;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a service from already-parsed components.
  const JellyfinLiveTvService({
    required this.name,
    required this.isVisible,
    required this.hasUpdateAvailable,
    required this.tuners,
    required this.raw,
    this.status,
    this.statusMessage,
    this.version,
  });

  /// Decodes a `LiveTvServiceInfo`.
  factory JellyfinLiveTvService.fromJson(Map<String, Object?> json) =>
      JellyfinLiveTvService(
        name: asString(json['Name']) ?? '',
        status: asString(json['Status']),
        statusMessage: asString(json['StatusMessage']),
        version: asString(json['Version']),
        isVisible: json['IsVisible'] == true,
        hasUpdateAvailable: json['HasUpdateAvailable'] == true,
        tuners: asStringList(json['Tuners']),
        raw: json,
      );
}

/// The live TV setup of the server (`LiveTvInfo`).
final class JellyfinLiveTvInfo {
  /// `IsEnabled`.
  final bool isEnabled;

  /// The backends (`Services`).
  final List<JellyfinLiveTvService> services;

  /// The users allowed live TV (`EnabledUsers`).
  final List<String> enabledUsers;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the info from already-parsed components.
  const JellyfinLiveTvInfo({
    required this.isEnabled,
    required this.services,
    required this.enabledUsers,
    required this.raw,
  });

  /// Decodes a `LiveTvInfo`.
  factory JellyfinLiveTvInfo.fromJson(Map<String, Object?> json) =>
      JellyfinLiveTvInfo(
        isEnabled: json['IsEnabled'] == true,
        services: asObjectList(
          json['Services'],
          JellyfinLiveTvService.fromJson,
        ),
        enabledUsers: asStringList(json['EnabledUsers']),
        raw: json,
      );
}

/// The time window the guide covers (`GuideInfo`).
final class JellyfinGuideInfo {
  /// `StartDate`.
  final DateTime? startDate;

  /// `EndDate`.
  final DateTime? endDate;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the guide info from already-parsed components.
  const JellyfinGuideInfo({required this.raw, this.startDate, this.endDate});

  /// Decodes a `GuideInfo`.
  factory JellyfinGuideInfo.fromJson(Map<String, Object?> json) =>
      JellyfinGuideInfo(
        startDate: asUtcDateTime(json['StartDate']),
        endDate: asUtcDateTime(json['EndDate']),
        raw: json,
      );
}

/// A tuner channel and the guide channel it maps to
/// (`TunerChannelMapping`).
final class JellyfinTunerChannelMapping {
  /// The tuner channel (`Id`).
  final String id;

  /// `Name`.
  final String? name;

  /// The guide channel (`ProviderChannelId`).
  final String? providerChannelId;

  /// `ProviderChannelName`.
  final String? providerChannelName;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a mapping from already-parsed components.
  const JellyfinTunerChannelMapping({
    required this.id,
    required this.raw,
    this.name,
    this.providerChannelId,
    this.providerChannelName,
  });

  /// Decodes a `TunerChannelMapping`.
  factory JellyfinTunerChannelMapping.fromJson(Map<String, Object?> json) =>
      JellyfinTunerChannelMapping(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']),
        providerChannelId: asString(json['ProviderChannelId']),
        providerChannelName: asString(json['ProviderChannelName']),
        raw: json,
      );
}

/// The channel mappings of a listings provider
/// (`ChannelMappingOptionsDto`).
final class JellyfinChannelMappingOptions {
  /// `TunerChannels`.
  final List<JellyfinTunerChannelMapping> tunerChannels;

  /// `ProviderChannels`.
  final List<JellyfinNameIdPair> providerChannels;

  /// `Mappings`.
  final List<JellyfinNameValuePair> mappings;

  /// `ProviderName`.
  final String? providerName;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the options from already-parsed components.
  const JellyfinChannelMappingOptions({
    required this.tunerChannels,
    required this.providerChannels,
    required this.mappings,
    required this.raw,
    this.providerName,
  });

  /// Decodes a `ChannelMappingOptionsDto`.
  factory JellyfinChannelMappingOptions.fromJson(Map<String, Object?> json) =>
      JellyfinChannelMappingOptions(
        tunerChannels: asObjectList(
          json['TunerChannels'],
          JellyfinTunerChannelMapping.fromJson,
        ),
        providerChannels: asObjectList(
          json['ProviderChannels'],
          JellyfinNameIdPair.fromJson,
        ),
        mappings: asObjectList(
          json['Mappings'],
          JellyfinNameValuePair.fromJson,
        ),
        providerName: asString(json['ProviderName']),
        raw: json,
      );
}

/// A tuner (`TunerHostInfo`).
final class JellyfinTunerHost {
  /// `Id`, for `liveTv.deleteTunerHost`.
  final String? id;

  /// `hdhomerun` or `m3u` (`Type`).
  final String? type;

  /// `Url`.
  final String? url;

  /// `DeviceId`.
  final String? deviceId;

  /// `FriendlyName`.
  final String? friendlyName;

  /// `TunerCount`.
  final int? tunerCount;

  /// `ImportFavoritesOnly`.
  final bool importFavoritesOnly;

  /// `AllowHWTranscoding`.
  final bool allowHwTranscoding;

  /// `AllowStreamSharing`.
  final bool allowStreamSharing;

  /// `UserAgent`.
  final String? userAgent;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a tuner host from already-parsed components.
  const JellyfinTunerHost({
    required this.importFavoritesOnly,
    required this.allowHwTranscoding,
    required this.allowStreamSharing,
    required this.raw,
    this.id,
    this.type,
    this.url,
    this.deviceId,
    this.friendlyName,
    this.tunerCount,
    this.userAgent,
  });

  /// Decodes a `TunerHostInfo`.
  factory JellyfinTunerHost.fromJson(Map<String, Object?> json) =>
      JellyfinTunerHost(
        id: asString(json['Id']),
        type: asString(json['Type']),
        url: asString(json['Url']),
        deviceId: asString(json['DeviceId']),
        friendlyName: asString(json['FriendlyName']),
        tunerCount: asInt(json['TunerCount']),
        importFavoritesOnly: json['ImportFavoritesOnly'] == true,
        allowHwTranscoding: json['AllowHWTranscoding'] == true,
        allowStreamSharing: json['AllowStreamSharing'] == true,
        userAgent: asString(json['UserAgent']),
        raw: json,
      );
}

/// A guide data source (`ListingsProviderInfo`).
final class JellyfinListingsProvider {
  /// `Id`, for `liveTv.deleteListingProvider`.
  final String? id;

  /// `SchedulesDirect` or `xmltv` (`Type`).
  final String? type;

  /// `ListingsId`.
  final String? listingsId;

  /// `Path`, for XMLTV.
  final String? path;

  /// `Country`.
  final String? country;

  /// `ZipCode`.
  final String? zipCode;

  /// `EnableAllTuners`.
  final bool enableAllTuners;

  /// `EnabledTuners`.
  final List<String> enabledTuners;

  /// `NewsCategories`.
  final List<String> newsCategories;

  /// `SportsCategories`.
  final List<String> sportsCategories;

  /// `KidsCategories`.
  final List<String> kidsCategories;

  /// `MovieCategories`.
  final List<String> movieCategories;

  /// `ChannelMappings`.
  final List<JellyfinNameValuePair> channelMappings;

  /// The decoded body; holds `Username` and `Password` when set.
  final Map<String, Object?> raw;

  /// Builds a listings provider from already-parsed components.
  const JellyfinListingsProvider({
    required this.enableAllTuners,
    required this.enabledTuners,
    required this.newsCategories,
    required this.sportsCategories,
    required this.kidsCategories,
    required this.movieCategories,
    required this.channelMappings,
    required this.raw,
    this.id,
    this.type,
    this.listingsId,
    this.path,
    this.country,
    this.zipCode,
  });

  /// Decodes a `ListingsProviderInfo`.
  factory JellyfinListingsProvider.fromJson(Map<String, Object?> json) =>
      JellyfinListingsProvider(
        id: asString(json['Id']),
        type: asString(json['Type']),
        listingsId: asString(json['ListingsId']),
        path: asString(json['Path']),
        country: asString(json['Country']),
        zipCode: asString(json['ZipCode']),
        enableAllTuners: json['EnableAllTuners'] == true,
        enabledTuners: asStringList(json['EnabledTuners']),
        newsCategories: asStringList(json['NewsCategories']),
        sportsCategories: asStringList(json['SportsCategories']),
        kidsCategories: asStringList(json['KidsCategories']),
        movieCategories: asStringList(json['MovieCategories']),
        channelMappings: asObjectList(
          json['ChannelMappings'],
          JellyfinNameValuePair.fromJson,
        ),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Subtitles, fonts, system
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

/// A file on the server: a fallback font (`FontFile`) or a log
/// (`LogFile`).
final class JellyfinServerFile {
  /// `Name`, for `subtitles.fallbackFontUrl` or `system.logFile`.
  final String name;

  /// Bytes (`Size`).
  final int? size;

  /// `DateCreated`.
  final DateTime? dateCreated;

  /// `DateModified`.
  final DateTime? dateModified;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a file from already-parsed components.
  const JellyfinServerFile({
    required this.name,
    required this.raw,
    this.size,
    this.dateCreated,
    this.dateModified,
  });

  /// Decodes a `FontFile` or `LogFile`.
  factory JellyfinServerFile.fromJson(Map<String, Object?> json) =>
      JellyfinServerFile(
        name: asString(json['Name']) ?? '',
        size: asInt(json['Size']),
        dateCreated: asUtcDateTime(json['DateCreated']),
        dateModified: asUtcDateTime(json['DateModified']),
        raw: json,
      );
}

/// Space on one folder's drive (`FolderStorageDto`).
final class JellyfinFolderStorage {
  /// `Path`.
  final String path;

  /// Free bytes (`FreeSpace`).
  final int? freeSpace;

  /// Used bytes (`UsedSpace`).
  final int? usedSpace;

  /// `Fixed`, `Network`, … (`StorageType`).
  final String? storageType;

  /// The mount the folder is on (`DeviceId`).
  final String? deviceId;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds folder storage from already-parsed components.
  const JellyfinFolderStorage({
    required this.path,
    required this.raw,
    this.freeSpace,
    this.usedSpace,
    this.storageType,
    this.deviceId,
  });

  /// Decodes a `FolderStorageDto`.
  factory JellyfinFolderStorage.fromJson(Map<String, Object?> json) =>
      JellyfinFolderStorage(
        path: asString(json['Path']) ?? '',
        freeSpace: asInt(json['FreeSpace']),
        usedSpace: asInt(json['UsedSpace']),
        storageType: asString(json['StorageType']),
        deviceId: asString(json['DeviceId']),
        raw: json,
      );
}

/// The folders of one library and their space (`LibraryStorageDto`).
final class JellyfinLibraryStorage {
  /// `Id`.
  final String id;

  /// `Name`.
  final String name;

  /// `Folders`.
  final List<JellyfinFolderStorage> folders;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds library storage from already-parsed components.
  const JellyfinLibraryStorage({
    required this.id,
    required this.name,
    required this.folders,
    required this.raw,
  });

  /// Decodes a `LibraryStorageDto`.
  factory JellyfinLibraryStorage.fromJson(Map<String, Object?> json) =>
      JellyfinLibraryStorage(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']) ?? '',
        folders: asObjectList(json['Folders'], JellyfinFolderStorage.fromJson),
        raw: json,
      );
}

/// Space on the server's folders and libraries (`SystemStorageDto`).
final class JellyfinSystemStorage {
  /// `ProgramDataFolder`.
  final JellyfinFolderStorage? programDataFolder;

  /// `WebFolder`.
  final JellyfinFolderStorage? webFolder;

  /// `ImageCacheFolder`.
  final JellyfinFolderStorage? imageCacheFolder;

  /// `CacheFolder`.
  final JellyfinFolderStorage? cacheFolder;

  /// `LogFolder`.
  final JellyfinFolderStorage? logFolder;

  /// `InternalMetadataFolder`.
  final JellyfinFolderStorage? internalMetadataFolder;

  /// `TranscodingTempFolder`.
  final JellyfinFolderStorage? transcodingTempFolder;

  /// `Libraries`.
  final List<JellyfinLibraryStorage> libraries;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds system storage from already-parsed components.
  const JellyfinSystemStorage({
    required this.libraries,
    required this.raw,
    this.programDataFolder,
    this.webFolder,
    this.imageCacheFolder,
    this.cacheFolder,
    this.logFolder,
    this.internalMetadataFolder,
    this.transcodingTempFolder,
  });

  /// Decodes a `SystemStorageDto`.
  factory JellyfinSystemStorage.fromJson(Map<String, Object?> json) {
    JellyfinFolderStorage? folder(String key) {
      final v = json[key];
      return v is Map<String, Object?>
          ? JellyfinFolderStorage.fromJson(v)
          : null;
    }

    return JellyfinSystemStorage(
      programDataFolder: folder('ProgramDataFolder'),
      webFolder: folder('WebFolder'),
      imageCacheFolder: folder('ImageCacheFolder'),
      cacheFolder: folder('CacheFolder'),
      logFolder: folder('LogFolder'),
      internalMetadataFolder: folder('InternalMetadataFolder'),
      transcodingTempFolder: folder('TranscodingTempFolder'),
      libraries: asObjectList(
        json['Libraries'],
        JellyfinLibraryStorage.fromJson,
      ),
      raw: json,
    );
  }
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

/// The first user the setup wizard is creating (`StartupUserDto`).
final class JellyfinStartupUser {
  /// `Name`.
  final String? name;

  /// `Password`.
  final String? password;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds a startup user from already-parsed components.
  const JellyfinStartupUser({required this.raw, this.name, this.password});

  /// Decodes a `StartupUserDto`.
  factory JellyfinStartupUser.fromJson(Map<String, Object?> json) =>
      JellyfinStartupUser(
        name: asString(json['Name']),
        password: asString(json['Password']),
        raw: json,
      );
}

/// The answer to `user.forgotPassword` (`ForgotPasswordResult`).
final class JellyfinForgotPasswordResult {
  /// `ContactAdmin`, `PinCode` or `InNetworkRequired` (`Action`).
  final String? action;

  /// Where the server wrote the PIN (`PinFile`).
  final String? pinFile;

  /// `PinExpirationDate`.
  final DateTime? pinExpirationDate;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the result from already-parsed components.
  const JellyfinForgotPasswordResult({
    required this.raw,
    this.action,
    this.pinFile,
    this.pinExpirationDate,
  });

  /// Decodes a `ForgotPasswordResult`.
  factory JellyfinForgotPasswordResult.fromJson(Map<String, Object?> json) =>
      JellyfinForgotPasswordResult(
        action: asString(json['Action']),
        pinFile: asString(json['PinFile']),
        pinExpirationDate: asUtcDateTime(json['PinExpirationDate']),
        raw: json,
      );
}

/// The answer to `user.forgotPasswordPin` (`PinRedeemResult`).
final class JellyfinPinRedeemResult {
  /// `Success`.
  final bool success;

  /// The users whose password was reset (`UsersReset`).
  final List<String> usersReset;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the result from already-parsed components.
  const JellyfinPinRedeemResult({
    required this.success,
    required this.usersReset,
    required this.raw,
  });

  /// Decodes a `PinRedeemResult`.
  factory JellyfinPinRedeemResult.fromJson(Map<String, Object?> json) =>
      JellyfinPinRedeemResult(
        success: json['Success'] == true,
        usersReset: asStringList(json['UsersReset']),
        raw: json,
      );
}
