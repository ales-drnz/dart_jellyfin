// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Smoke-test driver for dart_jellyfin.
//
//   dart run example/jellyfin_example.dart \
//     --baseUrl=https://jellyfin.example.com \
//     --username=you --password=hunter2

import 'package:dart_jellyfin/dart_jellyfin.dart';

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final baseUrl = flags['baseUrl'];
  if (baseUrl == null) {
    print('Pass --baseUrl=<your-jellyfin-url>');
    return;
  }

  final jf = JellyfinClient(
    baseUrl: baseUrl,
    credentials: const JellyfinCredentials(
      client: 'dart_jellyfin example',
      device: 'CLI',
      deviceId: 'dart_jellyfin-example-uuid',
      version: '0.0.1',
    ),
  );

  print('Public system info:');
  print('  ${(await jf.system.publicInfo()).raw}');

  if (flags['username'] == null) {
    print('No --username — stopping here.');
    return;
  }
  print('\nAuthenticating…');
  final auth = await jf.user.authenticateByName(
    username: flags['username']!,
    password: flags['password'] ?? '',
  );
  jf.setSession(token: auth.accessToken, userId: auth.user.id);
  print('Hello ${auth.user.name} (server ${auth.serverId}).');

  print('\nLibraries:');
  final views = await jf.library.userViews();
  for (final v in views) {
    print('  [${v.collectionType ?? '?'}] ${v.name}  (id=${v.id})');
  }

  final music = views.where((v) => v.isMusic).toList();
  if (music.isEmpty) {
    print('No music library on this server.');
    return;
  }
  final lib = music.first;
  print('\nFirst 5 albums in "${lib.name}":');
  final albums = await jf.items.list(
    parentId: lib.id,
    includeItemTypes: const [JellyfinItemKind.musicAlbum],
    sortBy: const ['SortName'],
    limit: 5,
  );
  for (final a in albums.items) {
    print('  ${a.name} — ${a.albumArtist ?? '?'}');
  }
  print('(total in library: ${albums.totalRecordCount})');
}

Map<String, String> _parseFlags(List<String> args) {
  final out = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) continue;
    final eq = a.indexOf('=');
    if (eq < 0) continue;
    out[a.substring(2, eq)] = a.substring(eq + 1);
  }
  return out;
}
