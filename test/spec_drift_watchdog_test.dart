// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '_helpers/spec_coverage.dart';
import '_helpers/spec_watchdog.dart';

/// Two informational checks that run on every `dart test`:
///
/// 1. **Upstream drift**: compare the pinned Jellyfin OpenAPI spec
///    against `api.jellyfin.org`. Reports added/removed endpoints.
/// 2. **Local coverage**: approximate static count of how many spec
///    paths the library references in `lib/src/api/`. Lossy by
///    design — a sudden drop is the signal worth investigating.
///
/// Both always pass. Real correctness is enforced by the integration
/// tests in `test/integration/`, which exercise the library against
/// a real Jellyfin server in Docker.
void main() {
  test(
    'upstream Jellyfin spec drift + local coverage (informational)',
    () async {
      final report = await runJellyfinSpecWatchdog();
      // ignore: avoid_print
      print(report.render());

      final cov = computeJellyfinLocalCoverage();
      final pct = cov.total == 0 ? 0 : (cov.matched * 100 / cov.total);
      // ignore: avoid_print
      print(
        'ℹ Local static coverage: ${cov.matched}/${cov.total} spec paths '
        'referenced in lib/src/api/ (~${pct.toStringAsFixed(0)}%, approximate)',
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
