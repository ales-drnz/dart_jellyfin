// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Field-level assertions for every Jellyfin DTO that ships in the
/// library. Each fixture below is a real response shape captured from
/// a Jellyfin 10.11.9 server seeded by `bootstrap.dart`; the fixtures
/// are inlined as raw strings so the tests stay self-contained and
/// committable (no PII — only synthetic Test Artist / Test Album / Track N
/// payloads).
///
/// These complement the integration smoke tests by catching parser
/// regressions without needing Docker.
library;

import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const _audioItemJson = r'''
{
  "Name": "Track 1",
  "ServerId": "32dcb3a2d1614c0db0ff0b3c417f0873",
  "Id": "b5455b2dcaf64392527a5ae01dd1523f",
  "Etag": "8b04da9f04d4cd2e4760ab3efdd0c0a6",
  "DateCreated": "2026-05-24T15:54:14.1923913Z",
  "CanDelete": true,
  "CanDownload": true,
  "HasLyrics": false,
  "Container": "mp3",
  "SortName": "0001 - Track 1",
  "PremiereDate": "2020-01-01T00:00:00.0000000Z",
  "MediaSources": [
    {
      "Protocol": "File",
      "Id": "b5455b2dcaf64392527a5ae01dd1523f",
      "Path": "/media/Music/Test Artist/Test Album/01 - Track 1.mp3",
      "Type": "Default",
      "Container": "mp3",
      "Size": 49038,
      "Name": "01 - Track 1",
      "RunTimeTicks": 30302040,
      "SupportsTranscoding": true,
      "SupportsDirectStream": true,
      "SupportsDirectPlay": true,
      "MediaStreams": [
        {
          "Codec": "mp3",
          "DisplayTitle": "MP3 - Stereo",
          "ChannelLayout": "stereo",
          "BitRate": 128000,
          "Channels": 2,
          "SampleRate": 44100,
          "Type": "Audio",
          "Index": 0
        }
      ],
      "Bitrate": 129464,
      "TranscodingSubProtocol": "http"
    }
  ],
  "Path": "/media/Music/Test Artist/Test Album/01 - Track 1.mp3",
  "RunTimeTicks": 30302040,
  "ProductionYear": 2020,
  "IndexNumber": 1,
  "IsFolder": false,
  "ParentId": "72839210ba8018a1bf1039f340953486",
  "Type": "Audio",
  "UserData": {
    "PlaybackPositionTicks": 1500000,
    "PlayCount": 4,
    "IsFavorite": true,
    "Likes": true,
    "LastPlayedDate": "2026-05-24T19:55:52.5971316Z",
    "Played": true,
    "Key": "Test Artist-Test Album-0001Track 1"
  },
  "Artists": ["Test Artist"],
  "ArtistItems": [
    {"Name": "Test Artist", "Id": "2ac1215700ad5ae5e300de65949c5647"}
  ],
  "Album": "Test Album",
  "AlbumId": "72839210ba8018a1bf1039f340953486",
  "AlbumPrimaryImageTag": "dea91e575240ee1245ce904eaa29feaa",
  "AlbumArtist": "Test Artist",
  "AlbumArtists": [
    {"Name": "Test Artist", "Id": "2ac1215700ad5ae5e300de65949c5647"}
  ],
  "MediaStreams": [
    {"Codec": "mp3", "DisplayTitle": "MP3 - Stereo", "BitRate": 128000, "Type": "Audio", "Index": 0}
  ],
  "Genres": ["Test Genre"],
  "Tags": ["seed"],
  "ImageTags": {"Primary": "dea91e575240ee1245ce904eaa29feaa"},
  "BackdropImageTags": [],
  "ImageBlurHashes": {
    "Primary": {"dea91e575240ee1245ce904eaa29feaa": "e9SPX|D+8|%K"}
  },
  "PrimaryImageAspectRatio": 1.0,
  "LocationType": "FileSystem",
  "MediaType": "Audio"
}
''';

const _audioItemMinimalJson = r'''
{
  "Id": "minimal-1",
  "Name": "Minimal",
  "Type": "Audio"
}
''';

const _viewMusicJson = r'''
{
  "Name": "Music",
  "ServerId": "server-xyz",
  "Id": "view-music",
  "CollectionType": "music",
  "ImageTags": {"Primary": "abc123"}
}
''';

