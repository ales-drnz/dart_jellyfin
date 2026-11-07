// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The live TV models, decoded from bodies shaped like Jellyfin 12.4 answers.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const Map<String, Object?> _empty = {};

void main() {
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
}
