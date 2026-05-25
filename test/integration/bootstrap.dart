// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Integration test bootstrap for dart_jellyfin.
///
/// Run from the library root:
///
///     dart run test/integration/bootstrap.dart
///
/// What it does (idempotent — safe to re-run any time):
/// 1. Reads `test/integration/.env.test`.
/// 2. Generates a minimal royalty-free seed library in
///    `test/integration/seed/jellyfin/` (silence MP3s + a 5s blue
///    video) via `ffmpeg`. If `ffmpeg` is not on PATH, skips this
///    step and warns — most integration tests still work against an
///    empty library.
/// 3. Brings up the docker-compose stack with
///    `docker compose up -d --wait`.
/// 4. If the Jellyfin first-run wizard has not been completed yet,
///    drives it through the typed `startup` sub-API.
/// 5. Authenticates as the test admin user and creates a "Music"
///    library if none exists yet.
/// 6. Triggers a library scan and waits for it to finish.
/// 7. Writes a JSON bootstrap cache to
///    `test/integration/.bootstrap-cache.json` that integration
///    tests pick up via [bootstrapCache] in their fixtures.
///
/// The cache file is gitignored (see `.gitignore` at the library
/// root). Tearing the stack down with `docker compose down` keeps
/// the volumes; `docker compose down -v` wipes them so the next
/// bootstrap rebuilds from scratch.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:http/http.dart' as http;

const String _integrationDir = 'test/integration';
const String _envFile = '$_integrationDir/.env.test';
const String _composeFile = '$_integrationDir/docker-compose.yml';
const String _seedDir = '$_integrationDir/seed/jellyfin';
const String _cacheFile = '$_integrationDir/.bootstrap-cache.json';

Future<void> main(List<String> args) async {
  final force = args.contains('--force') || args.contains('-f');

  _section('dart_jellyfin integration bootstrap');

  final env = _loadEnv(_envFile);
  final username = env['JELLYFIN_TEST_USERNAME'] ?? 'test_admin';
  final password = env['JELLYFIN_TEST_PASSWORD'] ?? 'test_password';
  final hostPort = int.tryParse(env['JELLYFIN_HOST_PORT'] ?? '') ?? 18096;
  final baseUrl = 'http://127.0.0.1:$hostPort';

  // 1. Seed media
  _step('Preparing seed media in $_seedDir/');
  await _ensureSeedMedia(_seedDir, force: force);

  // 2. Docker stack
  _step(
      'Starting Docker stack (Jellyfin ${env['JELLYFIN_IMAGE_TAG'] ?? '10.11.9'})');
  await _composeUp();

  // 3. Wait for HTTP
  _step('Waiting for $baseUrl to respond');
  await _waitForHttp('$baseUrl/System/Info/Public');

  // 4. First-run wizard
  final client = JellyfinClient(
    baseUrl: baseUrl,
    credentials: const JellyfinCredentials(
      client: 'dart_jellyfin_bootstrap',
      device: 'bootstrap',
      deviceId: 'bootstrap-dart-jellyfin',
      version: '0.0.1',
    ),
  );
  final publicInfo = await client.system.publicInfo();
  if (publicInfo.raw['StartupWizardCompleted'] != true) {
    _step('Running first-run wizard (admin: $username)');
    await _runFirstRunWizard(client, username, password);
  } else {
    _step('First-run wizard already complete (using existing volume)');
  }

  // 5. Authenticate
  _step('Authenticating as $username');
  final auth = await client.user.authenticateByName(
    username: username,
    password: password,
  );
  client.setSession(token: auth.accessToken, userId: auth.user.id);
  print('   ✓ Authenticated as ${auth.user.name} (id=${auth.user.id})');

  // 6. Ensure Music library
  _step('Ensuring "Music" library exists');
  final views = await client.library.userViews();
  if (views.any((v) => v.name == 'Music')) {
    print('   ✓ Music library already configured');
  } else {
    print('   ▶ Adding Music library');
    await client.libraryStructure.add(
      name: 'Music',
      collectionType: 'music',
      paths: const ['/media/Music'],
      refreshLibrary: true,
    );
    _step('Scanning library');
    await _waitForScan(client);
  }

  // 7. Cache
  _step('Saving bootstrap cache to $_cacheFile');
  await File(_cacheFile).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'baseUrl': baseUrl,
      'token': auth.accessToken,
      'userId': auth.user.id,
      'username': username,
      'serverName': publicInfo.serverName,
      'serverId': publicInfo.id,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    }),
  );

  _section('Bootstrap complete');
  print('Run integration tests with:');
  print('  dart test --tags integration');
}

// ─── Steps ──────────────────────────────────────────────────────────

