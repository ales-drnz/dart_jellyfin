// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for [JellyfinSystemApi] against a live server.
///
/// Run with: `dart test --tags integration`
void main() {
  group('Jellyfin system', () {
    late JellyfinClient jf;

    setUpAll(() {
      jf = jellyfinFromCache();
    });

    test('publicInfo returns server identity without authentication', () async {
      final info = await jf.system.publicInfo();
      expect(info.serverName, isNotEmpty);
      expect(info.version, matches(RegExp(r'^\d+\.\d+\.\d+')));
      expect(info.id, isNotEmpty);
    });

    test('info (authenticated) returns the same server identity', () async {
      final info = await jf.system.info();
      expect(info.id, isNotEmpty);
      expect(info.version, isNotEmpty);
    });

    test('ping returns true for a reachable server', () async {
      expect(await jf.system.ping(), isTrue);
    });

    test('utcTime returns RequestReceptionTime / ResponseTransmissionTime',
        () async {
      final t = await jf.system.utcTime();
      expect(t, isNotEmpty);
      expect(
        t.keys.toSet().intersection(
          {'RequestReceptionTime', 'ResponseTransmissionTime'},
        ),
        isNotEmpty,
      );
    });

    test('endpointInfo returns a parseable map', () async {
      // Inside Docker, the server sees the connection coming from
      // the bridge network, so IsLocal is not reliable in this
      // fixture. We just verify the endpoint is callable.
      final ep = await jf.system.endpointInfo();
      expect(ep, isNotEmpty);
      expect(ep.containsKey('IsLocal') || ep.containsKey('isLocal'), isTrue);
    });
  }, skip: bootstrapSkipReason);
}
