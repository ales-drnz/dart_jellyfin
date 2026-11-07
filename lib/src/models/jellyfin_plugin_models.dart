// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

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
