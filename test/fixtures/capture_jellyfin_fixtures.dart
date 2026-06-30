// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Captures real JSON responses from a running Jellyfin server into
/// `test/fixtures/captured/` so we can hand-craft committable fixtures
/// for the field-level DTO tests.
///
/// Usage:
///   1. Run `bootstrap.dart` first (so the cache is populated).
///   2. `dart run test/fixtures/capture_jellyfin_fixtures.dart`
///
/// Output is gitignored — the captured payloads carry server-local ids
/// that aren't useful in shared fixtures. The point of this script is
/// to inspect real shapes; the actual unit-test fixtures get written
/// by hand against the captured JSON.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

const _cachePath = 'test/integration/.bootstrap-cache.json';
const _outDir = 'test/fixtures/captured';

Future<void> main() async {
  if (!File(_cachePath).existsSync()) {
    stderr.writeln(
      'Bootstrap cache missing — run `dart run test/integration/bootstrap.dart` first.',
    );
    exit(1);
  }
  final cache =
      jsonDecode(File(_cachePath).readAsStringSync()) as Map<String, dynamic>;
  final baseUrl = cache['baseUrl'] as String;
  final token = cache['token'] as String;
  final userId = cache['userId'] as String;

  final dio = Dio()
    ..options.headers['Accept'] = 'application/json'
    ..options.headers['Authorization'] = 'MediaBrowser '
        'Client="dart_jellyfin_capture", '
        'Device="capture-tool", '
        'DeviceId="dart-jellyfin-capture", '
        'Version="0.0.1", '
        'Token="$token"';

  Directory(_outDir).createSync(recursive: true);

  Future<void> get(
    String name,
    String path, [
    Map<String, dynamic>? qp,
  ]) async {
    try {
      final res = await dio.get<dynamic>('$baseUrl$path', queryParameters: qp);
      _save(name, res.data);
    } on DioException catch (e) {
      stderr.writeln('  ✗ $name ($path) — ${e.response?.statusCode}');
    }
  }

  await get(
    'items_list_audio.json',
    '/Items',
    {
      'userId': userId,
      'IncludeItemTypes': 'Audio',
      'Recursive': 'true',
      'Limit': 3,
      'Fields': 'MediaSources,MediaStreams,Genres,Tags,ProviderIds',
    },
  );
  await get('user_views.json', '/UserViews', {'userId': userId});
  await get(
    'search_hints.json',
    '/Search/Hints',
    {'userId': userId, 'searchTerm': 'Track', 'Limit': 5},
  );
  await get(
    'filters2.json',
    '/Items/Filters2',
    {'userId': userId, 'IncludeItemTypes': 'Audio'},
  );
  await get(
    'display_preferences.json',
    '/DisplayPreferences/usersettings',
    {'userId': userId, 'client': 'dart_jellyfin_capture'},
  );
  await get('system_info.json', '/System/Info');
  await get('system_public_info.json', '/System/Info/Public');
  await get('sessions.json', '/Sessions');

  // Now hit per-item endpoints using the first audio track.
  final tracksRes = await dio.get<Map<String, dynamic>>(
    '$baseUrl/Items',
    queryParameters: {
      'userId': userId,
      'IncludeItemTypes': 'Audio',
      'Recursive': 'true',
      'Limit': 1,
    },
  );
  final firstItem =
      (tracksRes.data?['Items'] as List?)?.first as Map<String, dynamic>?;
  if (firstItem != null) {
    final id = firstItem['Id'] as String;
    await get('items_by_id_audio.json', '/Items/$id', {
      'userId': userId,
      'Fields':
          'MediaSources,MediaStreams,Genres,Tags,ProviderIds,ParentId,People',
    });
    try {
      final pi = await dio.post<Map<String, dynamic>>(
        '$baseUrl/Items/$id/PlaybackInfo',
        queryParameters: {'userId': userId},
        data: {
          'UserId': userId,
          'DeviceProfile': {
            'Name': 'capture',
            'MaxStreamingBitrate': 140000000,
            'CodecProfiles': <Map<String, dynamic>>[],
            'DirectPlayProfiles': [
              {'Container': 'mp3', 'Type': 'Audio'},
            ],
            'TranscodingProfiles': <Map<String, dynamic>>[],
          },
        },
      );
      _save('playback_info.json', pi.data);
    } on DioException catch (e) {
      stderr.writeln('  ✗ playback_info.json — ${e.response?.statusCode}');
    }
    await get('user_data.json', '/UserItems/$id/UserData');
    await get('media_segments.json', '/MediaSegments/$id');
    await get('lyrics.json', '/Audio/$id/Lyrics');
  }

  stdout.writeln('Captured ${Directory(_outDir).listSync().length} fixtures '
      'to $_outDir/');
}

void _save(String name, dynamic data) {
  File('$_outDir/$name').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(data),
  );
  stdout.writeln('  ✓ $name');
}