const _searchHintJson = r'''
{
  "ItemId": "b5455b2dcaf64392527a5ae01dd1523f",
  "Id": "b5455b2dcaf64392527a5ae01dd1523f",
  "Name": "Track 1",
  "MatchedTerm": "track",
  "IndexNumber": 1,
  "ProductionYear": 2020,
  "Type": "Audio",
  "RunTimeTicks": 30302040,
  "MediaType": "Audio",
  "Album": "Test Album",
  "AlbumId": "72839210ba8018a1bf1039f340953486",
  "AlbumArtist": "Test Artist",
  "Artists": ["Test Artist"],
  "PrimaryImageTag": "abc-tag"
}
''';

const _systemInfoJson = r'''
{
  "HasPendingRestart": false,
  "Version": "10.11.9",
  "ProductName": "Jellyfin Server",
  "OperatingSystem": "Linux",
  "Id": "32dcb3a2d1614c0db0ff0b3c417f0873",
  "ServerName": "test-server",
  "LocalAddress": "http://127.0.0.1:18096"
}
''';

const _playbackInfoJson = r'''
{
  "MediaSources": [
    {
      "Id": "media-1",
      "Container": "mp3",
      "Path": "/m/track.mp3",
      "RunTimeTicks": 30000000,
      "Bitrate": 128000,
      "Size": 50000,
      "SupportsTranscoding": false,
      "SupportsDirectStream": true,
      "SupportsDirectPlay": true,
      "TranscodingSubProtocol": "http",
      "MediaStreams": [
        {"Codec": "mp3", "DisplayTitle": "MP3 - Stereo", "Type": "Audio", "Index": 0}
      ]
    }
  ],
  "PlaySessionId": "9aa287e2cc0c4b7aa37a2e9fe83eb511"
}
''';

const _userDataJson = r'''
{
  "PlaybackPositionTicks": 1500000,
  "PlayCount": 4,
  "IsFavorite": true,
  "Likes": false,
  "LastPlayedDate": "2026-05-24T19:55:52.5971316Z",
  "Played": true,
  "Key": "key-1"
}
''';

const _displayPreferencesJson = r'''
{
  "Id": "usersettings",
  "Client": "dart_jellyfin",
  "ViewType": "Audio",
  "SortBy": "SortName",
  "SortOrder": "Descending",
  "RememberIndexing": true,
  "RememberSorting": false,
  "ShowBackdrop": true,
  "ShowSidebar": false,
  "PrimaryImageHeight": 200,
  "PrimaryImageWidth": 300,
  "CustomPrefs": {"foo": "bar", "baz": "qux"}
}
''';

const _mediaSegmentJson = r'''
{
  "Id": "seg-1",
  "ItemId": "b5455b2dcaf64392527a5ae01dd1523f",
  "Type": "Intro",
  "StartTicks": 50000000,
  "EndTicks": 150000000
}
''';

const _sessionJson = r'''
{
  "Id": "session-1",
  "UserId": "user-abc",
  "UserName": "admin",
  "Client": "dart_jellyfin",
  "DeviceId": "device-1",
  "DeviceName": "test-device",
  "ApplicationVersion": "0.0.1",
  "RemoteEndPoint": "127.0.0.1",
  "LastActivityDate": "2026-05-24T20:00:00.000Z",
  "IsActive": true,
  "SupportsMediaControl": false,
  "SupportsRemoteControl": false,
  "PlayableMediaTypes": ["Audio"],
  "SupportedCommands": ["Play", "Pause"],
  "PlayState": {"PositionTicks": 0, "IsPaused": false, "IsMuted": false}
}
''';

const _queryFiltersJson = r'''
{
  "Genres": [
    {"Name": "Rock", "Id": "g1"},
    {"Name": "Jazz", "Id": "g2"}
  ],
  "Tags": ["fav", "live"]
}
''';

const _lyricsJson = r'''
{
  "Metadata": {"Artist": "Test Artist", "Album": "Test Album"},
  "Lyrics": [
    {"Start": 0, "Text": "First line"},
    {"Start": 50000000, "Text": "Second line (5 seconds in)"},
    {"Start": 100000000, "Text": "Third line"}
  ]
}
''';

const _lyricsPlainJson = r'''
{
  "Lyrics": [
    {"Text": "Plain line one"},
    {"Text": "Plain line two"}
  ]
}
''';

