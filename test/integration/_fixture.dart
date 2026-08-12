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

/// Skip reason for the integration suite, or `null` when it can
/// actually run. Pass to `group(..., skip: bootstrapSkipReason)` so
/// `dart test` shows a clear message instead of failing.
///
/// Checks two things, because the cache alone is not enough: it stays
/// on disk after `docker compose down`, and a stale cache used to let
/// the whole suite run against nothing and fail with a wall of
/// `Connection refused` — noise that says nothing about the cause.
///
/// `skip:` is evaluated synchronously while the group is declared, so
/// the reachability probe has to be synchronous too: hence
/// [RawSynchronousSocket] rather than an HTTP request.
String? get bootstrapSkipReason {
  if (!File(_cacheFile).existsSync()) {
    return 'Bootstrap cache missing at $_cacheFile. '
        'Run `dart run test/integration/bootstrap.dart` first.';
  }
  final Uri uri;
  try {
    uri = Uri.parse(JellyfinBootstrapCache.load().baseUrl);
  } on Object {
    return 'Bootstrap cache at $_cacheFile is unreadable. '
        'Delete it and re-run `dart run test/integration/bootstrap.dart`.';
  }
  if (!_isReachable(uri.host, uri.port)) {
    return 'Jellyfin at ${uri.host}:${uri.port} is not reachable, but '
        '$_cacheFile still exists — the stack is probably down. '
        'Run `dart run test/integration/bootstrap.dart` to bring it '
        'back up, or delete the cache to skip these tests.';
  }
  return null;
}

/// Synchronous TCP reachability probe. Returns `false` on any socket
/// error — the caller only needs "can these tests talk to a server",
/// and every failure mode has the same answer.
bool _isReachable(String host, int port) {
  try {
    RawSynchronousSocket.connectSync(host, port).closeSync();
    return true;
  } on SocketException {
    return false;
  }
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
