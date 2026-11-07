// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The metadata lookup, remote subtitle and library models, decoded from bodies shaped like Jellyfin 12.4 answers.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const Map<String, Object?> _empty = {};

void main() {
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
}
