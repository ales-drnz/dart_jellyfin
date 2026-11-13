// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// What the sub-APIs make of an answer: each method here is given a body
/// of the shape a Jellyfin 12.4 server sends for its route — a bare list,
/// a `{Items}` page, one object, a JSON string — and must hand back the
/// typed value. The models' own fields are tested with the models.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

void main() {
  late CapturingAdapter adapter;
  late JellyfinClient jf;

  /// Answers [value] as JSON to the next requests.
  void answer(Object? value) => adapter.body = jsonEncode(value);

  Map<String, Object?> page(List<Object?> items) => {
    'Items': items,
    'TotalRecordCount': items.length,
    'StartIndex': 0,
  };

  setUp(() {
    adapter = CapturingAdapter();
    jf = capturingClient(adapter);
  });

  group('user', () {
    const user = {
      'Name': 'test_user',
      'ServerId': 'srv',
      'Id': 'u1',
      'HasPassword': true,
      'LastLoginDate': '2026-11-08T17:06:04.2882251Z',
    };

    test('authenticateByName answers the token and the user', () async {
      answer({'AccessToken': 'tok-9', 'ServerId': 'srv', 'User': user});
      final auth = await jf.user.authenticateByName(
        username: 'test_user',
        password: 'pw',
      );
      expect(auth.accessToken, 'tok-9');
      expect(auth.user.id, 'u1');
      expect(adapter.path, '/Users/AuthenticateByName');
      expect(adapter.last!.json, {'Username': 'test_user', 'Pw': 'pw'});
    });

    test('authenticateByName without a token is an auth error', () async {
      answer({'User': user});
      await expectLater(
        jf.user.authenticateByName(username: 'u', password: 'p'),
        throwsA(
          isA<JellyfinException>().having((e) => e.isAuthError, 'auth', isTrue),
        ),
      );
    });

    test('currentUser, list and publicUsers', () async {
      answer(user);
      expect((await jf.user.currentUser()).name, 'test_user');
      answer([user]);
      expect((await jf.user.list()).single.id, 'u1');
      answer(const <Object?>[]);
      expect(await jf.user.publicUsers(), isEmpty);
      expect(adapter.path, '/Users/Public');
    });

    test('byId answers null on 404', () async {
      adapter.respond = (_) => CannedResponse(404, const []);
      expect(await jf.user.byId(userId: 'gone'), isNull);
    });

    test('the provider lists and the password reset answers', () async {
      answer([
        {
          'Name': 'Default',
          'Id': 'Jellyfin.Server.DefaultAuthenticationProvider',
        },
      ]);
      expect((await jf.user.authProviders()).single.name, 'Default');
      expect((await jf.user.passwordResetProviders()).single.name, 'Default');
      answer({'Action': 'PinCode', 'PinFile': '/config/pin'});
      expect((await jf.user.forgotPassword(username: 'u')).action, 'PinCode');
      answer({
        'Success': true,
        'UsersReset': ['test_user'],
      });
      final redeemed = await jf.user.forgotPasswordPin(pin: '1234');
      expect(redeemed.success, isTrue);
      expect(redeemed.usersReset, ['test_user']);
    });
  });

  group('userData', () {
    const data = {
      'PlaybackPositionTicks': 0,
      'PlayCount': 2,
      'IsFavorite': true,
      'Played': true,
      'Key': 'k',
      'ItemId': 'i1',
    };

    test('every write answers the item\'s new user data', () async {
      answer(data);
      final calls = <(String, String, Future<JellyfinUserData>)>[
        (
          'POST',
          '/UserFavoriteItems/i1',
          jf.userData.markFavorite(itemId: 'i1'),
        ),
        (
          'DELETE',
          '/UserFavoriteItems/i1',
          jf.userData.unmarkFavorite(itemId: 'i1'),
        ),
        ('POST', '/UserPlayedItems/i1', jf.userData.markPlayed(itemId: 'i1')),
        (
          'DELETE',
          '/UserPlayedItems/i1',
          jf.userData.markUnplayed(itemId: 'i1'),
        ),
        ('GET', '/UserItems/i1/UserData', jf.userData.get(itemId: 'i1')),
        (
          'POST',
          '/UserItems/i1/Rating',
          jf.userData.rate(itemId: 'i1', likes: true),
        ),
        (
          'DELETE',
          '/UserItems/i1/Rating',
          jf.userData.clearRating(itemId: 'i1'),
        ),
      ];
      for (final (_, _, call) in calls) {
        final answered = await call;
        expect(answered.isFavorite, isTrue);
        expect(answered.playCount, 2);
      }
      expect(
        [for (final r in adapter.requests) (r.method, r.uri.path)],
        [for (final (method, path, _) in calls) (method, path)],
      );
    });

    test('setFavorite picks the method from the flag', () async {
      answer(data);
      await jf.userData.setFavorite(itemId: 'i1', isFavorite: false);
      expect(adapter.last!.method, 'DELETE');
      await jf.userData.setFavorite(itemId: 'i1', isFavorite: true);
      expect(adapter.last!.method, 'POST');
    });
  });

  group('mediaInfo', () {
    test('info and postedInfo answer the media sources', () async {
      answer({
        'MediaSources': [
          {'Id': 'ms1', 'Container': 'flac', 'Protocol': 'File'},
        ],
        'PlaySessionId': 'ps1',
      });
      final info = await jf.mediaInfo.info(itemId: 'i1');
      expect(info.playSessionId, 'ps1');
      expect(info.mediaSources.single.id, 'ms1');
      final posted = await jf.mediaInfo.postedInfo(
        itemId: 'i1',
        deviceProfile: const JellyfinDeviceProfile(),
      );
      expect(posted.mediaSources.single.container, 'flac');
      expect(adapter.last!.method, 'POST');
      expect((adapter.last!.json! as Map)['UserId'], 'user-1');
    });

    test('an error code comes through', () async {
      answer({'MediaSources': <Object?>[], 'ErrorCode': 'NoCompatibleStream'});
      expect(
        (await jf.mediaInfo.info(itemId: 'i1')).errorCode,
        'NoCompatibleStream',
      );
    });
  });

  group('quickConnect', () {
    test('enabled and authorize read a bare JSON boolean', () async {
      answer(true);
      expect(await jf.quickConnect.enabled(), isTrue);
      expect(await jf.quickConnect.authorize(code: '123456'), isTrue);
      expect(adapter.query['code'], ['123456']);
      answer(false);
      expect(await jf.quickConnect.enabled(), isFalse);
    });

    test('initiate and state answer the attempt', () async {
      answer({'Authenticated': false, 'Secret': 's3', 'Code': '123456'});
      expect((await jf.quickConnect.initiate()).code, '123456');
      answer({'Authenticated': true, 'Secret': 's3', 'Code': '123456'});
      expect((await jf.quickConnect.state(secret: 's3')).authenticated, isTrue);
      expect(adapter.query['secret'], ['s3']);
    });
  });

  group('plugins and packages', () {
    test('plugins.list is a bare list', () async {
      answer([
        {'Name': 'TMDb', 'Version': '12.4.0.0', 'Id': 'p1', 'Status': 'Active'},
      ]);
      final plugin = (await jf.plugins.list()).single;
      expect(plugin.name, 'TMDb');
      expect(plugin.version, '12.4.0.0');
    });

    test('plugins.configuration is the plugin\'s own document', () async {
      answer({
        'ApiKey': 'x',
        'Nested': {'a': 1},
      });
      expect(await jf.plugins.configuration(pluginId: 'p1'), {
        'ApiKey': 'x',
        'Nested': {'a': 1},
      });
      adapter.body = '';
      expect(await jf.plugins.configuration(pluginId: 'p1'), isEmpty);
    });

    test('plugins.manifest reads the lower-case keys', () async {
      answer({'guid': 'g1', 'name': 'TMDb', 'version': '1.0'});
      expect((await jf.plugins.manifest(pluginId: 'p1')).name, 'TMDb');
      expect(adapter.path, '/Plugins/p1/Manifest');
    });

    test('packages.list, byName and repositories', () async {
      answer([
        {'name': 'Bookshelf', 'guid': 'g2', 'versions': <Object?>[]},
      ]);
      expect((await jf.packages.list()).single.guid, 'g2');
      answer({'name': 'Open Subtitles', 'guid': 'g3'});
      expect((await jf.packages.byName(name: 'Open Subtitles')).guid, 'g3');
      expect(
        adapter.last!.uri.toString(),
        contains('/Packages/Open%20Subtitles'),
      );
      answer([
        {
          'Name': 'Jellyfin Stable',
          'Url': 'https://repo.example.test/m.json',
          'Enabled': true,
        },
      ]);
      expect((await jf.packages.repositories()).single.enabled, isTrue);
    });
  });

  group('configuration', () {
    test('get and defaultMetadataOptions', () async {
      answer({'ServerName': 'home', 'UICulture': 'en-US'});
      expect((await jf.configuration.get()).serverName, 'home');
      answer({
        'DisabledMetadataSavers': ['Nfo'],
        'LocalMetadataReaderOrder': <Object?>[],
      });
      expect(
        (await jf.configuration.defaultMetadataOptions())
            .disabledMetadataSavers,
        ['Nfo'],
      );
    });

    test('getNamed answers the named document as a map', () async {
      answer({'SplashscreenEnabled': false});
      expect(await jf.configuration.getNamed(key: 'branding'), {
        'SplashscreenEnabled': false,
      });
      expect(adapter.path, '/System/Configuration/branding');
    });
  });

  group('displayPreferences', () {
    test('get reads the document and update sends it back', () async {
      answer({
        'Id': 'usersettings',
        'SortBy': 'SortName',
        'RememberIndexing': false,
        'CustomPrefs': {'homesection0': 'resume'},
      });
      final prefs = await jf.displayPreferences.get(
        displayPreferencesId: 'usersettings',
        client: 'emby',
      );
      expect(prefs.sortBy, 'SortName');
      expect(prefs.customPrefs, {'homesection0': 'resume'});
      expect(adapter.query['client'], ['emby']);
      expect(adapter.query['userId'], ['user-1']);

      adapter.respond = (_) => CannedResponse(204, const []);
      await jf.displayPreferences.update(
        displayPreferencesId: 'usersettings',
        client: 'emby',
        preferences: prefs.copyWith(sortBy: 'DateCreated'),
      );
      expect(adapter.last!.method, 'POST');
      expect((adapter.last!.json! as Map)['SortBy'], 'DateCreated');
      expect((adapter.last!.json! as Map)['CustomPrefs'], {
        'homesection0': 'resume',
      });
    });
  });

  test('mediaSegments.forItem answers a page of segments', () async {
    answer(
      page([
        {
          'Id': 'seg1',
          'ItemId': 'i1',
          'Type': 'Intro',
          'StartTicks': 0,
          'EndTicks': 900000000,
        },
      ]),
    );
    final segments = await jf.mediaSegments.forItem(itemId: 'i1');
    expect(segments.items.single.type, 'Intro');
    expect(segments.items.single.end, const Duration(seconds: 90));
    expect(adapter.path, '/MediaSegments/i1');
  });

  group('backup', () {
    const manifest = {
      'Path': '/config/data/backups/b.zip',
      'ServerVersion': '12.4.0',
      'DateCreated': '2026-11-08T17:06:04.2882251Z',
    };

    test('list, create and manifest', () async {
      answer([manifest]);
      expect((await jf.backup.list()).single.serverVersion, '12.4.0');
      answer(manifest);
      expect(
        (await jf.backup.create(const {'Metadata': true})).path,
        '/config/data/backups/b.zip',
      );
      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.json, {'Metadata': true});
      expect((await jf.backup.manifest(path: '/x')).dateCreated, isNotNull);
      expect(adapter.query['path'], ['/x']);
    });
  });

  group('channels', () {
    test('list, items and latest answer pages of items', () async {
      answer(
        page([
          {'Id': 'c1', 'Name': 'Trailers', 'Type': 'Channel'},
        ]),
      );
      expect((await jf.channels.list()).items.single.name, 'Trailers');
      expect((await jf.channels.items(channelId: 'c1')).totalRecordCount, 1);
      expect(adapter.path, '/Channels/c1/Items');
      expect((await jf.channels.latest()).items.single.id, 'c1');
    });

    test('features of one channel and of all', () async {
      answer({'Id': 'c1', 'Name': 'Trailers', 'CanSearch': true});
      expect((await jf.channels.features(channelId: 'c1')).canSearch, isTrue);
      answer(const <Object?>[]);
      expect(await jf.channels.allFeatures(), isEmpty);
    });
  });

  group('dashboard and clientLog', () {
    test('configurationPages is a bare list', () async {
      answer([
        {'Name': 'tmdb', 'EnableInMainMenu': false, 'DisplayName': 'TMDb'},
      ]);
      expect(
        (await jf.dashboard.configurationPages()).single.displayName,
        'TMDb',
      );
    });

    test('configurationPage answers the page\'s HTML', () async {
      adapter.respond = (_) => CannedResponse(
        200,
        utf8.encode('<div>page</div>'),
        contentType: 'text/html',
      );
      expect(
        await jf.dashboard.configurationPage(name: 'tmdb'),
        '<div>page</div>',
      );
    });

    test('clientLog.upload answers the stored file name', () async {
      answer({'FileName': 'upload_1.log'});
      expect(
        await jf.clientLog.upload(body: Uint8List.fromList(utf8.encode('x'))),
        'upload_1.log',
      );
      expect(adapter.last!.headers['content-type'], startsWith('text/plain'));
      answer({'FileName': 7});
      expect(await jf.clientLog.upload(body: Uint8List(1)), '7');
    });
  });

  group('environment', () {
    test('drives and directoryContents are bare lists', () async {
      answer([
        {'Name': '/', 'Path': '/', 'Type': 'Directory'},
      ]);
      expect((await jf.environment.drives()).single.path, '/');
      expect(
        (await jf.environment.directoryContents(path: '/config')).single.type,
        'Directory',
      );
      expect(adapter.query['path'], ['/config']);
    });

    test('parentPath reads a JSON string', () async {
      answer('/config');
      expect(await jf.environment.parentPath(path: '/config/data'), '/config');
    });

    test('defaultDirectoryBrowser reads an empty object', () async {
      answer(const <String, Object?>{});
      expect(
        await jf.environment.defaultDirectoryBrowser(),
        isA<JellyfinDefaultDirectoryBrowser>(),
      );
    });
  });

  group('itemLookup', () {
    test('externalIdInfos is a bare list', () async {
      answer([
        {'Name': 'MusicBrainz', 'Key': 'MusicBrainzAlbum', 'Type': 'Album'},
      ]);
      expect(
        (await jf.itemLookup.externalIdInfos(itemId: 'i1')).single.key,
        'MusicBrainzAlbum',
      );
    });

    test('every search posts its query and answers the matches', () async {
      answer([
        {
          'Name': 'Kind of Blue',
          'ProductionYear': 1959,
          'ProviderIds': {'MusicBrainzAlbum': 'mb1'},
        },
      ]);
      const body = {
        'SearchInfo': {'Name': 'Kind of Blue'},
      };
      final searches = {
        '/Items/RemoteSearch/Movie': jf.itemLookup.searchMovies,
        '/Items/RemoteSearch/Series': jf.itemLookup.searchSeries,
        '/Items/RemoteSearch/Trailer': jf.itemLookup.searchTrailers,
        '/Items/RemoteSearch/MusicAlbum': jf.itemLookup.searchMusicAlbums,
        '/Items/RemoteSearch/MusicArtist': jf.itemLookup.searchMusicArtists,
        '/Items/RemoteSearch/MusicVideo': jf.itemLookup.searchMusicVideos,
        '/Items/RemoteSearch/Person': jf.itemLookup.searchPersons,
        '/Items/RemoteSearch/Book': jf.itemLookup.searchBooks,
        '/Items/RemoteSearch/BoxSet': jf.itemLookup.searchBoxSets,
      };
      for (final MapEntry(key: path, value: search) in searches.entries) {
        final match = (await search(body)).single;
        expect(match.productionYear, 1959);
        expect(match.providerIds, {'MusicBrainzAlbum': 'mb1'});
        expect(adapter.path, path);
        expect(adapter.last!.method, 'POST');
        expect(adapter.last!.json, body);
      }
    });
  });

  test('libraryStructure.list is a bare list of virtual folders', () async {
    answer([
      {
        'Name': 'Music',
        'Locations': ['/media/music'],
        'CollectionType': 'music',
        'ItemId': 'lib1',
      },
    ]);
    final folder = (await jf.libraryStructure.list()).single;
    expect(folder.locations, ['/media/music']);
    expect(folder.itemId, 'lib1');
  });

  test('movies.recommendations is a bare list with its items', () async {
    answer([
      {
        'CategoryId': 'cat1',
        'BaselineItemName': 'Alien',
        'RecommendationType': 'SimilarToRecentlyPlayed',
        'Items': [
          {'Id': 'm1', 'Name': 'Aliens', 'Type': 'Movie'},
        ],
      },
    ]);
    final recommendation = (await jf.movies.recommendations()).single;
    expect(recommendation.baselineItemName, 'Alien');
    expect(recommendation.items.single.name, 'Aliens');
  });

  group('remoteImage', () {
    test('list answers the images and the providers', () async {
      answer({
        'Images': [
          {
            'ProviderName': 'TheAudioDB',
            'Url': 'https://img.example.test/a.jpg',
            'Type': 'Primary',
          },
        ],
        'TotalRecordCount': 1,
        'Providers': ['TheAudioDB'],
      });
      final result = await jf.remoteImage.list(itemId: 'i1');
      expect(result.images.single.providerName, 'TheAudioDB');
      expect(adapter.path, '/Items/i1/RemoteImages');
    });

    test('providers is a bare list', () async {
      answer([
        {
          'Name': 'TheAudioDB',
          'SupportedImages': ['Primary', 'Backdrop'],
        },
      ]);
      expect(
        (await jf.remoteImage.providers(itemId: 'i1')).single.supportedImages,
        ['Primary', 'Backdrop'],
      );
    });
  });

  test('startup.firstUser answers the wizard\'s user', () async {
    answer({'Name': 'admin'});
    expect((await jf.startup.firstUser()).name, 'admin');
    expect(adapter.path, '/Startup/User');
  });

  group('devices', () {
    const device = {
      'Id': 'd1',
      'Name': 'iPhone',
      'AppName': 'Finova',
      'DateLastActivity': '2026-11-08T17:06:04.2882251Z',
    };

    test('list lifts the Items of the envelope', () async {
      answer(page([device]));
      expect((await jf.devices.list()).single.appName, 'Finova');
    });

    test('info answers null for an empty body; options the options', () async {
      answer(device);
      expect((await jf.devices.info(id: 'd1'))!.name, 'iPhone');
      expect(adapter.query['id'], ['d1']);
      adapter.body = '';
      expect(await jf.devices.info(id: 'd1'), isNull);
      answer({'DeviceId': 'd1', 'CustomName': 'Kitchen'});
      expect((await jf.devices.options(id: 'd1')).customName, 'Kitchen');
    });
  });

  group('trickplay', () {
    test('the tile and playlist URLs are signed', () {
      final tile = Uri.parse(
        jf.trickplay.tileUrl(itemId: 'i1', width: 320, index: 4),
      );
      expect(tile.path, '/Videos/i1/Trickplay/320/4.jpg');
      expect(tile.queryParameters['ApiKey'], 'tok');
      final playlist = Uri.parse(
        jf.trickplay.hlsPlaylistUrl(itemId: 'i1', width: 320),
      );
      expect(playlist.path, '/Videos/i1/Trickplay/320/tiles.m3u8');
      expect(playlist.queryParameters['ApiKey'], 'tok');
    });
  });
}
