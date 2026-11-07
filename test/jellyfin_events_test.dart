// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// [JellyfinEvent] against real, anonymised `/socket` frames captured from
/// Jellyfin 12.2 (`test/fixtures/notifications/`): user ids, session ids,
/// device and user names, addresses and message ids replaced; item and task
/// ids are the seeded library's.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const _user = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _track = 'b5455b2dcaf64392527a5ae01dd1523f';
const _album = '72839210ba8018a1bf1039f340953486';

JellyfinNotification _frame(String name) => JellyfinNotification.fromJson(
  jsonDecode(
        File('test/fixtures/notifications/$name.json').readAsStringSync(),
      )
      as Map<String, Object?>,
);

T _event<T extends JellyfinEvent>(String name) {
  final event = _frame(name).event;
  expect(event, isA<T>());
  return event as T;
}

void main() {
  group('UserDataChanged', () {
    test('a favourite carries the track and its album', () {
      final e = _event<JellyfinUserDataChangedEvent>(
        'user_data_changed_favorite',
      );
      expect(e.userId, _user);
      expect(e.messageId, isNotNull);
      expect(e.changes.map((c) => c.itemId), [_track, _album]);
      final track = e.forItem(_track)!;
      expect(track.isFavorite, isTrue);
      expect(track.played, isTrue);
      expect(track.playCount, 1);
      expect(track.playbackPositionTicks, 0);
      expect(
        track.lastPlayedDate,
        DateTime.utc(2026, 10, 11, 15, 45, 4, 823, 214),
      );
      expect(track.likes, isNull);
      expect(track.rating, isNull);
      expect(track.userData.key, isNotEmpty);
      expect(e.forItem(_album)!.isFavorite, isFalse);
      expect(e.forItem('missing'), isNull);
    });

    test('marked unplayed: no LastPlayedDate, count reset', () {
      final e = _event<JellyfinUserDataChangedEvent>(
        'user_data_changed_unplayed',
      );
      final track = e.forItem(_track)!;
      expect(track.raw.containsKey('LastPlayedDate'), isFalse);
      expect(track.lastPlayedDate, isNull);
      expect(track.played, isFalse);
      expect(track.playCount, 0);
    });
  });

  test('LibraryChanged lists the updated item', () {
    final e = _event<JellyfinLibraryChangedEvent>('library_changed');
    expect(e.itemsUpdated, [_track]);
    expect(e.itemsAdded, isEmpty);
    expect(e.itemsRemoved, isEmpty);
    expect(e.foldersAddedTo, isEmpty);
    expect(e.foldersRemovedFrom, isEmpty);
    expect(e.collectionFolders, isEmpty);
    expect(e.isEmpty, isFalse);
  });

  test('Sessions decodes JellyfinSession with the now-playing track', () {
    final e = _event<JellyfinSessionsEvent>('sessions_playing');
    expect(e.sessions, hasLength(2));
    final playing = e.sessions.firstWhere((s) => s.isPlaying);
    expect(playing.userId, _user);
    expect(playing.deviceId, 'test-device');
    expect(playing.nowPlayingItem!.id, _track);
    expect(playing.nowPlayingItem!.isAudio, isTrue);
    expect(playing.playState!['IsPaused'], isFalse);
    expect(e.sessions.where((s) => !s.isPlaying), hasLength(1));
  });

  test('Play', () {
    final e = _event<JellyfinPlayEvent>('play');
    expect(e.itemIds, [_track]);
    expect(e.playCommand, JellyfinPlayCommand.playNow);
    expect(e.startPositionTicks, 10000000);
    expect(e.startIndex, isNull);
    expect(e.controllingUserId, _user);
  });

  test('Playstate: pause and seek', () {
    final pause = _event<JellyfinPlaystateEvent>('playstate_pause');
    expect(pause.command, JellyfinPlaystateCommand.pause);
    expect(pause.seekPositionTicks, isNull);
    expect(pause.seekPosition, isNull);
    expect(pause.controllingUserId, _user);

    final seek = _event<JellyfinPlaystateEvent>('playstate_seek');
    expect(seek.command, JellyfinPlaystateCommand.seek);
    expect(seek.seekPositionTicks, 20000000);
    expect(seek.seekPosition, const Duration(seconds: 2));
  });

  test('GeneralCommand arguments are strings', () {
    final e = _event<JellyfinGeneralCommandEvent>('general_command');
    expect(e.name, JellyfinGeneralCommand.setVolume);
    expect(e.arguments, {'Volume': '50'});
    expect(e.controllingUserId, _user);
  });

  test('RefreshProgress sends progress as a string', () {
    final e = _event<JellyfinRefreshProgressEvent>('refresh_progress');
    expect(e.raw['Data'], containsPair('Progress', '100'));
    expect(e.itemId, isNotEmpty);
    expect(e.progress, 100);
    expect(e.isDone, isTrue);
  });

  test('ScheduledTasksInfo decodes JellyfinScheduledTask', () {
    final e = _event<JellyfinScheduledTasksInfoEvent>(
      'scheduled_tasks_info_running',
    );
    expect(e.tasks.length, greaterThan(10));
    expect(e.running.map((t) => t.key), ['DeleteTranscodeFiles']);
    final normalization = e.tasks.firstWhere(
      (t) => t.key == 'AudioNormalization',
    );
    expect(normalization.lastExecutionResult!.status, 'Completed');
  });

  test('ScheduledTaskEnded decodes the TaskResult', () {
    // Not captured from 12.2 (see JellyfinScheduledTaskEndedEvent); the
    // payload is a task's LastExecutionResult, which is.
    final info = _event<JellyfinScheduledTasksInfoEvent>(
      'scheduled_tasks_info_running',
    );
    final last = info.tasks
        .firstWhere((t) => t.key == 'AudioNormalization')
        .lastExecutionResult!
        .raw;
    final e = JellyfinEvent.fromFrame({
      'MessageType': 'ScheduledTaskEnded',
      'Data': last,
    });
    expect(e, isA<JellyfinScheduledTaskEndedEvent>());
    e as JellyfinScheduledTaskEndedEvent;
    expect(e.key, 'AudioNormalization');
    expect(e.taskId, isNotEmpty);
    expect(e.result.status, 'Completed');
    expect(e.result.endTime, isNotNull);
  });

  test('ForceKeepAlive carries the timeout; KeepAlive nothing', () {
    final forced = _event<JellyfinKeepAliveEvent>('force_keep_alive');
    expect(forced.isForced, isTrue);
    expect(forced.timeout, const Duration(seconds: 60));
    final ka = _event<JellyfinKeepAliveEvent>('keep_alive');
    expect(ka.isForced, isFalse);
    expect(ka.timeout, isNull);
  });

  group('fallback', () {
    test('an unknown type becomes JellyfinUnknownEvent with the frame', () {
      final frame = <String, Object?>{
        'MessageType': 'SomethingNew',
        'MessageId': '1',
        'Data': {'Id': _user},
      };
      final e = JellyfinEvent.fromFrame(frame);
      expect(e, isA<JellyfinUnknownEvent>());
      e as JellyfinUnknownEvent;
      expect(e.messageType, 'SomethingNew');
      expect(e.raw, same(frame));
      expect(e.data, {'Id': _user});
      expect(e.messageId, '1');
    });

    test('a known type with a malformed payload becomes unknown', () {
      for (final frame in <Map<String, Object?>>[
        {'MessageType': 'UserDataChanged', 'Data': 'nope'},
        {'MessageType': 'Sessions', 'Data': <String, Object?>{}},
        {'MessageType': 'LibraryChanged'},
        {'MessageType': 'ScheduledTasksInfo', 'Data': 42},
        {'MessageType': 'UserDeleted', 'Data': <String, Object?>{}},
        {'MessageType': 'SyncPlayCommand', 'Data': 'nope'},
        {'MessageType': 'ActivityLogEntry', 'Data': <String, Object?>{}},
        {'MessageType': 'TimerCreated'},
      ]) {
        final e = JellyfinEvent.fromFrame(frame);
        expect(e, isA<JellyfinUnknownEvent>(), reason: '$frame');
        expect((e as JellyfinUnknownEvent).messageType, frame['MessageType']);
      }
    });

    test('odd entries inside a payload are skipped, not thrown', () {
      final e =
          JellyfinEvent.fromFrame({
                'MessageType': 'UserDataChanged',
                'Data': {
                  'UserId': _user,
                  'UserDataList': [
                    'nope',
                    null,
                    {'ItemId': _track, 'IsFavorite': true, 'PlayCount': 'x'},
                  ],
                },
              })
              as JellyfinUserDataChangedEvent;
      expect(e.changes.single.isFavorite, isTrue);
      expect(e.changes.single.playCount, 0);
    });

    test('events() keeps going past a malformed frame', () async {
      final events = await Stream.fromIterable([
        JellyfinNotification.fromJson(const {'MessageType': 'Playstate'}),
        JellyfinNotification.fromJson(const {
          'MessageType': 'Sessions',
          'Data': 'not a list',
        }),
        _frame('playstate_pause'),
      ]).events().toList();
      expect(events, hasLength(3));
      expect(events[0], isA<JellyfinUnknownEvent>());
      expect(events[1], isA<JellyfinUnknownEvent>());
      expect(events[2], isA<JellyfinPlaystateEvent>());
    });
  });

  // Frames shaped after the API document's *Message schemas: a test server
  // rarely sends these, so there are no captures.
  JellyfinEvent ev(String type, [Object? data]) => JellyfinEvent.fromFrame({
    'MessageType': type,
    'MessageId': 'm1',
    'Data': ?data,
  });

  group('documented frames', () {
    test('SyncPlayCommand', () {
      final e =
          ev('SyncPlayCommand', {
                'GroupId': 'g1',
                'PlaylistItemId': 'p1',
                'When': '2026-11-07T10:00:00.0000000Z',
                'PositionTicks': 50000000,
                'Command': 'Seek',
                'EmittedAt': '2026-11-07T09:59:59.5000000Z',
              })
              as JellyfinSyncPlayCommandEvent;
      expect(e.groupId, 'g1');
      expect(e.playlistItemId, 'p1');
      expect(e.command, 'Seek');
      expect(e.when, DateTime.utc(2026, 11, 7, 10));
      expect(e.position, const Duration(seconds: 5));
      expect(e.emittedAt!.isBefore(e.when!), isTrue);
    });

    test('SyncPlayGroupUpdate', () {
      final joined =
          ev('SyncPlayGroupUpdate', {
                'GroupId': 'g1',
                'Type': 'GroupJoined',
                'Data': {
                  'GroupId': 'g1',
                  'GroupName': 'Movie night',
                  'State': 'Idle',
                  'Participants': ['alice'],
                  'LastUpdatedAt': '2026-11-07T10:00:00Z',
                },
              })
              as JellyfinSyncPlayGroupUpdateEvent;
      expect(joined.updateType, 'GroupJoined');
      expect(joined.group!.name, 'Movie night');
      expect(joined.userName, isNull);

      final user =
          ev('SyncPlayGroupUpdate', {
                'GroupId': 'g1',
                'Type': 'UserJoined',
                'Data': 'bob',
              })
              as JellyfinSyncPlayGroupUpdateEvent;
      expect(user.userName, 'bob');
      expect(user.group, isNull);

      final state =
          ev('SyncPlayGroupUpdate', {
                'GroupId': 'g1',
                'Type': 'StateUpdate',
                'Data': {'State': 'Waiting', 'Reason': 'Buffer'},
              })
              as JellyfinSyncPlayGroupUpdateEvent;
      expect(state.state, 'Waiting');
      expect(state.reason, 'Buffer');
    });

    test('UserUpdated and UserDeleted', () {
      final updated =
          ev('UserUpdated', {'Id': _user, 'Name': 'alice'})
              as JellyfinUserUpdatedEvent;
      expect(updated.user.id, _user);
      expect(updated.user.name, 'alice');
      final deleted = ev('UserDeleted', _user) as JellyfinUserDeletedEvent;
      expect(deleted.userId, _user);
    });

    test('server state frames carry no data', () {
      expect(ev('RestartRequired'), isA<JellyfinRestartRequiredEvent>());
      expect(ev('ServerRestarting'), isA<JellyfinServerRestartingEvent>());
      expect(
        ev('ServerShuttingDown'),
        isA<JellyfinServerShuttingDownEvent>(),
      );
    });

    test('timer frames', () {
      final created =
          ev('TimerCreated', {'Id': 't1', 'ProgramId': 'p1'})
              as JellyfinTimerEvent;
      expect(created.timerId, 't1');
      expect(created.programId, 'p1');
      expect(created.isSeriesTimer, isFalse);
      expect(created.isCancelled, isFalse);
      final series =
          ev('SeriesTimerCancelled', {'Id': 's1'}) as JellyfinTimerEvent;
      expect(series.isSeriesTimer, isTrue);
      expect(series.isCancelled, isTrue);
      expect(series.programId, isNull);
    });

    test('plugin frames', () {
      const info = {
        'Guid': 'a4df60c5-6ab4-412a-8f79-2cab93fb2bc5',
        'Name': 'Open Subtitles',
        'Version': '20.0.0.0',
        'SourceUrl': 'https://repo.jellyfin.org/x.zip',
      };
      for (final (type, check)
          in <(String, bool Function(JellyfinPluginInstallationEvent))>[
            ('PackageInstalling', (e) => e.isInstalling),
            ('PackageInstallationCompleted', (e) => e.isCompleted),
            ('PackageInstallationFailed', (e) => e.isFailed),
            ('PackageInstallationCancelled', (e) => e.isCancelled),
          ]) {
        final e = ev(type, info) as JellyfinPluginInstallationEvent;
        expect(check(e), isTrue, reason: type);
        expect(e.messageType, type);
        expect(e.pluginId, info['Guid']);
        expect(e.name, 'Open Subtitles');
        expect(e.version, '20.0.0.0');
      }
      final removed =
          ev('PackageUninstalled', {
                'Id': 'a4df60c5-6ab4-412a-8f79-2cab93fb2bc5',
                'Name': 'Open Subtitles',
                'Version': '20.0.0.0',
                'CanUninstall': true,
                'Status': 'Active',
              })
              as JellyfinPluginUninstalledEvent;
      expect(removed.plugin.name, 'Open Subtitles');
    });

    test('ActivityLogEntry', () {
      final e =
          ev('ActivityLogEntry', [
                {
                  'Id': 7,
                  'Name': 'alice is online from Web',
                  'Type': 'SessionStarted',
                  'Date': '2026-11-07T10:00:00Z',
                  'UserId': _user,
                  'Severity': 'Information',
                },
                'skipped',
              ])
              as JellyfinActivityLogEvent;
      expect(e.entries.single.name, 'alice is online from Web');
    });
  });
}
