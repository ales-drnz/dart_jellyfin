// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dart_jellyfin/src/jellyfin_connection.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

const _credentials = JellyfinCredentials(
  client: 'TestApp',
  device: 'TestDevice',
  deviceId: 'test-device',
  version: '1.0.0',
);

void main() {
  group('response decoding', () {
    test('the default transport decodes large bodies off-isolate', () {
      final transformer = JellyfinConnection(
        credentials: _credentials,
      ).transformer;

      expect(transformer, isA<FusedTransformer>());
      expect(
        (transformer as FusedTransformer).contentLengthIsolateThreshold,
        JellyfinConnection.jsonIsolateThreshold,
      );
      expect(JellyfinConnection.jsonIsolateThreshold, greaterThan(0));
    });

    test('an injected Dio keeps its own transformer', () {
      final dio = Dio();
      final mine = dio.transformer;
      final connection = JellyfinConnection(
        credentials: _credentials,
        dio: dio,
      );

      expect(identical(connection.transformer, mine), isTrue);
    });
  });
}
