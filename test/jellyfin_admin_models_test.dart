// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The typed admin, metadata, live TV and account models, decoded from
/// bodies shaped like Jellyfin 12.4 answers, and the sub-API methods that
/// return them.
library;

import 'dart:convert';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

const Map<String, Object?> _empty = {};

void main() {
  group('shared pairs', () {
    test('JellyfinNameIdPair', () {
      final p = JellyfinNameIdPair.fromJson(const {
        'Name': 'HD Homerun',
        'Id': 'hdhomerun',
      });
      expect(p.name, 'HD Homerun');
      expect(p.id, 'hdhomerun');
      final e = JellyfinNameIdPair.fromJson(_empty);
      expect(e.name, '');
      expect(e.id, '');
    });

    test('JellyfinNameValuePair', () {
      final p = JellyfinNameValuePair.fromJson(const {
        'Name': 'Afrikaans',
        'Value': 'af',
      });
      expect(p.value, 'af');
      expect(JellyfinNameValuePair.fromJson(_empty).value, isNull);
    });
  });

  group('API keys, backups, configuration', () {
    test('JellyfinApiKey', () {
      final k = JellyfinApiKey.fromJson(const {
        'Id': 3,
        'AccessToken': 'abc123',
        'AppName': 'ci',
        'IsActive': true,
        'DateCreated': '2026-11-07T10:00:00.0000000Z',
        'UserId': '00000000000000000000000000000000',
      });
      expect(k.accessToken, 'abc123');
      expect(k.appName, 'ci');
      expect(k.isActive, isTrue);
      expect(k.dateCreated, DateTime.utc(2026, 11, 7, 10));
      final e = JellyfinApiKey.fromJson(_empty);
      expect(e.accessToken, '');
      expect(e.isActive, isFalse);
      expect(e.dateRevoked, isNull);
    });

    test('JellyfinBackupManifest and options', () {
      final m = JellyfinBackupManifest.fromJson(const {
        'ServerVersion': '12.4.0',
        'BackupEngineVersion': '0.2.0',
        'DateCreated': '2026-11-07T10:00:00Z',
        'Path': '/config/data/backups/jellyfin-backup.zip',
        'Options': {'Metadata': true, 'Database': true},
      });
      expect(m.path, endsWith('.zip'));
      expect(m.serverVersion, '12.4.0');
      expect(m.options!.metadata, isTrue);
      expect(m.options!.trickplay, isFalse);
      expect(m.options!.database, isTrue);
      final e = JellyfinBackupManifest.fromJson(_empty);
      expect(e.options, isNull);
      expect(e.path, isNull);
    });

    test('JellyfinServerConfiguration', () {
      final c = JellyfinServerConfiguration.fromJson(const {
        'ServerName': 'home',
        'UICulture': 'en-US',
        'PreferredMetadataLanguage': 'en',
        'MetadataCountryCode': 'US',
        'IsStartupWizardCompleted': true,
        'QuickConnectAvailable': true,
        'EnableLegacyAuthorization': false,
        'MinResumePct': 5,
        'MaxResumePct': 90,
        'RemoteClientBitrateLimit': 0,
        'PluginRepositories': [
          {
            'Name': 'Jellyfin Stable',
            'Url': 'https://repo.jellyfin.org/files/plugin/manifest.json',
            'Enabled': true,
          },
        ],
        'MetadataOptions': [
          {
            'ItemType': 'Book',
            'DisabledMetadataFetchers': ['x'],
          },
        ],
      });
      expect(c.serverName, 'home');
      expect(c.isStartupWizardCompleted, isTrue);
      expect(c.maxResumePct, 90);
      expect(c.pluginRepositories.single.enabled, isTrue);
      expect(c.metadataOptions.single.itemType, 'Book');
      expect(c.metadataOptions.single.disabledMetadataFetchers, ['x']);
      final e = JellyfinServerConfiguration.fromJson(_empty);
      expect(e.pluginRepositories, isEmpty);
      expect(e.quickConnectAvailable, isFalse);
    });

    test('JellyfinMetadataOptions (the default template)', () {
      final o = JellyfinMetadataOptions.fromJson(const {
        'DisabledMetadataSavers': <String>[],
        'LocalMetadataReaderOrder': <String>[],
        'MetadataFetcherOrder': ['TheMovieDb'],
      });
      expect(o.itemType, isNull);
      expect(o.metadataFetcherOrder, ['TheMovieDb']);
      expect(
        JellyfinMetadataOptions.fromJson(_empty).imageFetcherOrder,
        isEmpty,
      );
    });

    test('JellyfinBrandingOptions', () {
      final b = JellyfinBrandingOptions.fromJson(const {
        'SplashscreenEnabled': false,
      });
      expect(b.splashscreenEnabled, isFalse);
      expect(b.loginDisclaimer, isNull);
      expect(
        JellyfinBrandingOptions.fromJson(const {'CustomCss': 'a{}'}).customCss,
        'a{}',
      );
    });

    test('JellyfinConfigurationPage', () {
      final p = JellyfinConfigurationPage.fromJson(const {
        'Name': 'TMDb',
        'EnableInMainMenu': false,
        'DisplayName': 'TMDb',
        'PluginId': 'b8715ed16c4745289ad3f72deb539cd4',
      });
      expect(p.name, 'TMDb');
      expect(p.pluginId, 'b8715ed16c4745289ad3f72deb539cd4');
      expect(JellyfinConfigurationPage.fromJson(_empty).name, '');
    });

    test('JellyfinChannelFeatures', () {
      final f = JellyfinChannelFeatures.fromJson(const {
        'Name': 'Podcasts',
        'Id': 'c1',
        'CanSearch': true,
        'MediaTypes': ['Audio'],
        'ContentTypes': ['Podcast'],
        'MaxPageSize': 50,
        'DefaultSortFields': ['Name'],
      });
      expect(f.canSearch, isTrue);
      expect(f.mediaTypes, ['Audio']);
      expect(f.maxPageSize, 50);
      final e = JellyfinChannelFeatures.fromJson(_empty);
      expect(e.id, '');
      expect(e.contentTypes, isEmpty);
    });

    test('JellyfinDeviceOptions', () {
      final o = JellyfinDeviceOptions.fromJson(const {
        'Id': 1,
        'DeviceId': 'd1',
        'CustomName': 'Living room',
      });
      expect(o.deviceId, 'd1');
      expect(o.customName, 'Living room');
      expect(JellyfinDeviceOptions.fromJson(_empty).customName, isNull);
    });

    test('JellyfinFileSystemEntry and default directory', () {
      final d = JellyfinFileSystemEntry.fromJson(const {
        'Name': 'Music',
        'Path': '/media/Music',
        'Type': 'Directory',
      });
      expect(d.isDirectory, isTrue);
      expect(d.path, '/media/Music');
      final e = JellyfinFileSystemEntry.fromJson(_empty);
      expect(e.isDirectory, isFalse);
      expect(JellyfinDefaultDirectoryBrowser.fromJson(_empty).path, isNull);
      expect(
        JellyfinDefaultDirectoryBrowser.fromJson(const {'Path': '/media'}).path,
        '/media',
      );
    });

    test('JellyfinCollectionCreationResult', () {
      expect(
        JellyfinCollectionCreationResult.fromJson(const {'Id': 'b1'}).id,
        'b1',
      );
      expect(JellyfinCollectionCreationResult.fromJson(_empty).id, '');
    });
  });

  group('localization', () {
    test('JellyfinCountry', () {
      final c = JellyfinCountry.fromJson(const {
        'Name': 'AF',
        'DisplayName': 'Afghanistan',
        'TwoLetterISORegionName': 'AF',
        'ThreeLetterISORegionName': 'AFG',
      });
      expect(c.displayName, 'Afghanistan');
      expect(c.threeLetterIsoRegionName, 'AFG');
      expect(JellyfinCountry.fromJson(_empty).name, '');
    });

    test('JellyfinCulture', () {
      final c = JellyfinCulture.fromJson(const {
        'Name': 'Abkhazian',
        'DisplayName': 'Abkhazian',
        'TwoLetterISOLanguageName': 'ab',
        'ThreeLetterISOLanguageName': 'abk',
        'ThreeLetterISOLanguageNames': ['abk'],
      });
      expect(c.twoLetterIsoLanguageName, 'ab');
      expect(c.threeLetterIsoLanguageNames, ['abk']);
      expect(
        JellyfinCulture.fromJson(_empty).threeLetterIsoLanguageNames,
        isEmpty,
      );
    });

    test('JellyfinParentalRating, with and without a value', () {
      final r = JellyfinParentalRating.fromJson(const {
        'Name': 'TV-Y7',
        'Value': 7,
        'RatingScore': {'score': 7, 'subScore': 0},
      });
      expect(r.value, 7);
      expect(r.score, 7);
      expect(r.subScore, 0);
      final unrated = JellyfinParentalRating.fromJson(const {
        'Name': 'Unrated',
      });
      expect(unrated.value, isNull);
      expect(unrated.score, isNull);
    });
  });

  group('metadata lookup and editing', () {
    test('JellyfinExternalIdInfo', () {
      final i = JellyfinExternalIdInfo.fromJson(const {
        'Name': 'MusicBrainz',
        'Key': 'MusicBrainzAlbum',
        'Type': 'Album',
      });
      expect(i.key, 'MusicBrainzAlbum');
      expect(i.type, 'Album');
      expect(
        JellyfinExternalIdInfo.fromJson(const {
          'Name': 'TheAudioDb',
          'Key': 'AudioDbAlbum',
        }).type,
        isNull,
      );
    });

    test('JellyfinRemoteSearchResult with nested artists', () {
      final r = JellyfinRemoteSearchResult.fromJson(const {
        'Name': 'Selected Ambient Works',
        'ProviderIds': {'MusicBrainzAlbum': 'mb1'},
        'ProductionYear': 1992,
        'PremiereDate': '1992-11-09T00:00:00.0000000Z',
        'SearchProviderName': 'MusicBrainz',
        'AlbumArtist': {'Name': 'Aphex Twin'},
        'Artists': [
          {'Name': 'Aphex Twin'},
        ],
      });
      expect(r.providerIds, {'MusicBrainzAlbum': 'mb1'});
      expect(r.productionYear, 1992);
      expect(r.premiereDate, DateTime.utc(1992, 11, 9));
      expect(r.albumArtist!.name, 'Aphex Twin');
      expect(r.artists.single.name, 'Aphex Twin');
      final e = JellyfinRemoteSearchResult.fromJson(_empty);
      expect(e.albumArtist, isNull);
      expect(e.providerIds, isEmpty);
    });

    test('JellyfinMetadataEditorInfo', () {
      final m = JellyfinMetadataEditorInfo.fromJson(const {
        'ParentalRatingOptions': [
          {'Name': 'Unrated'},
          {'Name': 'G', 'Value': 0},
        ],
        'Countries': [
          {'Name': 'IT', 'DisplayName': 'Italy'},
        ],
        'Cultures': [
          {'Name': 'Italian', 'TwoLetterISOLanguageName': 'it'},
        ],
        'ExternalIdInfos': [
          {'Name': 'MusicBrainz', 'Key': 'MusicBrainzAlbum'},
        ],
        'ContentType': 'music',
        'ContentTypeOptions': [
          {'Name': 'Music', 'Value': 'music'},
        ],
      });
      expect(m.parentalRatingOptions, hasLength(2));
      expect(m.countries.single.displayName, 'Italy');
      expect(m.cultures.single.twoLetterIsoLanguageName, 'it');
      expect(m.externalIdInfos.single.key, 'MusicBrainzAlbum');
      expect(m.contentType, 'music');
      expect(m.contentTypeOptions.single.value, 'music');
      final e = JellyfinMetadataEditorInfo.fromJson(_empty);
      expect(e.countries, isEmpty);
      expect(e.contentType, isNull);
    });

    test('JellyfinRemoteImageResult and providers', () {
      final r = JellyfinRemoteImageResult.fromJson(const {
        'Images': [
          {
            'ProviderName': 'TheAudioDB',
            'Url': 'https://r2.theaudiodb.com/a.jpg',
            'Type': 'Primary',
            'RatingType': 'Score',
            'Width': 500,
            'CommunityRating': 7.5,
          },
        ],
        'TotalRecordCount': 1,
        'Providers': ['TheAudioDB'],
      });
      expect(r.totalRecordCount, 1);
      expect(r.providers, ['TheAudioDB']);
      final img = r.images.single;
      expect(img.url, 'https://r2.theaudiodb.com/a.jpg');
      expect(img.type, 'Primary');
      expect(img.width, 500);
      expect(img.communityRating, 7.5);
      expect(img.height, isNull);
      final e = JellyfinRemoteImageResult.fromJson(_empty);
      expect(e.images, isEmpty);
      expect(e.totalRecordCount, 0);

      final p = JellyfinImageProviderInfo.fromJson(const {
        'Name': 'TheAudioDB',
        'SupportedImages': ['Primary', 'Disc'],
      });
      expect(p.supportedImages, ['Primary', 'Disc']);
      expect(
        JellyfinImageProviderInfo.fromJson(_empty).supportedImages,
        isEmpty,
      );
    });
  });

  group('libraries', () {
    test('JellyfinThemeMedia', () {
      final t = JellyfinThemeMedia.fromJson(const {
        'ThemeVideosResult': {
          'OwnerId': 'a1',
          'Items': <Object?>[],
          'TotalRecordCount': 0,
        },
        'ThemeSongsResult': {
          'OwnerId': 'a1',
          'Items': [
            {'Id': 's1', 'Name': 'Theme', 'Type': 'Audio'},
          ],
          'TotalRecordCount': 1,
        },
      });
      expect(t.themeVideos.items, isEmpty);
      expect(t.themeSongs.items.single.id, 's1');
      expect(t.soundtrackSongs.totalRecordCount, 0);
      expect(JellyfinThemeMedia.fromJson(_empty).themeSongs.items, isEmpty);
    });

    test('JellyfinLibraryAvailableOptions', () {
      final o = JellyfinLibraryAvailableOptions.fromJson(const {
        'MetadataSavers': [
          {'Name': 'Nfo', 'DefaultEnabled': true},
        ],
        'MetadataReaders': [
          {'Name': 'Nfo', 'DefaultEnabled': true},
        ],
        'SubtitleFetchers': <Object?>[],
        'TypeOptions': [
          {
            'Type': 'Series',
            'MetadataFetchers': [
              {'Name': 'TheMovieDb', 'DefaultEnabled': true},
            ],
            'ImageFetchers': [
              {'Name': 'TheMovieDb', 'DefaultEnabled': true},
            ],
            'SimilarItemProviders': [
              {'Name': 'Local Genre/Tag', 'DefaultEnabled': true},
            ],
            'SupportedImageTypes': ['Primary', 'Backdrop'],
            'DefaultImageOptions': [
              {'Type': 'Backdrop', 'Limit': 1, 'MinWidth': 1280},
            ],
          },
        ],
      });
      expect(o.metadataSavers.single.name, 'Nfo');
      expect(o.metadataSavers.single.defaultEnabled, isTrue);
      expect(o.subtitleFetchers, isEmpty);
      expect(o.lyricFetchers, isEmpty);
      final series = o.typeOptions.single;
      expect(series.type, 'Series');
      expect(series.metadataFetchers.single.name, 'TheMovieDb');
      expect(series.similarItemProviders.single.name, 'Local Genre/Tag');
      expect(series.supportedImageTypes, ['Primary', 'Backdrop']);
      expect(series.raw['DefaultImageOptions'], isA<List<Object?>>());
      expect(
        JellyfinLibraryAvailableOptions.fromJson(_empty).typeOptions,
        isEmpty,
      );
      expect(JellyfinLibraryTypeOptions.fromJson(_empty).type, '');
      expect(
        JellyfinLibraryOptionInfo.fromJson(_empty).defaultEnabled,
        isFalse,
      );
    });

    test('JellyfinVirtualFolder', () {
      final v = JellyfinVirtualFolder.fromJson(const {
        'Name': 'Music',
        'Locations': ['/media/Music'],
        'CollectionType': 'music',
        'LibraryOptions': {'Enabled': true, 'EnableLUFSScan': false},
        'ItemId': '7e64e319657a9516ec78490da03edccb',
        'RefreshStatus': 'Idle',
      });
      expect(v.name, 'Music');
      expect(v.locations, ['/media/Music']);
      expect(v.collectionType, 'music');
      expect(v.itemId, '7e64e319657a9516ec78490da03edccb');
      expect(v.libraryOptions['Enabled'], isTrue);
      expect(v.refreshProgress, isNull);
      final e = JellyfinVirtualFolder.fromJson(_empty);
      expect(e.locations, isEmpty);
      expect(e.libraryOptions, isEmpty);
    });
  });

  group('plugins and packages', () {
    test('JellyfinPluginInfo', () {
      final p = JellyfinPluginInfo.fromJson(const {
        'Name': 'AudioDB',
        'Version': '12.4.0.0',
        'ConfigurationFileName': 'Jellyfin.Plugin.AudioDb.xml',
        'Id': 'a629c0dafac54c7e931a7174223f14c8',
        'CanUninstall': false,
        'HasImage': true,
        'Status': 'Active',
      });
      expect(p.version, '12.4.0.0');
      expect(p.hasImage, isTrue);
      expect(p.status, 'Active');
      expect(JellyfinPluginInfo.fromJson(_empty).status, isNull);
    });

    test('JellyfinPluginManifest (camelCase)', () {
      final m = JellyfinPluginManifest.fromJson(const {
        'guid': 'a629c0dafac54c7e931a7174223f14c8',
        'name': 'AudioDB',
        'version': '12.4.0.0',
        'status': 'Active',
        'autoUpdate': true,
      });
      expect(m.guid, 'a629c0dafac54c7e931a7174223f14c8');
      expect(m.autoUpdate, isTrue);
      expect(JellyfinPluginManifest.fromJson(_empty).name, '');
    });

    test('JellyfinPackageInfo with versions', () {
      final p = JellyfinPackageInfo.fromJson(const {
        'name': 'Bookshelf',
        'owner': 'jellyfin',
        'category': 'Books',
        'guid': '9c4e63f1031b4f25988b4f7d78a8b53e',
        'versions': [
          {
            'version': '13.0.0.0',
            'VersionNumber': '13.0.0.0',
            'targetAbi': '10.11.0.0',
            'timestamp': '2025-10-20T01:25:49Z',
            'repositoryUrl':
                'https://repo.jellyfin.org/files/plugin/manifest.json',
          },
        ],
      });
      expect(p.name, 'Bookshelf');
      expect(p.guid, '9c4e63f1031b4f25988b4f7d78a8b53e');
      final v = p.versions.single;
      expect(v.version, '13.0.0.0');
      expect(v.targetAbi, '10.11.0.0');
      expect(v.timestamp, DateTime.utc(2025, 10, 20, 1, 25, 49));
      expect(JellyfinPackageInfo.fromJson(_empty).versions, isEmpty);
      expect(JellyfinPackageVersion.fromJson(_empty).version, '');
    });

    test('JellyfinRepository', () {
      final r = JellyfinRepository.fromJson(const {
        'Name': 'Jellyfin Stable',
        'Url': 'https://repo.jellyfin.org/files/plugin/manifest.json',
        'Enabled': true,
      });
      expect(r.enabled, isTrue);
      expect(JellyfinRepository.fromJson(_empty).url, isNull);
    });
  });

  group('live TV', () {
    test('JellyfinTimer', () {
      final t = JellyfinTimer.fromJson(const {
        'Id': 't1',
        'Type': 'Timer',
        'ChannelId': 'c1',
        'ChannelName': 'Rai 1',
        'Name': 'News',
        'StartDate': '2026-11-07T20:00:00Z',
        'EndDate': '2026-11-07T20:30:00Z',
        'Status': 'New',
        'PrePaddingSeconds': 60,
        'KeepUntil': 'UntilDeleted',
        'SeriesTimerId': 's1',
        'ProgramInfo': {'Id': 'p1', 'Name': 'News', 'Type': 'Program'},
      });
      expect(t.id, 't1');
      expect(t.channelName, 'Rai 1');
      expect(t.startDate, DateTime.utc(2026, 11, 7, 20));
      expect(t.prePaddingSeconds, 60);
      expect(t.programInfo!.id, 'p1');
      final e = JellyfinTimer.fromJson(_empty);
      expect(e.id, '');
      expect(e.programInfo, isNull);
    });

    test('JellyfinSeriesTimer (the timer defaults)', () {
      final s = JellyfinSeriesTimer.fromJson(const {
        'RecordAnyTime': true,
        'SkipEpisodesInLibrary': true,
        'RecordAnyChannel': false,
        'KeepUpTo': 0,
        'RecordNewOnly': true,
        'Days': ['Sunday', 'Monday'],
        'DayPattern': 'Daily',
        'Id': 'eb075d6a62e2edc6b764a304633d33c0',
        'Type': 'SeriesTimer',
        'KeepUntil': 'UntilDeleted',
      });
      expect(s.recordAnyTime, isTrue);
      expect(s.recordAnyChannel, isFalse);
      expect(s.days, ['Sunday', 'Monday']);
      expect(s.dayPattern, 'Daily');
      expect(s.keepUpTo, 0);
      final e = JellyfinSeriesTimer.fromJson(_empty);
      expect(e.days, isEmpty);
      expect(e.recordNewOnly, isFalse);
    });

    test('JellyfinLiveTvInfo and guide info', () {
      final i = JellyfinLiveTvInfo.fromJson(const {
        'Services': [
          {
            'Name': 'Emby',
            'Status': 'Ok',
            'HasUpdateAvailable': false,
            'IsVisible': false,
            'Tuners': <String>[],
          },
        ],
        'IsEnabled': true,
        'EnabledUsers': <String>[],
      });
      expect(i.isEnabled, isTrue);
      expect(i.services.single.status, 'Ok');
      expect(JellyfinLiveTvInfo.fromJson(_empty).services, isEmpty);
      expect(JellyfinLiveTvService.fromJson(_empty).name, '');

      final g = JellyfinGuideInfo.fromJson(const {
        'StartDate': '2026-11-07T17:11:43.3219794Z',
        'EndDate': '2026-11-14T17:11:43.3219794Z',
      });
      expect(g.endDate!.difference(g.startDate!), const Duration(days: 7));
      expect(JellyfinGuideInfo.fromJson(_empty).startDate, isNull);
    });

    test('JellyfinChannelMappingOptions', () {
      final o = JellyfinChannelMappingOptions.fromJson(const {
        'TunerChannels': [
          {
            'Name': 'Rai 1',
            'ProviderChannelName': 'RAI1',
            'ProviderChannelId': 'p1',
            'Id': 't1',
          },
        ],
        'ProviderChannels': [
          {'Name': 'RAI1', 'Id': 'p1'},
        ],
        'Mappings': [
          {'Name': 't1', 'Value': 'p1'},
        ],
        'ProviderName': 'Schedules Direct',
      });
      expect(o.tunerChannels.single.providerChannelId, 'p1');
      expect(o.providerChannels.single.id, 'p1');
      expect(o.mappings.single.value, 'p1');
      expect(o.providerName, 'Schedules Direct');
      expect(JellyfinChannelMappingOptions.fromJson(_empty).mappings, isEmpty);
      expect(JellyfinTunerChannelMapping.fromJson(_empty).id, '');
    });

    test('JellyfinTunerHost', () {
      final t = JellyfinTunerHost.fromJson(const {
        'Id': 'h1',
        'Url': 'http://192.168.1.20',
        'Type': 'hdhomerun',
        'FriendlyName': 'HDHomeRun',
        'TunerCount': 2,
        'AllowHWTranscoding': true,
      });
      expect(t.type, 'hdhomerun');
      expect(t.tunerCount, 2);
      expect(t.allowHwTranscoding, isTrue);
      expect(t.importFavoritesOnly, isFalse);
      expect(JellyfinTunerHost.fromJson(_empty).id, isNull);
    });

    test('JellyfinListingsProvider (the defaults)', () {
      final p = JellyfinListingsProvider.fromJson(const {
        'EnabledTuners': <String>[],
        'EnableAllTuners': true,
        'NewsCategories': ['news', 'journalism'],
        'MovieCategories': ['movie'],
        'ChannelMappings': <Object?>[],
      });
      expect(p.enableAllTuners, isTrue);
      expect(p.newsCategories, ['news', 'journalism']);
      expect(p.movieCategories, ['movie']);
      expect(p.id, isNull);
      expect(JellyfinListingsProvider.fromJson(_empty).kidsCategories, isEmpty);
    });
  });

  group('subtitles, fonts, system', () {
    test('JellyfinRemoteSubtitle', () {
      final s = JellyfinRemoteSubtitle.fromJson(const {
        'ThreeLetterISOLanguageName': 'ita',
        'Id': 'os-1',
        'ProviderName': 'Open Subtitles',
        'Name': 'Movie.2026.srt',
        'Format': 'srt',
        'DownloadCount': 1200,
        'CommunityRating': 8.5,
        'IsHashMatch': true,
        'HearingImpaired': true,
      });
      expect(s.id, 'os-1');
      expect(s.language, 'ita');
      expect(s.downloadCount, 1200);
      expect(s.isHashMatch, isTrue);
      expect(s.forced, isFalse);
      expect(JellyfinRemoteSubtitle.fromJson(_empty).format, isNull);
    });

    test('JellyfinServerFile (a log or a font)', () {
      final f = JellyfinServerFile.fromJson(const {
        'DateCreated': '2026-11-07T17:05:02.5049044Z',
        'DateModified': '2026-11-07T17:05:02.5049044Z',
        'Size': 19767,
        'Name': 'log_20261107.log',
      });
      expect(f.name, 'log_20261107.log');
      expect(f.size, 19767);
      expect(f.dateModified!.year, 2026);
      expect(JellyfinServerFile.fromJson(_empty).size, isNull);
    });

    test('JellyfinSystemStorage', () {
      const folder = {
        'Path': '/config',
        'FreeSpace': 126147047424,
        'UsedSpace': 869760737280,
        'StorageType': 'Fixed',
        'DeviceId': '/config',
      };
      final s = JellyfinSystemStorage.fromJson(const {
        'ProgramDataFolder': folder,
        'CacheFolder': folder,
        'Libraries': [
          {
            'Id': '7e64e319657a9516ec78490da03edccb',
            'Name': 'Music',
            'Folders': [folder],
          },
        ],
      });
      expect(s.programDataFolder!.freeSpace, 126147047424);
      expect(s.cacheFolder!.storageType, 'Fixed');
      expect(s.webFolder, isNull);
      expect(s.libraries.single.name, 'Music');
      expect(s.libraries.single.folders.single.path, '/config');
      final e = JellyfinSystemStorage.fromJson(_empty);
      expect(e.libraries, isEmpty);
      expect(e.logFolder, isNull);
      expect(JellyfinFolderStorage.fromJson(_empty).path, '');
      expect(JellyfinLibraryStorage.fromJson(_empty).folders, isEmpty);
    });
  });

  group('accounts', () {
    test('JellyfinStartupUser', () {
      final u = JellyfinStartupUser.fromJson(const {'Name': 'admin'});
      expect(u.name, 'admin');
      expect(u.password, isNull);
      expect(JellyfinStartupUser.fromJson(_empty).name, isNull);
    });

    test('JellyfinForgotPasswordResult and JellyfinPinRedeemResult', () {
      final f = JellyfinForgotPasswordResult.fromJson(const {
        'Action': 'PinCode',
        'PinFile': '/config/passwordreset1.json',
        'PinExpirationDate': '2026-11-07T18:00:00Z',
      });
      expect(f.action, 'PinCode');
      expect(f.pinExpirationDate, DateTime.utc(2026, 11, 7, 18));
      expect(JellyfinForgotPasswordResult.fromJson(_empty).action, isNull);

      final p = JellyfinPinRedeemResult.fromJson(const {
        'Success': true,
        'UsersReset': ['admin'],
      });
      expect(p.success, isTrue);
      expect(p.usersReset, ['admin']);
      expect(JellyfinPinRedeemResult.fromJson(_empty).success, isFalse);
    });
  });

  group('sub-API methods', () {
    late CapturingAdapter adapter;
    late JellyfinClient client;

    setUp(() {
      adapter = CapturingAdapter();
      client = capturingClient(adapter);
    });

    test('apiKey.list lifts the Items of the envelope', () async {
      adapter.respond = (_) => CannedResponse.json({
        'Items': [
          {'AccessToken': 'k1', 'AppName': 'ci', 'IsActive': true},
        ],
        'TotalRecordCount': 1,
      });
      final keys = await client.apiKey.list();
      expect(adapter.path, '/Auth/Keys');
      expect(keys.single.accessToken, 'k1');
    });

    test('liveTv.timers and seriesTimers answer typed pages', () async {
      adapter.respond = (_) => CannedResponse.json({
        'Items': [
          {'Id': 'x1', 'Name': 'News'},
        ],
        'TotalRecordCount': 1,
      });
      expect((await client.liveTv.timers()).items.single.id, 'x1');
      expect((await client.liveTv.seriesTimers()).items.single.name, 'News');
    });

    test('an empty body is an empty model, not a failure', () async {
      adapter.respond = (_) => CannedResponse(200, const []);
      expect((await client.system.storage()).libraries, isEmpty);
      expect((await client.branding.configuration()).customCss, isNull);
      expect(await client.localization.countries(), isEmpty);
      expect(
        await client.playlists.userAccess(playlistId: 'p', userId: 'u'),
        isNull,
      );
    });

    test('a list answer of the wrong shape is a parse error', () async {
      adapter.respond = (_) => CannedResponse.json({'not': 'a list'});
      await expectLater(
        client.localization.cultures(),
        throwsA(
          isA<JellyfinException>().having(
            (e) => e.type,
            'type',
            JellyfinErrorType.parse,
          ),
        ),
      );
    });

    test('videos.additionalParts answers a page of items', () async {
      adapter.respond = (_) => CannedResponse.json({
        'Items': [
          {'Id': 'part2', 'Name': 'CD2', 'Type': 'Movie'},
        ],
        'TotalRecordCount': 1,
      });
      final parts = await client.videos.additionalParts(itemId: 'm1');
      expect(parts.items.single.id, 'part2');
      expect(parts.totalRecordCount, 1);
    });

    test('subtitles.getRemote answers the subtitle text', () async {
      adapter.respond = (_) => CannedResponse(
        200,
        utf8.encode('1\n00:00:01,000 --> 00:00:02,000\nPerché sì\n'),
        contentType: 'text/plain; charset=utf-8',
      );
      expect(
        await client.subtitles.getRemote(id: 'os-1'),
        contains('Perché sì'),
      );
      expect(adapter.path, '/Providers/Subtitles/Subtitles/os-1');
      adapter.respond = (_) =>
          CannedResponse.json({'title': 'Not Found'}, status: 404);
      expect(await client.subtitles.getRemote(id: 'none'), isNull);
    });

    test('collection.create answers the new id', () async {
      adapter.respond = (_) => CannedResponse.json({'Id': 'box1'});
      final created = await client.collection.create(name: 'Saga');
      expect(created.id, 'box1');
      expect(adapter.last!.method, 'POST');
    });
  });
}
