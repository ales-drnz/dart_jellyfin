// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Shared fixture for the dart_jellyfin integration test suite.
///
/// Each `*_integration_test.dart` file calls [jellyfinFromCache] from
/// `setUpAll` to obtain an authenticated [JellyfinClient]. The
/// credentials come from `test/integration/.bootstrap-cache.json`
/// written by `bootstrap.dart`, so we don't re-run the wizard for
/// every test.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_jellyfin/dart_jellyfin.dart';

const String _cacheFile = 'test/integration/.bootstrap-cache.json';

/// Skip reason for the integration suite when the bootstrap hasn't
/// been run yet. Pass to `group(..., skip: bootstrapSkipReason)` so
/// `dart test` shows a clear message instead of failing.
String? get bootstrapSkipReason {
  if (File(_cacheFile).existsSync()) return null;
  return 'Bootstrap cache missing at $_cacheFile. '
      'Run `dart run test/integration/bootstrap.dart` first.';
}

class JellyfinBootstrapCache {
  final String baseUrl;
  final String token;
  final String userId;
  final String username;
  final String? serverName;
  final String? serverId;

  const JellyfinBootstrapCache({
    required this.baseUrl,
    required this.token,
    required this.userId,
    required this.username,
    this.serverName,
    this.serverId,
  });

  factory JellyfinBootstrapCache.load() {
    final file = File(_cacheFile);
    if (!file.existsSync()) {
      throw StateError(
        'Bootstrap cache missing at $_cacheFile. '
        'Run `dart run test/integration/bootstrap.dart` first.',
      );
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return JellyfinBootstrapCache(
      baseUrl: json['baseUrl'] as String,
      token: json['token'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      serverName: json['serverName'] as String?,
      serverId: json['serverId'] as String?,
    );
  }
}

/// Build a [JellyfinClient] from the bootstrap cache. The client is
/// fully authenticated and points at the local Docker stack.
///
/// When the cache is missing, returns an unconfigured client — the
/// surrounding `group(skip: bootstrapSkipReason)` guards the tests
/// from running, but `setUpAll` itself still executes on a skipped
/// group, so this must not throw.
JellyfinClient jellyfinFromCache() {
  final client = JellyfinClient(
    credentials: const JellyfinCredentials(
      client: 'dart_jellyfin_integration_tests',
      device: 'integration-tests',
      deviceId: 'dart-jellyfin-integration',
      version: '0.0.1',
    ),
  );
  if (!File(_cacheFile).existsSync()) return client;
  final cache = JellyfinBootstrapCache.load();
  client.connect(cache.baseUrl);
  client.setSession(token: cache.token, userId: cache.userId);
  return client;
}
