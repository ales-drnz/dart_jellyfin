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
  group(
    'Jellyfin system',
    () {
      late JellyfinClient jf;

      setUpAll(() {
        jf = jellyfinFromCache();
      });

      test('publicInfo returns server identity without authentication',
          () async {
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

      test('utcTime is the server clock', () async {
        final t = await jf.system.utcTime();
        expect(t.requestReceptionTime, isNotNull);
        expect(t.responseTransmissionTime, isNotNull);
        final skew = t.requestReceptionTime!.difference(DateTime.now().toUtc());
        expect(skew.inMinutes.abs(), lessThan(5));
      });

      test('endpointInfo answers for this connection', () async {
        // Inside Docker the server sees the bridge network: the request is
        // in-network but not local.
        final ep = await jf.system.endpointInfo();
        expect(ep.raw, contains('IsInNetwork'));
        expect(ep.isInNetwork, isTrue);
      });
    },
    skip: bootstrapSkipReason,
  );
}
