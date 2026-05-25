// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for the admin surface
/// ([JellyfinSystemApi], [JellyfinConfigurationApi],
/// [JellyfinEnvironmentApi], [JellyfinScheduledTasksApi],
/// [JellyfinPluginsApi], [JellyfinPackagesApi],
/// [JellyfinActivityLogApi], [JellyfinDevicesApi],
/// [JellyfinBrandingApi], [JellyfinDashboardApi],
/// [JellyfinApiKeyApi], [JellyfinNotificationsApi]).
void main() {
  group('Jellyfin admin APIs', () {
    late JellyfinClient jf;

    setUpAll(() {
      jf = jellyfinFromCache();
    });

    test('system.info returns the server identity', () async {
      final info = await jf.system.info();
      expect(info.id, isNotEmpty);
      expect(info.version, isNotEmpty);
    });

    test('system.publicInfo works without auth scope', () async {
      final info = await jf.system.publicInfo();
      expect(info.id, isNotEmpty);
    });

    test('system.ping returns true on a live server', () async {
      expect(await jf.system.ping(), isTrue);
    });

    test('system.endpointInfo + system.storage return populated maps',
        () async {
      final ep = await jf.system.endpointInfo();
      expect(ep, isNotEmpty);
      final st = await jf.system.storage();
      expect(st, isA<Map<String, dynamic>>());
    });

    test('configuration.get returns the server config map', () async {
      final cfg = await jf.configuration.get();
      expect(cfg, isNotEmpty);
    });

    test('environment.drives returns a list (possibly empty)', () async {
      final drives = await jf.environment.drives();
      expect(drives, isA<List<Map<String, dynamic>>>());
    });

    test('scheduledTasks.list returns the server task list', () async {
      final tasks = await jf.scheduledTasks.list();
      expect(tasks, isNotEmpty);
    });

    test('plugins.list returns a (possibly empty) list', () async {
      final ps = await jf.plugins.list();
      expect(ps, isA<List<Map<String, dynamic>>>());
    });

    test('packages.repositories returns the configured repositories',
        () async {
      final repos = await jf.packages.repositories();
      expect(repos, isA<List<Map<String, dynamic>>>());
    });

    test('activityLog.entries returns a paginated log (possibly empty)',
        () async {
      final entries = await jf.activityLog.entries(limit: 10);
      expect(entries, isA<List<Map<String, dynamic>>>());
    });

    test('devices.list includes the current test client', () async {
      final devices = await jf.devices.list();
      // Each call from the integration suite creates/touches a device
      // record with our credentials.deviceId.
      expect(devices, isNotEmpty);
    });

    test('branding.configuration returns the branding map', () async {
      final b = await jf.branding.configuration();
      expect(b, isA<Map<String, dynamic>>());
    });

    test('dashboard.configurationPages lists available admin pages',
        () async {
      final pages = await jf.dashboard.configurationPages();
      expect(pages, isA<List<Map<String, dynamic>>>());
    });

    test('apiKey.list returns the active API keys', () async {
      final keys = await jf.apiKey.list();
      expect(keys, isA<List<Map<String, dynamic>>>());
    });

    test('notifications WebSocket: connect -> close round trip', () async {
      expect(jf.notifications.isConnected, isFalse);
      final stream = jf.notifications.connect();
      expect(stream, isA<Stream<JellyfinNotification>>());
      // Give the socket a moment to actually open.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(jf.notifications.isConnected, isTrue);
      await jf.notifications.close();
      expect(jf.notifications.isConnected, isFalse);
    });
  }, skip: bootstrapSkipReason);
}
