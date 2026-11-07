// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The plugin and package models, decoded from bodies shaped like Jellyfin 12.4 answers.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const Map<String, Object?> _empty = {};

void main() {
  group('plugins and packages', () {
    test('JellyfinPluginInfo', () {
      final p = JellyfinPluginInfo.fromJson(const {
        'Name': 'AudioDB',
        'Version': '12.4.0.0',
        'ConfigurationFileName': 'Jellyfin.Plugin.AudioDb.xml',
        'Id': 'a629c0dafac54c7e931a7174223f14c8',
        'CanUninstall': false,
        'HasImage': true,
        'Status': 'Active',
      });
      expect(p.version, '12.4.0.0');
      expect(p.hasImage, isTrue);
      expect(p.status, 'Active');
      expect(JellyfinPluginInfo.fromJson(_empty).status, isNull);
    });

    test('JellyfinPluginManifest (camelCase)', () {
      final m = JellyfinPluginManifest.fromJson(const {
        'guid': 'a629c0dafac54c7e931a7174223f14c8',
        'name': 'AudioDB',
        'version': '12.4.0.0',
        'status': 'Active',
        'autoUpdate': true,
      });
      expect(m.guid, 'a629c0dafac54c7e931a7174223f14c8');
      expect(m.autoUpdate, isTrue);
      expect(JellyfinPluginManifest.fromJson(_empty).name, '');
    });

    test('JellyfinPackageInfo with versions', () {
      final p = JellyfinPackageInfo.fromJson(const {
        'name': 'Bookshelf',
        'owner': 'jellyfin',
        'category': 'Books',
        'guid': '9c4e63f1031b4f25988b4f7d78a8b53e',
        'versions': [
          {
            'version': '13.0.0.0',
            'VersionNumber': '13.0.0.0',
            'targetAbi': '10.11.0.0',
            'timestamp': '2025-10-20T01:25:49Z',
            'repositoryUrl':
                'https://repo.jellyfin.org/files/plugin/manifest.json',
          },
        ],
      });
      expect(p.name, 'Bookshelf');
      expect(p.guid, '9c4e63f1031b4f25988b4f7d78a8b53e');
      final v = p.versions.single;
      expect(v.version, '13.0.0.0');
      expect(v.targetAbi, '10.11.0.0');
      expect(v.timestamp, DateTime.utc(2025, 10, 20, 1, 25, 49));
      expect(JellyfinPackageInfo.fromJson(_empty).versions, isEmpty);
      expect(JellyfinPackageVersion.fromJson(_empty).version, '');
    });

    test('JellyfinRepository', () {
      final r = JellyfinRepository.fromJson(const {
        'Name': 'Jellyfin Stable',
        'Url': 'https://repo.jellyfin.org/files/plugin/manifest.json',
        'Enabled': true,
      });
      expect(r.enabled, isTrue);
      expect(JellyfinRepository.fromJson(_empty).url, isNull);
    });
  });
}
