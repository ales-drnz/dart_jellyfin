// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Regression tests for the sub-API fixes of 0.4.2: what goes on the wire
/// and what comes back, through a capturing `http.Client`.
library;

import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient jf;

  setUp(() {
    adapter = CapturingAdapter();
    jf = capturingClient(adapter);
  });

  group('mediaInfo.bitrateTestBytesLength', () {
    test('reads the octet-stream body as bytes', () async {
      adapter.respond = (_) => CannedResponse(
        200,
        Uint8List(2048),
        contentType: 'application/octet-stream',
      );
      expect(await jf.mediaInfo.bitrateTestBytesLength(size: 2048), 2048);
      expect(adapter.path, '/Playback/BitrateTest');
      expect(adapter.query['size'], ['2048']);
    });
  });
}
