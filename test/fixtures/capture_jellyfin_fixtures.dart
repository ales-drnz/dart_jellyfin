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

import 'package:http/http.dart' as http;

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

  final headers = {
    'Accept': 'application/json',
    'Authorization': 'MediaBrowser '
        'Client="dart_jellyfin_capture", '
        'Device="capture-tool", '
        'DeviceId="dart-jellyfin-capture", '
        'Version="0.0.1", '
        'Token="$token"',
  };

  Directory(_outDir).createSync(recursive: true);

  Future<void> get(
    String name,
    String path, [
    Map<String, dynamic>? qp,
  ]) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: qp?.map((k, v) => MapEntry(k, '$v')),
    );
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) {
      stderr.writeln('  ✗ $name ($path) — ${res.statusCode}');
      return;
    }
    _save(name, jsonDecode(res.body));
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
  final tracksRes = await http.get(
    Uri.parse('$baseUrl/Items').replace(
      queryParameters: {
        'userId': userId,
        'IncludeItemTypes': 'Audio',
        'Recursive': 'true',
        'Limit': '1',
      },
    ),
    headers: headers,
  );
  final tracks = jsonDecode(tracksRes.body) as Map<String, dynamic>;
  final firstItem = (tracks['Items'] as List?)?.first as Map<String, dynamic>?;
  if (firstItem != null) {
    final id = firstItem['Id'] as String;
    await get('items_by_id_audio.json', '/Items/$id', {
      'userId': userId,
      'Fields':
          'MediaSources,MediaStreams,Genres,Tags,ProviderIds,ParentId,People',
    });
    final pi = await http.post(
      Uri.parse('$baseUrl/Items/$id/PlaybackInfo')
          .replace(queryParameters: {'userId': userId}),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
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
      }),
    );
    if (pi.statusCode == 200) {
      _save('playback_info.json', jsonDecode(pi.body));
    } else {
      stderr.writeln('  ✗ playback_info.json — ${pi.statusCode}');
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
