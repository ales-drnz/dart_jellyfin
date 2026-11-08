// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Minimum share of the pinned spec's operations the typed wrappers
/// reference. Enforced by `spec_drift_watchdog_test.dart`: a drop below
/// it fails the suite, flagging that typed wrappers may have been removed.
///
/// Measured on 12.4 with 0.4.1: 331 of 346 operations (0.957). The 15
/// left, as [jellyfinUncoveredOperations] lists them:
///
/// * the obsolete routes the package dropped: `GET /Artists/{name}`,
///   `/MusicGenres/{genreName}`, the two `/MusicGenres` instant mixes,
///   `/Trailers`, `GET` and `POST /Startup/Configuration`,
///   `POST /Startup/RemoteAccess`, and `GET /Startup/FirstUser`, the
///   wizard's first-user read;
/// * routes never wrapped: `GET` and `POST /LiveTv/Timers/{timerId}` and
///   `/LiveTv/SeriesTimers/{timerId}`, `POST /LiveTv/Programs` and
///   `GET /Playlists/{playlistId}`.
///
/// Lower it only after confirming the wrappers were removed on purpose.
const double jellyfinLocalCoverageFloor = 0.95;

/// Approximate static coverage of the pinned Jellyfin spec by the typed
/// wrappers, as `(matched, total)` operations. An operation is a method
/// and a path.
///
/// INFORMATIONAL, not a conformance check: the contract test
/// (`spec_contract_test.dart`) checks every request a wrapper sends, and
/// `test/integration/` runs the package against a real Jellyfin. An
/// operation counts when `lib/src/api/*.dart` has:
///
/// * a path in a string literal, also after an interpolated base
///   (`'$base/Videos/$itemId/Trickplay/…'`), outside comments. Its method
///   is the `method:` argument of the same statement, else `GET`;
/// * a doc comment whose first word is the route in backticks, for
///   builders whose path is assembled from parts:
///   `` /// `GET /Genres/{name}/Images/{type}[/{index}]` — … ``.
///   Every backticked route on that line counts, and a `[…]` part stands
///   for the route with and without it. A route named in prose does not.
({int matched, int total}) computeJellyfinLocalCoverage() {
  final spec = _specOperations();
  final lib = _scanLibraryOperations('lib/src/api');
  final matched = spec.where((op) => lib.contains(_canonical(op))).length;
  return (matched: matched, total: spec.length);
}

/// The spec operations no wrapper references, as `METHOD /path`.
List<String> jellyfinUncoveredOperations() {
  final lib = _scanLibraryOperations('lib/src/api');
  return [
    for (final op in _specOperations())
      if (!lib.contains(_canonical(op))) op,
  ]..sort();
}

const _methods = {'GET', 'POST', 'PUT', 'DELETE', 'PATCH'};

Set<String> _specOperations() {
  final spec = jsonDecode(
    File('docs/jellyfin-openapi-stable.json').readAsStringSync(),
  );
  final out = <String>{};
  if (spec is! Map || spec['paths'] is! Map) return out;
  (spec['paths'] as Map).forEach((path, ops) {
    if (path is! String || ops is! Map) return;
    for (final method in ops.keys) {
      if (method is! String) continue;
      final m = method.toUpperCase();
      if (_methods.contains(m)) out.add('$m $path');
    }
  });
  return out;
}

Set<String> _scanLibraryOperations(String dir) {
  final out = <String>{};
  final root = Directory(dir);
  if (!root.existsSync()) return out;
  // A path literal, possibly after an interpolated base URL.
  final literal = RegExp(r'''['"](?:\$\{[^}]*\}|\$\w+)?(\/[^'"\n]*)['"]''');
  final method = RegExp(r'''method:\s*['"](\w+)['"]''');
  // A doc line that opens with a route in backticks.
  final docLine = RegExp(r'^\s*///\s*`(?:GET|POST|PUT|DELETE|PATCH)\s+\/');
  final docRoute = RegExp(r'`(GET|POST|PUT|DELETE|PATCH)\s+(\/[^\s`]+)`');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final lines = entity.readAsLinesSync();
    // The code without its comment lines, which only the doc rule reads.
    final code = [
      for (final l in lines) l.trimLeft().startsWith('//') ? '' : l,
    ].join('\n');
    for (final m in literal.allMatches(code)) {
      final path = m.group(1)!;
      if (path.isEmpty) continue;
      final end = code.indexOf(';', m.end);
      final statement = code.substring(m.end, end < 0 ? code.length : end);
      final verb = method.firstMatch(statement)?.group(1) ?? 'GET';
      out.add(_canonical('$verb ${path.split('?').first}'));
    }
    for (final line in lines) {
      if (!docLine.hasMatch(line)) continue;
      for (final m in docRoute.allMatches(line)) {
        for (final p in _expandOptional(m.group(2)!.split('?').first)) {
          out.add(_canonical('${m.group(1)} $p'));
        }
      }
    }
  }
  return out;
}

/// `/a[/{b}]` → `/a` and `/a/{b}`.
Iterable<String> _expandOptional(String path) sync* {
  final m = RegExp(r'\[([^\[\]]*)\]').firstMatch(path);
  if (m == null) {
    yield path;
    return;
  }
  final before = path.substring(0, m.start);
  final after = path.substring(m.end);
  yield* _expandOptional('$before$after');
  yield* _expandOptional('$before${m.group(1)}$after');
}

String _canonical(String op) {
  var r = op;
  r = r.replaceAll(RegExp(r'\$\{[^}]+\}'), '<P>');
  r = r.replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '<P>');
  r = r.replaceAll(RegExp(r'\{[^/}]+\}'), '<P>');
  r = r.replaceAll(RegExp(r'(<P>)+'), '<P>');
  return r.toLowerCase();
}
