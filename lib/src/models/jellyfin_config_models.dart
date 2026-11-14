// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

library;

import '../jellyfin_json.dart';

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
  factory JellyfinDefaultDirectoryBrowser.fromJson(Map<String, Object?> json) =>
      JellyfinDefaultDirectoryBrowser(path: asString(json['Path']), raw: json);
}

/// The answer to `collection.create` (`CollectionCreationResult`).
final class JellyfinCollectionCreationResult {
  /// The new collection's id (`Id`).
  final String id;

  /// The decoded body.
  final Map<String, Object?> raw;

  /// Builds the result from already-parsed components.
  const JellyfinCollectionCreationResult({required this.id, required this.raw});

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
    final score = asObject(json['RatingScore']);
    return JellyfinParentalRating(
      name: asString(json['Name']) ?? '',
      value: asInt(json['Value']),
      score: asInt(score['score']),
      subScore: asInt(score['subScore']),
      raw: json,
    );
  }
}
