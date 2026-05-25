// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Lightweight watchdog that detects drift between the pinned
/// Jellyfin OpenAPI spec in `docs/jellyfin-openapi-stable.json` and
/// the upstream copy at <https://api.jellyfin.org>.
///
/// Used by `test/spec_drift_watchdog_test.dart`. Always informational
/// — never fails, only prints a human-readable summary. Uses a 24h
/// on-disk cache (`test/.spec_cache/`) so repeated runs don't hammer
/// the network.

const String _upstreamUrl =
    'https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json';
const String _pinnedPath = 'docs/jellyfin-openapi-stable.json';
const String _cacheDir = 'test/.spec_cache';
const Duration _cacheTtl = Duration(hours: 24);

class _Endpoint {
  final String method;
  final String path;
  final String? operationId;
  const _Endpoint(this.method, this.path, this.operationId);
  String get signature => '$method $path';
}

class JellyfinSpecDriftReport {
  final int pinnedCount;
  final int latestCount;
  /// Formatted lines like `"POST /Items/{id}/Refresh  (RefreshItem)"`.
  final List<String> added;

  /// Formatted lines like `"GET /Items/{id}/Old  (GetOldThing)"`.
  final List<String> removed;
  final bool fromCache;

  const JellyfinSpecDriftReport({
    required this.pinnedCount,
    required this.latestCount,
    required this.added,
    required this.removed,
    required this.fromCache,
  });

  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty;

  String render() {
    final buf = StringBuffer();
    if (!hasChanges) {
      buf.writeln(
        '✓ dart_jellyfin spec is up to date '
        '(${fromCache ? 'cached' : 'fetched'}, $pinnedCount ops)',
      );
      return buf.toString();
    }
    buf
      ..writeln('')
      ..writeln('━━━ Upstream Jellyfin spec drift ━━━')
      ..writeln('  Pinned: $_pinnedPath ($pinnedCount ops)')
      ..writeln('  Latest: ${fromCache ? 'cache' : 'fresh'} ($latestCount ops)');
    if (added.isNotEmpty) {
      buf.writeln('  + ${added.length} new endpoint${added.length == 1 ? '' : 's'}:');
      for (final line in added.take(20)) {
        buf.writeln('      $line');
      }
      if (added.length > 20) {
        buf.writeln('      ... and ${added.length - 20} more');
      }
    }
    if (removed.isNotEmpty) {
      buf.writeln('  - ${removed.length} removed endpoint${removed.length == 1 ? '' : 's'}:');
      for (final line in removed.take(20)) {
        buf.writeln('      $line');
      }
      if (removed.length > 20) {
        buf.writeln('      ... and ${removed.length - 20} more');
      }
    }
    buf
      ..writeln('  → Refresh the pinned spec, review the diff, update wrappers.')
      ..writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      ..writeln('');
    return buf.toString();
  }
}

Future<JellyfinSpecDriftReport> runJellyfinSpecWatchdog({
  bool force = false,
}) async {
  final cacheFile = File('$_cacheDir/jellyfin.cache');
  final stampFile = File('$_cacheDir/jellyfin.stamp');

  String? latestRaw;
  var fromCache = false;

  final cacheFresh = !force && _isCacheFresh(stampFile);
  if (cacheFresh && cacheFile.existsSync()) {
    latestRaw = await cacheFile.readAsString();
    fromCache = true;
  } else {
    try {
      final res = await http
          .get(Uri.parse(_upstreamUrl))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        latestRaw = res.body;
        await Directory(_cacheDir).create(recursive: true);
        await cacheFile.writeAsString(latestRaw);
        await stampFile.writeAsString(
          DateTime.now().toUtc().toIso8601String(),
        );
      } else if (cacheFile.existsSync()) {
        latestRaw = await cacheFile.readAsString();
        fromCache = true;
      }
    } catch (_) {
      if (cacheFile.existsSync()) {
        latestRaw = await cacheFile.readAsString();
        fromCache = true;
      }
    }
  }

  final pinnedRaw = await File(_pinnedPath).readAsString();
  final pinned = _parseEndpoints(pinnedRaw);
  final latest = latestRaw == null ? <_Endpoint>{} : _parseEndpoints(latestRaw);

  final pinnedSet = pinned.map((e) => e.signature).toSet();
  final latestSet = latest.map((e) => e.signature).toSet();

  return JellyfinSpecDriftReport(
    pinnedCount: pinned.length,
    latestCount: latest.length,
    added: latest
        .where((e) => !pinnedSet.contains(e.signature))
        .map(_formatEndpoint)
        .toList(),
    removed: pinned
        .where((e) => !latestSet.contains(e.signature))
        .map(_formatEndpoint)
        .toList(),
    fromCache: fromCache,
  );
}

String _formatEndpoint(_Endpoint e) =>
    '${e.method.padRight(6)} ${e.path}'
    '${e.operationId == null ? '' : '  (${e.operationId})'}';

bool _isCacheFresh(File stampFile) {
  if (!stampFile.existsSync()) return false;
  try {
    final stamp = DateTime.parse(stampFile.readAsStringSync());
    return DateTime.now().toUtc().difference(stamp) < _cacheTtl;
  } catch (_) {
    return false;
  }
}

Set<_Endpoint> _parseEndpoints(String raw) {
  final Object? decoded = jsonDecode(raw);
  if (decoded is! Map) return const {};
  final paths = decoded['paths'];
  if (paths is! Map) return const {};
  final out = <_Endpoint>{};
  paths.forEach((path, ops) {
    if (path is! String || ops is! Map) return;
    ops.forEach((method, op) {
      if (method is! String) return;
      final m = method.toLowerCase();
      if (!{'get', 'post', 'put', 'delete', 'patch'}.contains(m)) return;
      String? opId;
      if (op is Map && op['operationId'] is String) {
        opId = op['operationId'] as String;
      }
      out.add(_Endpoint(m.toUpperCase(), path, opId));
    });
  });
  return out;
}
