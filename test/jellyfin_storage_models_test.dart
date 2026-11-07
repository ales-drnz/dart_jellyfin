// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The remote subtitle, server file and storage models, decoded from bodies shaped like Jellyfin 12.4 answers.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const Map<String, Object?> _empty = {};

void main() {
  group('subtitles, fonts, system', () {
    test('JellyfinRemoteSubtitle', () {
      final s = JellyfinRemoteSubtitle.fromJson(const {
        'ThreeLetterISOLanguageName': 'ita',
        'Id': 'os-1',
        'ProviderName': 'Open Subtitles',
        'Name': 'Movie.2026.srt',
        'Format': 'srt',
        'DownloadCount': 1200,
        'CommunityRating': 8.5,
        'IsHashMatch': true,
        'HearingImpaired': true,
      });
      expect(s.id, 'os-1');
      expect(s.language, 'ita');
      expect(s.downloadCount, 1200);
      expect(s.isHashMatch, isTrue);
      expect(s.forced, isFalse);
      expect(JellyfinRemoteSubtitle.fromJson(_empty).format, isNull);
    });

    test('JellyfinServerFile (a log or a font)', () {
      final f = JellyfinServerFile.fromJson(const {
        'DateCreated': '2026-11-07T17:05:02.5049044Z',
        'DateModified': '2026-11-07T17:05:02.5049044Z',
        'Size': 19767,
        'Name': 'log_20261107.log',
      });
      expect(f.name, 'log_20261107.log');
      expect(f.size, 19767);
      expect(f.dateModified!.year, 2026);
      expect(JellyfinServerFile.fromJson(_empty).size, isNull);
    });

    test('JellyfinSystemStorage', () {
      const folder = {
        'Path': '/config',
        'FreeSpace': 126147047424,
        'UsedSpace': 869760737280,
        'StorageType': 'Fixed',
        'DeviceId': '/config',
      };
      final s = JellyfinSystemStorage.fromJson(const {
        'ProgramDataFolder': folder,
        'CacheFolder': folder,
        'Libraries': [
          {
            'Id': '7e64e319657a9516ec78490da03edccb',
            'Name': 'Music',
            'Folders': [folder],
          },
        ],
      });
      expect(s.programDataFolder!.freeSpace, 126147047424);
      expect(s.cacheFolder!.storageType, 'Fixed');
      expect(s.webFolder, isNull);
      expect(s.libraries.single.name, 'Music');
      expect(s.libraries.single.folders.single.path, '/config');
      final e = JellyfinSystemStorage.fromJson(_empty);
      expect(e.libraries, isEmpty);
      expect(e.logFolder, isNull);
      expect(JellyfinFolderStorage.fromJson(_empty).path, '');
      expect(JellyfinLibraryStorage.fromJson(_empty).folders, isEmpty);
    });
  });
}
