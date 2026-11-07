// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Server files and storage
// ---------------------------------------------------------------------------

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
