// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The shared pairs, API key, backup, configuration and localization models, decoded from bodies shaped like Jellyfin 12.4 answers.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const Map<String, Object?> _empty = {};

void main() {
  group('shared pairs', () {
    test('JellyfinNameIdPair', () {
      final p = JellyfinNameIdPair.fromJson(const {
        'Name': 'HD Homerun',
        'Id': 'hdhomerun',
      });
      expect(p.name, 'HD Homerun');
      expect(p.id, 'hdhomerun');
      final e = JellyfinNameIdPair.fromJson(_empty);
      expect(e.name, '');
      expect(e.id, '');
    });

    test('JellyfinNameValuePair', () {
      final p = JellyfinNameValuePair.fromJson(const {
        'Name': 'Afrikaans',
        'Value': 'af',
      });
      expect(p.value, 'af');
      expect(JellyfinNameValuePair.fromJson(_empty).value, isNull);
    });
  });

  group('API keys, backups, configuration', () {
    test('JellyfinApiKey', () {
      final k = JellyfinApiKey.fromJson(const {
        'Id': 3,
        'AccessToken': 'abc123',
        'AppName': 'ci',
        'IsActive': true,
        'DateCreated': '2026-11-07T10:00:00.0000000Z',
        'UserId': '00000000000000000000000000000000',
      });
      expect(k.accessToken, 'abc123');
      expect(k.appName, 'ci');
      expect(k.isActive, isTrue);
      expect(k.dateCreated, DateTime.utc(2026, 11, 7, 10));
      final e = JellyfinApiKey.fromJson(_empty);
      expect(e.accessToken, '');
      expect(e.isActive, isFalse);
      expect(e.dateRevoked, isNull);
    });

    test('JellyfinBackupManifest and options', () {
      final m = JellyfinBackupManifest.fromJson(const {
        'ServerVersion': '12.4.0',
        'BackupEngineVersion': '0.2.0',
        'DateCreated': '2026-11-07T10:00:00Z',
        'Path': '/config/data/backups/jellyfin-backup.zip',
        'Options': {'Metadata': true, 'Database': true},
      });
      expect(m.path, endsWith('.zip'));
      expect(m.serverVersion, '12.4.0');
      expect(m.options!.metadata, isTrue);
      expect(m.options!.trickplay, isFalse);
      expect(m.options!.database, isTrue);
      final e = JellyfinBackupManifest.fromJson(_empty);
      expect(e.options, isNull);
      expect(e.path, isNull);
    });

    test('JellyfinServerConfiguration', () {
      final c = JellyfinServerConfiguration.fromJson(const {
        'ServerName': 'home',
        'UICulture': 'en-US',
        'PreferredMetadataLanguage': 'en',
        'MetadataCountryCode': 'US',
        'IsStartupWizardCompleted': true,
        'QuickConnectAvailable': true,
        'EnableLegacyAuthorization': false,
        'MinResumePct': 5,
        'MaxResumePct': 90,
        'RemoteClientBitrateLimit': 0,
        'PluginRepositories': [
          {
            'Name': 'Jellyfin Stable',
            'Url': 'https://repo.jellyfin.org/files/plugin/manifest.json',
            'Enabled': true,
          },
        ],
        'MetadataOptions': [
          {
            'ItemType': 'Book',
            'DisabledMetadataFetchers': ['x'],
          },
        ],
      });
      expect(c.serverName, 'home');
      expect(c.isStartupWizardCompleted, isTrue);
      expect(c.maxResumePct, 90);
      expect(c.pluginRepositories.single.enabled, isTrue);
      expect(c.metadataOptions.single.itemType, 'Book');
      expect(c.metadataOptions.single.disabledMetadataFetchers, ['x']);
      final e = JellyfinServerConfiguration.fromJson(_empty);
      expect(e.pluginRepositories, isEmpty);
      expect(e.quickConnectAvailable, isFalse);
    });

    test('JellyfinMetadataOptions (the default template)', () {
      final o = JellyfinMetadataOptions.fromJson(const {
        'DisabledMetadataSavers': <String>[],
        'LocalMetadataReaderOrder': <String>[],
        'MetadataFetcherOrder': ['TheMovieDb'],
      });
      expect(o.itemType, isNull);
      expect(o.metadataFetcherOrder, ['TheMovieDb']);
      expect(
        JellyfinMetadataOptions.fromJson(_empty).imageFetcherOrder,
        isEmpty,
      );
    });

    test('JellyfinBrandingOptions', () {
      final b = JellyfinBrandingOptions.fromJson(const {
        'SplashscreenEnabled': false,
      });
      expect(b.splashscreenEnabled, isFalse);
      expect(b.loginDisclaimer, isNull);
      expect(
        JellyfinBrandingOptions.fromJson(const {'CustomCss': 'a{}'}).customCss,
        'a{}',
      );
    });

    test('JellyfinConfigurationPage', () {
      final p = JellyfinConfigurationPage.fromJson(const {
        'Name': 'TMDb',
        'EnableInMainMenu': false,
        'DisplayName': 'TMDb',
        'PluginId': 'b8715ed16c4745289ad3f72deb539cd4',
      });
      expect(p.name, 'TMDb');
      expect(p.pluginId, 'b8715ed16c4745289ad3f72deb539cd4');
      expect(JellyfinConfigurationPage.fromJson(_empty).name, '');
    });

    test('JellyfinChannelFeatures', () {
      final f = JellyfinChannelFeatures.fromJson(const {
        'Name': 'Podcasts',
        'Id': 'c1',
        'CanSearch': true,
        'MediaTypes': ['Audio'],
        'ContentTypes': ['Podcast'],
        'MaxPageSize': 50,
        'DefaultSortFields': ['Name'],
      });
      expect(f.canSearch, isTrue);
      expect(f.mediaTypes, ['Audio']);
      expect(f.maxPageSize, 50);
      final e = JellyfinChannelFeatures.fromJson(_empty);
      expect(e.id, '');
      expect(e.contentTypes, isEmpty);
    });

    test('JellyfinDeviceOptions', () {
      final o = JellyfinDeviceOptions.fromJson(const {
        'Id': 1,
        'DeviceId': 'd1',
        'CustomName': 'Living room',
      });
      expect(o.deviceId, 'd1');
      expect(o.customName, 'Living room');
      expect(JellyfinDeviceOptions.fromJson(_empty).customName, isNull);
    });

    test('JellyfinFileSystemEntry and default directory', () {
      final d = JellyfinFileSystemEntry.fromJson(const {
        'Name': 'Music',
        'Path': '/media/Music',
        'Type': 'Directory',
      });
      expect(d.isDirectory, isTrue);
      expect(d.path, '/media/Music');
      final e = JellyfinFileSystemEntry.fromJson(_empty);
      expect(e.isDirectory, isFalse);
      expect(JellyfinDefaultDirectoryBrowser.fromJson(_empty).path, isNull);
      expect(
        JellyfinDefaultDirectoryBrowser.fromJson(const {'Path': '/media'}).path,
        '/media',
      );
    });

    test('JellyfinCollectionCreationResult', () {
      expect(
        JellyfinCollectionCreationResult.fromJson(const {'Id': 'b1'}).id,
        'b1',
      );
      expect(JellyfinCollectionCreationResult.fromJson(_empty).id, '');
    });
  });

  group('localization', () {
    test('JellyfinCountry', () {
      final c = JellyfinCountry.fromJson(const {
        'Name': 'AF',
        'DisplayName': 'Afghanistan',
        'TwoLetterISORegionName': 'AF',
        'ThreeLetterISORegionName': 'AFG',
      });
      expect(c.displayName, 'Afghanistan');
      expect(c.threeLetterIsoRegionName, 'AFG');
      expect(JellyfinCountry.fromJson(_empty).name, '');
    });

    test('JellyfinCulture', () {
      final c = JellyfinCulture.fromJson(const {
        'Name': 'Abkhazian',
        'DisplayName': 'Abkhazian',
        'TwoLetterISOLanguageName': 'ab',
        'ThreeLetterISOLanguageName': 'abk',
        'ThreeLetterISOLanguageNames': ['abk'],
      });
      expect(c.twoLetterIsoLanguageName, 'ab');
      expect(c.threeLetterIsoLanguageNames, ['abk']);
      expect(
        JellyfinCulture.fromJson(_empty).threeLetterIsoLanguageNames,
        isEmpty,
      );
    });

    test('JellyfinParentalRating, with and without a value', () {
      final r = JellyfinParentalRating.fromJson(const {
        'Name': 'TV-Y7',
        'Value': 7,
        'RatingScore': {'score': 7, 'subScore': 0},
      });
      expect(r.value, 7);
      expect(r.score, 7);
      expect(r.subScore, 0);
      final unrated = JellyfinParentalRating.fromJson(const {
        'Name': 'Unrated',
      });
      expect(unrated.value, isNull);
      expect(unrated.score, isNull);
    });
  });
}
