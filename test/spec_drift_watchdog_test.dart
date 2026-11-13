// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '_helpers/spec_coverage.dart';
import '_helpers/spec_watchdog.dart';

/// Two checks on the pinned Jellyfin OpenAPI document
/// (`docs/jellyfin-openapi-stable.json`):
///
/// 1. **Local coverage**, on every `dart test`, offline: how many of its
///    operations the typed wrappers in `lib/src/api/` reference. A drop
///    below [jellyfinLocalCoverageFloor] fails: a wrapper went missing.
/// 2. **Upstream drift**, tagged `network` and skipped by default: fetches
///    the latest document from api.jellyfin.org and prints the operations
///    added or removed since the pinned one. Run it with
///    `dart test -P network test/spec_drift_watchdog_test.dart`; CI does on
///    a schedule.
///    Informational: drift is printed, not failed on.
void main() {
  test('local coverage of the pinned spec does not drop', () {
    final cov = computeJellyfinLocalCoverage();
    // ignore: avoid_print
    print(
      'ℹ Local static coverage: ${cov.matched}/${cov.total} spec '
      'operations referenced in lib/src/api/ (approximate). Not '
      'referenced: ${jellyfinUncoveredOperations().join(', ')}',
    );

    // The pinned document is read from disk. Far fewer operations than
    // it holds means it is truncated or its structure changed.
    expect(
      cov.total,
      greaterThan(300),
      reason: 'the pinned Jellyfin spec parsed to too few operations',
    );
    expect(
      cov.matched,
      greaterThanOrEqualTo(jellyfinLocalCoverageFloor),
      reason:
          'local static coverage (${cov.matched}/${cov.total}) fell below '
          'the measured $jellyfinLocalCoverageFloor: a typed wrapper may '
          'have been removed. If that was intended, update '
          'jellyfinLocalCoverageFloor in test/_helpers/spec_coverage.dart',
    );
  });

  test(
    'upstream Jellyfin spec drift (informational)',
    () async {
      final report = await runJellyfinSpecWatchdog();
      // ignore: avoid_print
      print(report.render());
      expect(report.pinnedCount, greaterThan(300));
    },
    tags: 'network',
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
