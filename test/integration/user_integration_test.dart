// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_fixture.dart';

/// Smoke tests for [JellyfinUserApi] against a live server.
void main() {
  group(
    'Jellyfin user',
    () {
      late JellyfinClient jf;
      late JellyfinBootstrapCache cache;

      setUpAll(() {
        cache = JellyfinBootstrapCache.load();
        jf = jellyfinFromCache();
      });

      test('currentUser returns the bootstrap admin', () async {
        final user = await jf.user.currentUser();
        expect(user.id, cache.userId);
        expect(user.name, cache.username);
      });

      test('list returns at least the admin user', () async {
        final users = await jf.user.list();
        expect(users.length, greaterThanOrEqualTo(1));
        expect(users.any((u) => u.id == cache.userId), isTrue);
      });

      test('publicUsers is callable without an active session', () async {
        // The seeded admin user is not marked public by default, so
        // the returned list may be empty. We only assert the call
        // succeeds and parses into a list.
        final list = await jf.user.publicUsers();
        expect(list, isA<List<JellyfinUser>>());
      });

      test('authProviders is callable and returns a parseable list', () async {
        final providers = await jf.user.authProviders();
        expect(providers, isA<List<Map<String, dynamic>>>());
        // Most Jellyfin builds ship at least one provider, but field
        // names vary by version, so we don't assert on contents.
      });
    },
    skip: bootstrapSkipReason,
  );
}