const _quickConnectStateJson = r'''
{
  "Authenticated": true,
  "Secret": "secret-xyz",
  "Code": "ABC123",
  "DeviceId": "device-1",
  "DeviceName": "test-device",
  "AppName": "dart_jellyfin",
  "AppVersion": "0.0.1",
  "DateAdded": "2026-05-24T20:00:00.000Z"
}
''';

const _authResultJson = r'''
{
  "User": {
    "Id": "user-abc",
    "Name": "admin",
    "ServerId": "server-1",
    "HasPassword": true,
    "HasConfiguredPassword": true,
    "HasConfiguredEasyPassword": false
  },
  "AccessToken": "token-xyz",
  "ServerId": "server-1"
}
''';

void main() {
  group('JellyfinItem.fromJson', () {
    test('parses a fully-populated audio item', () {
      final item = JellyfinItem.fromJson(
        jsonDecode(_audioItemJson) as Map<String, dynamic>,
      );

      // Identity / core
      expect(item.id, 'b5455b2dcaf64392527a5ae01dd1523f');
      expect(item.name, 'Track 1');
      expect(item.type, 'Audio');
      expect(item.mediaType, 'Audio');
      expect(item.sortName, '0001 - Track 1');
      expect(item.container, 'mp3');
      expect(item.isFolder, isFalse);
      expect(item.hasLyrics, isFalse);

      // Hierarchy
      expect(item.parentId, '72839210ba8018a1bf1039f340953486');
      expect(item.albumId, '72839210ba8018a1bf1039f340953486');
      expect(item.album, 'Test Album');
      expect(item.albumArtist, 'Test Artist');
      expect(item.albumArtists, ['Test Artist']);
      expect(item.artists, ['Test Artist']);
      expect(item.artistItems, hasLength(1));
      expect(item.artistItems.single.id, '2ac1215700ad5ae5e300de65949c5647');
      expect(item.artistItems.single.name, 'Test Artist');

      // Index / ordering / dates
      expect(item.indexNumber, 1);
      expect(item.productionYear, 2020);
      expect(item.premiereDate, isNotNull);
      expect(item.premiereDate!.year, 2020);
      expect(item.dateCreated, isNotNull);

      // Duration / ticks helper
      expect(item.runTimeTicks, 30302040);
      expect(item.durationMs, (30302040 / 10000).round());

      // Media sources / streams nested parsing
      expect(item.mediaSources, hasLength(1));
      expect(item.mediaSources.single.path,
          '/media/Music/Test Artist/Test Album/01 - Track 1.mp3');
      expect(item.mediaSources.single.container, 'mp3');
      expect(item.mediaSources.single.bitrate, 129464);
      expect(item.mediaSources.single.size, 49038);
      expect(item.mediaSources.single.supportsDirectPlay, isTrue);
      expect(item.mediaSources.single.supportsTranscoding, isTrue);
      expect(item.mediaSources.single.mediaStreams, hasLength(1));
      expect(item.mediaStreams, hasLength(1));

      // Genres / tags
      expect(item.genres, ['Test Genre']);
      expect(item.tags, ['seed']);

      // Images
      expect(item.imageTags['Primary'], 'dea91e575240ee1245ce904eaa29feaa');
      expect(item.albumPrimaryImageTag, 'dea91e575240ee1245ce904eaa29feaa');
      // The map flattens by ImageType, so 'Primary' resolves to the
      // blur hash even though the wire shape is nested by image tag.
      expect(item.imageBlurHashes['Primary'], 'e9SPX|D+8|%K');
      expect(item.primaryImageAspectRatio, 1.0);

      // UserData nested parsing
      expect(item.userData, isNotNull);
      expect(item.userData!.isFavorite, isTrue);
      expect(item.userData!.played, isTrue);
      expect(item.userData!.playCount, 4);
      expect(item.userData!.playbackPositionTicks, 1500000);
      expect(item.userData!.likes, isTrue);
      expect(item.userData!.lastPlayedDate, isNotNull);
      expect(item.userData!.key, 'Test Artist-Test Album-0001Track 1');

      // Convenience helpers
      expect(item.isAudio, isTrue);
      expect(item.isFavorite, isTrue);

      // Raw is preserved
      expect(item.raw['Etag'], '8b04da9f04d4cd2e4760ab3efdd0c0a6');
      expect(item.raw['CanDownload'], isTrue);
    });

    test('handles a minimal item without crashing on missing fields', () {
      final item = JellyfinItem.fromJson(
        jsonDecode(_audioItemMinimalJson) as Map<String, dynamic>,
      );
      expect(item.id, 'minimal-1');
      expect(item.name, 'Minimal');
      expect(item.type, 'Audio');
      expect(item.mediaSources, isEmpty);
      expect(item.mediaStreams, isEmpty);
      expect(item.artistItems, isEmpty);
      expect(item.albumArtists, isEmpty);
      expect(item.artists, isEmpty);
      expect(item.genres, isEmpty);
      expect(item.tags, isEmpty);
      expect(item.userData, isNull);
      expect(item.runTimeTicks, isNull);
      expect(item.indexNumber, isNull);
      expect(item.isFolder, isFalse);
    });

    test('durationMs is null when runTimeTicks is null', () {
      final item = JellyfinItem.fromJson(
        jsonDecode(_audioItemMinimalJson) as Map<String, dynamic>,
      );
      expect(item.durationMs, isNull);
    });
  });

  group('JellyfinView.fromJson', () {
    test('lifts ImageTags.Primary into primaryImageTag', () {
      final view = JellyfinView.fromJson(
        jsonDecode(_viewMusicJson) as Map<String, dynamic>,
      );
      expect(view.id, 'view-music');
      expect(view.name, 'Music');
      expect(view.collectionType, 'music');
      expect(view.primaryImageTag, 'abc123');
      expect(view.serverId, 'server-xyz');
    });
  });

  group('JellyfinSearchHint.fromJson', () {
    test('prefers Id over ItemId when both are present', () {
      final hint = JellyfinSearchHint.fromJson(
        jsonDecode(_searchHintJson) as Map<String, dynamic>,
      );
      expect(hint.itemId, 'b5455b2dcaf64392527a5ae01dd1523f');
      expect(hint.name, 'Track 1');
      expect(hint.matchedTerm, 'track');
      expect(hint.indexNumber, 1);
      expect(hint.productionYear, 2020);
      expect(hint.type, 'Audio');
      expect(hint.mediaType, 'Audio');
      expect(hint.runTimeTicks, 30302040);
      expect(hint.albumArtist, 'Test Artist');
      expect(hint.artists, ['Test Artist']);
      expect(hint.primaryImageTag, 'abc-tag');
    });

    test('falls back to ItemId when Id is missing', () {
      final hint = JellyfinSearchHint.fromJson({
        'ItemId': 'fallback-id',
        'Name': 'foo',
      });
      expect(hint.itemId, 'fallback-id');
    });
  });

  group('JellyfinSystemInfo.fromJson', () {
    test('parses every promoted field', () {
      final info = JellyfinSystemInfo.fromJson(
        jsonDecode(_systemInfoJson) as Map<String, dynamic>,
      );
      expect(info.id, '32dcb3a2d1614c0db0ff0b3c417f0873');
      expect(info.serverName, 'test-server');
      expect(info.version, '10.11.9');
      expect(info.productName, 'Jellyfin Server');
      expect(info.operatingSystem, 'Linux');
      expect(info.raw['LocalAddress'], 'http://127.0.0.1:18096');
    });
  });

  group('JellyfinPlaybackInfo.fromJson', () {
    test('parses mediaSources + playSessionId', () {
      final pi = JellyfinPlaybackInfo.fromJson(
        jsonDecode(_playbackInfoJson) as Map<String, dynamic>,
      );
      expect(pi.playSessionId, '9aa287e2cc0c4b7aa37a2e9fe83eb511');
      expect(pi.errorCode, isNull);
      expect(pi.mediaSources, hasLength(1));
      expect(pi.mediaSources.single.id, 'media-1');
      expect(pi.mediaSources.single.container, 'mp3');
      expect(pi.mediaSources.single.bitrate, 128000);
      expect(pi.mediaSources.single.supportsDirectPlay, isTrue);
      expect(pi.mediaSources.single.mediaStreams, hasLength(1));
    });
  });

  group('JellyfinUserData.fromJson', () {
    test('parses every promoted field', () {
      final ud = JellyfinUserData.fromJson(
        jsonDecode(_userDataJson) as Map<String, dynamic>,
      );
      expect(ud.playbackPositionTicks, 1500000);
      expect(ud.playCount, 4);
      expect(ud.isFavorite, isTrue);
      expect(ud.likes, isFalse);
      expect(ud.played, isTrue);
      expect(ud.key, 'key-1');
      expect(ud.lastPlayedDate, isNotNull);
    });

    test('treats missing booleans as false / missing counts as 0', () {
      final ud = JellyfinUserData.fromJson(const {});
      expect(ud.playCount, 0);
      expect(ud.isFavorite, isFalse);
      expect(ud.played, isFalse);
      expect(ud.likes, isNull);
    });
  });

  group('JellyfinDisplayPreferences.fromJson + toJson', () {
    test('round-trips every promoted field', () {
      final dp = JellyfinDisplayPreferences.fromJson(
        jsonDecode(_displayPreferencesJson) as Map<String, dynamic>,
      );
      expect(dp.id, 'usersettings');
      expect(dp.client, 'dart_jellyfin');
      expect(dp.viewType, 'Audio');
      expect(dp.sortBy, 'SortName');
      expect(dp.sortOrder, 'Descending');
      expect(dp.rememberIndexing, isTrue);
      expect(dp.rememberSorting, isFalse);
      expect(dp.showBackdrop, isTrue);
      expect(dp.showSidebar, isFalse);
      expect(dp.primaryImageHeight, 200);
      expect(dp.primaryImageWidth, 300);
      expect(dp.customPrefs, {'foo': 'bar', 'baz': 'qux'});

      // toJson emits the same wire shape.
      final round = dp.toJson();
      expect(round['SortBy'], 'SortName');
      expect(round['CustomPrefs'], {'foo': 'bar', 'baz': 'qux'});
      expect(round['PrimaryImageHeight'], 200);
    });
  });

  group('JellyfinMediaSegment.fromJson', () {
    test('parses startTicks / endTicks + Duration helpers', () {
      final seg = JellyfinMediaSegment.fromJson(
        jsonDecode(_mediaSegmentJson) as Map<String, dynamic>,
      );
      expect(seg.id, 'seg-1');
      expect(seg.itemId, 'b5455b2dcaf64392527a5ae01dd1523f');
      expect(seg.type, JellyfinMediaSegmentType.intro);
      expect(seg.startTicks, 50000000);
      expect(seg.endTicks, 150000000);
      // 50_000_000 ticks = 5_000_000 microseconds = 5 seconds.
      expect(seg.start, const Duration(seconds: 5));
      expect(seg.end, const Duration(seconds: 15));
    });
  });

  group('JellyfinSession.fromJson', () {
    test('parses identity + playState passthrough', () {
      final s = JellyfinSession.fromJson(
        jsonDecode(_sessionJson) as Map<String, dynamic>,
      );
      expect(s.id, 'session-1');
      expect(s.userId, 'user-abc');
      expect(s.userName, 'admin');
      expect(s.client, 'dart_jellyfin');
      expect(s.deviceId, 'device-1');
      expect(s.deviceName, 'test-device');
      expect(s.applicationVersion, '0.0.1');
      expect(s.remoteEndPoint, '127.0.0.1');
      expect(s.isActive, isTrue);
      expect(s.supportsMediaControl, isFalse);
      expect(s.supportsRemoteControl, isFalse);
      expect(s.playableMediaTypes, ['Audio']);
      expect(s.supportedCommands, ['Play', 'Pause']);
      expect(s.lastActivityDate, isNotNull);
      expect(s.nowPlayingItem, isNull);
      expect(s.playState, isNotNull);
      expect(s.playState!['IsPaused'], isFalse);
      expect(s.isPlaying, isFalse);
    });
  });

  group('JellyfinQueryFilters.fromJson', () {
    test('lifts Genres (Name+Id pairs) + Tags (strings)', () {
      final f = JellyfinQueryFilters.fromJson(
        jsonDecode(_queryFiltersJson) as Map<String, dynamic>,
      );
      expect(f.genres, hasLength(2));
      expect(f.genres.first.name, 'Rock');
      expect(f.genres.first.id, 'g1');
      expect(f.tags, ['fav', 'live']);
    });
  });

  group('JellyfinLyrics.fromJson', () {
    test('parses synced lyrics with start ticks + LRC rendering', () {
      final ly = JellyfinLyrics.fromJson(
        jsonDecode(_lyricsJson) as Map<String, dynamic>,
      );
      expect(ly.lines, hasLength(3));
      expect(ly.lines[0].text, 'First line');
      expect(ly.lines[0].startTicks, 0);
      expect(ly.lines[1].startTicks, 50000000);
      // 50_000_000 ticks → 5000 ms → [00:05.00]
      expect(ly.lines[1].toLrcLine(), startsWith('[00:05.00]'));
      expect(ly.lines[1].toLrcLine(), endsWith('Second line (5 seconds in)'));
    });

    test('plain (unsynced) lyrics produce text-only LRC lines', () {
      final ly = JellyfinLyrics.fromJson(
        jsonDecode(_lyricsPlainJson) as Map<String, dynamic>,
      );
      expect(ly.lines, hasLength(2));
      expect(ly.lines[0].startTicks, isNull);
      expect(ly.lines[0].toLrcLine(), 'Plain line one');
    });
  });

  group('JellyfinQuickConnectState.fromJson', () {
    test('parses every promoted field', () {
      final s = JellyfinQuickConnectState.fromJson(
        jsonDecode(_quickConnectStateJson) as Map<String, dynamic>,
      );
      expect(s.authenticated, isTrue);
      expect(s.secret, 'secret-xyz');
      expect(s.code, 'ABC123');
      expect(s.deviceId, 'device-1');
      expect(s.deviceName, 'test-device');
      expect(s.appName, 'dart_jellyfin');
      expect(s.appVersion, '0.0.1');
      expect(s.dateAdded, isNotNull);
    });
  });

  group('JellyfinAuthResult.fromJson', () {
    test('parses User + AccessToken + ServerId', () {
      final r = JellyfinAuthResult.fromJson(
        jsonDecode(_authResultJson) as Map<String, dynamic>,
      );
      expect(r.accessToken, 'token-xyz');
      expect(r.serverId, 'server-1');
      expect(r.user.id, 'user-abc');
      expect(r.user.name, 'admin');
      expect(r.user.hasPassword, isTrue);
      expect(r.user.hasConfiguredPassword, isTrue);
      expect(r.user.hasConfiguredEasyPassword, isFalse);
    });
  });

  group('JellyfinNotification.fromJson', () {
    test('parses a Sessions frame (list payload)', () {
      const json = r'''
{
  "MessageType": "Sessions",
  "Data": [
    {"Id": "s1", "UserId": "u1", "Client": "web"},
    {"Id": "s2", "UserId": "u2", "Client": "iOS"}
  ]
}
''';
      final n = JellyfinNotification.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(n.messageType, 'Sessions');
      expect(n.data, isA<List<dynamic>>());
      expect((n.data as List).length, 2);
    });

    test('parses a UserDataChanged frame (map payload)', () {
      const json = r'''
{
  "MessageType": "UserDataChanged",
  "Data": {
    "UserId": "user-1",
    "UserDataList": [
      {"ItemId": "item-1", "IsFavorite": true, "Played": false, "PlayCount": 1}
    ]
  }
}
''';
      final n = JellyfinNotification.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(n.messageType, 'UserDataChanged');
      expect(n.data, isA<Map<String, dynamic>>());
      expect((n.data as Map)['UserId'], 'user-1');
    });

    test('handles KeepAlive (no data)', () {
      final n = JellyfinNotification.fromJson(const {
        'MessageType': 'KeepAlive',
      });
      expect(n.messageType, 'KeepAlive');
      expect(n.data, isNull);
    });

    test('falls back to "Unknown" when MessageType is missing', () {
      final n = JellyfinNotification.fromJson(const {});
      expect(n.messageType, 'Unknown');
    });
  });

  group('JellyfinQueryResult.fromJson', () {
    test('lifts Items + TotalRecordCount + StartIndex', () {
      const json = r'''
{
  "Items": [{"Id": "1", "Name": "A"}, {"Id": "2", "Name": "B"}],
  "TotalRecordCount": 2,
  "StartIndex": 0
}
''';
      final q = JellyfinQueryResult.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
        JellyfinItem.fromJson,
      );
      expect(q.totalRecordCount, 2);
      expect(q.startIndex, 0);
      expect(q.items, hasLength(2));
      expect(q.items.first.id, '1');
      expect(q.items.last.name, 'B');
    });

    test('honours itemsKey override (SearchHints envelope)', () {
      const json = r'''
{
  "SearchHints": [{"Id": "h1", "Name": "Hit"}],
  "TotalRecordCount": 1
}
''';
      final q = JellyfinQueryResult.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
        JellyfinSearchHint.fromJson,
        itemsKey: 'SearchHints',
      );
      expect(q.items, hasLength(1));
      expect(q.items.single.itemId, 'h1');
    });
  });
}
