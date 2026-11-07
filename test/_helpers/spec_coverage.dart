// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Compute approximate static coverage of the pinned Jellyfin spec
/// by the library's typed wrappers. Returns `(matched, total)` where
/// `matched` is the count of spec paths whose canonical form appears
/// in a `lib/src/api/*.dart` string literal or opens a doc comment.
///
/// This is INFORMATIONAL, not a strict conformance check; the contract
/// test (`spec_contract_test.dart`) checks every request a wrapper sends,
/// and the integration tests in `test/integration/` exercise the library
/// against a real Jellyfin running in Docker. Two sources count:
///
/// * a string literal holding a path, also after an interpolated base
///   (`'${_requireBaseUrl()}/Videos/$itemId/Trickplay/…'`, `'$base/…'`);
/// * a doc comment whose first word is the route in backticks
///   (`` /// `GET /Genres/{name}/Images/{imageType}[/{imageIndex}]` — … ``),
///   for builders whose path is assembled from parts. Every backticked
///   route on that line counts, and a `[…]` part stands for the route
///   with and without it. A route merely named in prose does not count.
///
/// Minimum acceptable ratio of pinned-spec paths referenced by the typed
/// wrappers. Enforced by `spec_drift_watchdog_test.dart`: a drop below this
/// fails the suite, flagging that typed API wrappers may have been removed.
/// Measured on 12.4 with 0.4.0: 284 of 294 paths (0.966). The ten left
/// are the obsolete routes the package dropped: `/Artists`,
/// `/Artists/{name}`, `/Artists/AlbumArtists`, `/MusicGenres/{genreName}`,
/// the two `/MusicGenres` instant mixes, the three `/Startup`
/// configuration routes and `/Trailers`. Lower it only after confirming
/// the wrappers were intentionally removed.
const double jellyfinLocalCoverageFloor = 0.96;

({int matched, int total}) computeJellyfinLocalCoverage() {
  final specRaw = File('docs/jellyfin-openapi-stable.json').readAsStringSync();
  final spec = jsonDecode(specRaw);
  if (spec is! Map) return (matched: 0, total: 0);
  final paths = spec['paths'];
  if (paths is! Map) return (matched: 0, total: 0);

  final specPaths = <String>{};
  paths.forEach((path, ops) {
    if (path is! String || ops is! Map) return;
    for (final method in ops.keys) {
      if (method is String &&
          {
            'get',
            'post',
            'put',
            'delete',
            'patch',
          }.contains(method.toLowerCase())) {
        specPaths.add(path);
      }
    }
  });

  final libCanon = _scanLibraryPaths('lib/src/api');

  var matched = 0;
  for (final p in specPaths) {
    if (libCanon.contains(_canonicalize(p))) matched++;
  }
  return (matched: matched, total: specPaths.length);
}

Set<String> _scanLibraryPaths(String dir) {
  final out = <String>{};
  final root = Directory(dir);
  if (!root.existsSync()) return out;
  // A path literal, possibly after an interpolated base URL.
  final literal = RegExp(r'''['"](?:\$\{[^}]*\}|\$\w+)?(\/[^'"\n]*)['"]''');
  // A doc line that opens with a route in backticks.
  final docLine = RegExp(r'^\s*///\s*`(?:GET|POST|PUT|DELETE|PATCH)\s+\/');
  final docRoute = RegExp(r'`(?:GET|POST|PUT|DELETE|PATCH)\s+(\/[^\s`]+)`');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    for (final m in literal.allMatches(content)) {
      final raw = m.group(1)!;
      if (raw.isEmpty) continue;
      out.add(_canonicalize(raw.split('?').first));
    }
    for (final line in content.split('\n')) {
      if (!docLine.hasMatch(line)) continue;
      for (final m in docRoute.allMatches(line)) {
        for (final p in _expandOptional(m.group(1)!.split('?').first)) {
          out.add(_canonicalize(p));
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

String _canonicalize(String path) {
  var r = path;
  r = r.replaceAll(RegExp(r'\$\{[^}]+\}'), '<P>');
  r = r.replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '<P>');
  r = r.replaceAll(RegExp(r'\{[^/}]+\}'), '<P>');
  r = r.replaceAll(RegExp(r'(<P>)+'), '<P>');
  return r.toLowerCase();
}