Future<void> _ensureSeedMedia(String dir, {required bool force}) async {
  final root = Directory(dir);
  if (root.existsSync() && !force) {
    final existing = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _mediaExts.any((e) => f.path.endsWith(e)))
        .length;
    if (existing > 0) {
      print('   ✓ Seed media already present ($existing files)');
      return;
    }
  }
  await root.create(recursive: true);

  final hasFfmpeg = await _hasCommand('ffmpeg');
  if (!hasFfmpeg) {
    print('   ⚠ ffmpeg not on PATH — skipping seed generation.');
    print('     Integration tests will run against an empty library.');
    print('     Install ffmpeg to enable full-fidelity seed.');
    return;
  }

  final musicDir = '$dir/Music/Test Artist/Test Album';
  await Directory(musicDir).create(recursive: true);
  print('   ▶ ffmpeg: generating 3 silence MP3s');
  for (var i = 1; i <= 3; i++) {
    final path = '$musicDir/${i.toString().padLeft(2, '0')} - Track $i.mp3';
    final r = await Process.run('ffmpeg', [
      '-y',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'anullsrc=channel_layout=stereo:sample_rate=44100',
      '-t',
      '3',
      '-c:a',
      'libmp3lame',
      '-b:a',
      '128k',
      '-metadata',
      'title=Track $i',
      '-metadata',
      'artist=Test Artist',
      '-metadata',
      'album=Test Album',
      '-metadata',
      'track=$i',
      '-metadata',
      'date=2020',
      path,
    ]);
    if (r.exitCode != 0) {
      print('     ✗ ffmpeg failed for $path: ${r.stderr}');
    }
  }

  final movieDir = '$dir/Movies/Test Movie (2020)';
  await Directory(movieDir).create(recursive: true);
  print('   ▶ ffmpeg: generating 5s blue video');
  final mvR = await Process.run('ffmpeg', [
    '-y',
    '-loglevel',
    'error',
    '-f',
    'lavfi',
    '-i',
    'color=c=blue:s=320x240:d=5:r=24',
    '-c:v',
    'libx264',
    '-pix_fmt',
    'yuv420p',
    '$movieDir/Test Movie (2020).mp4',
  ]);
  if (mvR.exitCode != 0) {
    print('     ✗ ffmpeg failed for movie: ${mvR.stderr}');
  }
  print('   ✓ Seed media generated');
}

Future<void> _composeUp() async {
  // `--wait` blocks until every service's healthcheck reports
  // healthy, or the start_period timeout elapses.
  final r = await Process.run(
    'docker',
    [
      'compose',
      '--env-file',
      _envFile,
      '-f',
      _composeFile,
      'up',
      '-d',
      '--wait',
    ],
    workingDirectory: Directory.current.path,
  );
  if (r.exitCode != 0) {
    stderr.writeln('docker compose up failed:');
    stderr.writeln(r.stdout);
    stderr.writeln(r.stderr);
    exit(1);
  }
}

Future<void> _waitForHttp(String url, {int maxSeconds = 120}) async {
  final deadline = DateTime.now().add(Duration(seconds: maxSeconds));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final res = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 3),
          );
      if (res.statusCode == 200) {
        print('   ✓ Server reachable');
        return;
      }
    } catch (_) {
      // not yet — keep polling
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw StateError('Timed out waiting for $url after ${maxSeconds}s');
}

Future<void> _runFirstRunWizard(
  JellyfinClient client,
  String username,
  String password,
) async {
  // The Jellyfin Web wizard steps in this order:
  //   configuration → user → remote access → complete
  // Re-ordering causes the server to reject later POSTs.
  print('   ▶ /Startup/Configuration');
  await client.startup.updateInitialConfiguration({
    'UICulture': 'en-US',
    'MetadataCountryCode': 'US',
    'PreferredMetadataLanguage': 'en',
  });
  // The server tracks the wizard step server-side. Doing a GET on
  // /Startup/User first advances the state machine, after which the
  // POST is accepted; without the GET it returns 404.
  await client.startup.firstUser();
  print('   ▶ /Startup/User');
  await client.startup.updateStartupUser(
    name: username,
    password: password,
  );
  print('   ▶ /Startup/RemoteAccess');
  await client.startup.setRemoteAccess({
    'EnableRemoteAccess': false,
    'EnableAutomaticPortMapping': false,
  });
  print('   ▶ /Startup/Complete');
  await client.startup.completeWizard();
  print('   ✓ Wizard complete');
}

Future<void> _waitForScan(
  JellyfinClient client, {
  int maxSeconds = 60,
}) async {
  final deadline = DateTime.now().add(Duration(seconds: maxSeconds));
  var lastCount = -1;
  var stableTicks = 0;
  while (DateTime.now().isBefore(deadline)) {
    final count = await client.items.count(
      includeItemTypes: const ['Audio'],
    );
    if (count != lastCount) {
      lastCount = count;
      stableTicks = 0;
    } else {
      stableTicks++;
    }
    // 3 consecutive stable polls = scan settled.
    if (count > 0 && stableTicks >= 3) {
      print('   ✓ Scan settled with $count audio items');
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  print('   ⚠ Scan didn\'t settle within ${maxSeconds}s — '
      'final count: $lastCount audio items');
}

// ─── Helpers ────────────────────────────────────────────────────────

const Set<String> _mediaExts = {
  '.mp3',
  '.flac',
  '.m4a',
  '.ogg',
  '.wav',
  '.aac',
  '.mp4',
  '.mkv',
  '.mov',
  '.avi',
  '.webm',
};

Map<String, String> _loadEnv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path. Copy .env.test.example to .env.test first.');
    exit(2);
  }
  final out = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq < 0) continue;
    out[line.substring(0, eq).trim()] = line.substring(eq + 1).trim();
  }
  return out;
}

Future<bool> _hasCommand(String cmd) async {
  try {
    final probe = Platform.isWindows ? 'where' : 'which';
    final r = await Process.run(probe, [cmd]);
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}

void _section(String title) {
  print('');
  print('━━━ $title ━━━');
  print('');
}

void _step(String msg) {
  print('▶ $msg');
}
