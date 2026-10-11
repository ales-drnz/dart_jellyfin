// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Typed server events, decoded from the `/socket` notification stream.
///
/// The shapes follow frames captured from Jellyfin 12.2 (fixtures in
/// `test/fixtures/notifications/`), not only the API document: every frame
/// carries a `MessageId`, `RefreshProgress` sends its progress as a string,
/// `UserDataChanged` for a track also carries its album's entry, and an
/// entry leaves `LastPlayedDate` out (rather than sending `null`) once the
/// item is marked unplayed.
library;

import 'api/jellyfin_notifications_api.dart';
import 'jellyfin_models.dart';
import 'jellyfin_server_models.dart';

/// One frame of the notification stream, typed by its `MessageType`.
/// Switch over the subtypes:
///
/// ```dart
/// final socket = await jf.notifications.connect();
/// jf.notifications.startSessions();
/// socket.events().listen((event) {
///   switch (event) {
///     case JellyfinUserDataChangedEvent(:final changes):
///       for (final c in changes) {
///         cache.setFavorite(c.itemId, c.isFavorite);
///       }
///     case JellyfinLibraryChangedEvent(:final itemsRemoved):
///       cache.dropAll(itemsRemoved);
///     case JellyfinSessionsEvent(:final sessions):
///       nowPlaying.update(sessions);
///     case JellyfinPlaystateEvent(command: JellyfinPlaystateCommand.pause):
///       player.pause();
///     case _:
///   }
/// });
/// ```
///
/// Decoding never throws: a known `MessageType` whose `Data` has the wrong
/// shape becomes a [JellyfinUnknownEvent] too, so one malformed frame
/// cannot end a listener.
sealed class JellyfinEvent {
  /// The whole frame as the server sent it (`MessageType`, `MessageId`,
  /// `Data`).
  final Map<String, Object?> raw;

  /// Wraps a decoded frame; the subtypes are built by [fromFrame].
  const JellyfinEvent(this.raw);

  /// The frame's `MessageId`, unique per frame; `null` when not sent.
  String? get messageId => _str(raw['MessageId']);

  /// Decodes [notification]; same as `notification.event`.
  static JellyfinEvent fromNotification(JellyfinNotification notification) =>
      fromFrame(notification.raw);

  /// Decodes one `{MessageType, MessageId, Data}` frame.
  static JellyfinEvent fromFrame(Map<String, Object?> frame) {
    final type = _str(frame['MessageType']) ?? 'Unknown';
    try {
      return _decode(type, frame) ?? JellyfinUnknownEvent(type, frame);
    } on Object {
      return JellyfinUnknownEvent(type, frame);
    }
  }

  static JellyfinEvent? _decode(String type, Map<String, Object?> frame) {
    final data = frame['Data'];
    final map = data is Map<String, Object?> ? data : null;
    final list = data is List<Object?> ? data : null;
    return switch (type) {
      'UserDataChanged' when map != null =>
        JellyfinUserDataChangedEvent._(frame, map),
      'LibraryChanged' when map != null =>
        JellyfinLibraryChangedEvent._(frame, map),
      'Sessions' when list != null => JellyfinSessionsEvent._(frame, list),
      'Play' when map != null => JellyfinPlayEvent._(frame, map),
      'Playstate' when map != null => JellyfinPlaystateEvent._(frame, map),
      'GeneralCommand' when map != null =>
        JellyfinGeneralCommandEvent._(frame, map),
      'RefreshProgress' when map != null =>
        JellyfinRefreshProgressEvent._(frame, map),
      'ScheduledTasksInfo' when list != null =>
        JellyfinScheduledTasksInfoEvent._(frame, list),
      'ScheduledTaskEnded' when map != null =>
        JellyfinScheduledTaskEndedEvent._(frame, map),
      'KeepAlive' || 'ForceKeepAlive' => JellyfinKeepAliveEvent._(frame, type),
      _ => null,
    };
  }
}

/// `UserDataChanged`: the favourite, played state, play count or resume
/// position of one or more items changed for [userId] — from this client,
/// another client, or playback reports.
///
/// A change on a track also carries an entry for its album (the album's
/// aggregate user data), so match entries by [JellyfinUserDataChange.itemId]
/// rather than taking the first one.
final class JellyfinUserDataChangedEvent extends JellyfinEvent {
  /// The user whose data changed.
  final String userId;

  /// One entry per changed item (`UserDataList`).
  final List<JellyfinUserDataChange> changes;

  JellyfinUserDataChangedEvent._(super.raw, Map<String, Object?> data)
      : userId = _str(data['UserId']) ?? '',
        changes = [
          if (data['UserDataList'] is List)
            for (final e in data['UserDataList'] as List)
              if (e is Map<String, Object?>) JellyfinUserDataChange.fromJson(e),
        ];

  /// The entry for [itemId], or `null` when the frame has none.
  JellyfinUserDataChange? forItem(String itemId) {
    for (final c in changes) {
      if (c.itemId == itemId) return c;
    }
    return null;
  }
}

/// One item's new user data inside a [JellyfinUserDataChangedEvent] (a
/// `UserItemDataDto` with its `ItemId`).
final class JellyfinUserDataChange {
  /// The item.
  final String itemId;

  /// The item's user data after the change.
  final JellyfinUserData userData;

  /// The entry as the server sent it.
  final Map<String, Object?> raw;

  /// Builds a change from already-parsed components.
  const JellyfinUserDataChange({
    required this.itemId,
    required this.userData,
    required this.raw,
  });

  /// Decodes a `UserDataList` entry.
  factory JellyfinUserDataChange.fromJson(Map<String, Object?> json) =>
      JellyfinUserDataChange(
        itemId: _str(json['ItemId']) ?? '',
        userData: JellyfinUserData.fromJson(json),
        raw: json,
      );

  /// `IsFavorite`.
  bool get isFavorite => userData.isFavorite;

  /// `Played`.
  bool get played => userData.played;

  /// `PlayCount`.
  int get playCount => userData.playCount;

  /// `PlaybackPositionTicks` (10 000 per millisecond).
  int? get playbackPositionTicks => userData.playbackPositionTicks;

  /// `LastPlayedDate`; `null` once the item is marked unplayed.
  DateTime? get lastPlayedDate => userData.lastPlayedDate;

  /// `Likes`: `true` like, `false` dislike, `null` unrated (left out of the
  /// frame until set).
  bool? get likes => userData.likes;

  /// `Rating`, the user's star rating; left out of the frame until set.
  double? get rating => _double(raw['Rating']);
}

/// `LibraryChanged`: items were added, updated or removed. The server
/// batches changes and sends this some seconds after the last one (about
/// 30 s on 12.2), so it is a cache-invalidation signal, not a live feed.
final class JellyfinLibraryChangedEvent extends JellyfinEvent {
  /// `ItemsAdded`.
  final List<String> itemsAdded;

  /// `ItemsUpdated` — includes metadata edits and refreshes.
  final List<String> itemsUpdated;

  /// `ItemsRemoved`.
  final List<String> itemsRemoved;

  /// `FoldersAddedTo` — folders that gained children.
  final List<String> foldersAddedTo;

  /// `FoldersRemovedFrom` — folders that lost children.
  final List<String> foldersRemovedFrom;

  /// `CollectionFolders` — libraries whose contents changed.
  final List<String> collectionFolders;

  JellyfinLibraryChangedEvent._(super.raw, Map<String, Object?> data)
      : itemsAdded = _strList(data['ItemsAdded']),
        itemsUpdated = _strList(data['ItemsUpdated']),
        itemsRemoved = _strList(data['ItemsRemoved']),
        foldersAddedTo = _strList(data['FoldersAddedTo']),
        foldersRemovedFrom = _strList(data['FoldersRemovedFrom']),
        collectionFolders = _strList(data['CollectionFolders']);

  /// No id in any list.
  bool get isEmpty =>
      itemsAdded.isEmpty &&
      itemsUpdated.isEmpty &&
      itemsRemoved.isEmpty &&
      foldersAddedTo.isEmpty &&
      foldersRemovedFrom.isEmpty &&
      collectionFolders.isEmpty;
}

/// `Sessions`: the active sessions, after
/// `JellyfinNotificationsApi.startSessions`. The server sends a frame when
/// a session changes (playback start, progress, stop, capabilities), not on
/// every interval tick.
final class JellyfinSessionsEvent extends JellyfinEvent {
  /// Every active session the server lists, as `/Sessions` would.
  final List<JellyfinSession> sessions;

  JellyfinSessionsEvent._(super.raw, List<Object?> data)
      : sessions = [
          for (final e in data)
            if (e is Map<String, Object?>) JellyfinSession.fromJson(e),
        ];
}

/// `Play`: another client asked this one to play items
/// (`JellyfinSessionsApi.play`). Arrives on the socket of the session that
/// owns this access token.
final class JellyfinPlayEvent extends JellyfinEvent {
  /// The items to play, in order.
  final List<String> itemIds;

  /// `PlayNow`, `PlayNext`, … (see `JellyfinPlayCommand`).
  final String playCommand;

  /// Where to start the first item, in ticks.
  final int? startPositionTicks;

  /// Index into [itemIds] to start from.
  final int? startIndex;

  /// The media source to play.
  final String? mediaSourceId;

  /// The audio stream to select.
  final int? audioStreamIndex;

  /// The subtitle stream to select.
  final int? subtitleStreamIndex;

  /// The user who sent the command.
  final String? controllingUserId;

  JellyfinPlayEvent._(super.raw, Map<String, Object?> data)
      : itemIds = _strList(data['ItemIds']),
        playCommand = _str(data['PlayCommand']) ?? '',
        startPositionTicks = _int(data['StartPositionTicks']),
        startIndex = _int(data['StartIndex']),
        mediaSourceId = _str(data['MediaSourceId']),
        audioStreamIndex = _int(data['AudioStreamIndex']),
        subtitleStreamIndex = _int(data['SubtitleStreamIndex']),
        controllingUserId = _str(data['ControllingUserId']);
}

/// `Playstate`: another client asked this one to pause, stop, seek, skip, …
/// (`JellyfinSessionsApi.sendPlaystateCommand`).
final class JellyfinPlaystateEvent extends JellyfinEvent {
  /// `Pause`, `Seek`, `NextTrack`, … (see `JellyfinPlaystateCommand`).
  final String command;

  /// The target position for `Seek`, in ticks.
  final int? seekPositionTicks;

  /// The user who sent the command.
  final String? controllingUserId;

  JellyfinPlaystateEvent._(super.raw, Map<String, Object?> data)
      : command = _str(data['Command']) ?? '',
        seekPositionTicks = _int(data['SeekPositionTicks']),
        controllingUserId = _str(data['ControllingUserId']);

  /// [seekPositionTicks] as a [Duration].
  Duration? get seekPosition => seekPositionTicks == null
      ? null
      : Duration(microseconds: seekPositionTicks! ~/ 10);
}

/// `GeneralCommand`: another client sent a command such as `SetVolume` or
/// `DisplayMessage` (`JellyfinSessionsApi.sendCommand` / `sendFullCommand`).
final class JellyfinGeneralCommandEvent extends JellyfinEvent {
  /// The command (see `JellyfinGeneralCommand`).
  final String name;

  /// The command's arguments; the server sends every value as a string
  /// (`{"Volume": "50"}`).
  final Map<String, String?> arguments;

  /// The user who sent the command.
  final String? controllingUserId;

  JellyfinGeneralCommandEvent._(super.raw, Map<String, Object?> data)
      : name = _str(data['Name']) ?? '',
        arguments = {
          if (data['Arguments'] is Map)
            for (final e in (data['Arguments'] as Map).entries)
              '${e.key}': _str(e.value),
        },
        controllingUserId = _str(data['ControllingUserId']);
}

/// `RefreshProgress`: a library (or the root folder) is being refreshed.
/// Sent for collection folders, not for single tracks or albums.
final class JellyfinRefreshProgressEvent extends JellyfinEvent {
  /// The folder being refreshed.
  final String itemId;

  /// 0–100. The server sends it as a string (`"100"`); `null` when it
  /// cannot be read.
  final double? progress;

  JellyfinRefreshProgressEvent._(super.raw, Map<String, Object?> data)
      : itemId = _str(data['ItemId']) ?? '',
        progress = _double(data['Progress']);

  /// The refresh reached 100.
  bool get isDone => progress != null && progress! >= 100;
}

/// `ScheduledTasksInfo`: every scheduled task with its state, after
/// `JellyfinNotificationsApi.startScheduledTasks`. Sent when a task's state
/// or progress changes. Admin only.
final class JellyfinScheduledTasksInfoEvent extends JellyfinEvent {
  /// The tasks, as `JellyfinScheduledTasksApi.list` returns them.
  final List<JellyfinScheduledTask> tasks;

  JellyfinScheduledTasksInfoEvent._(super.raw, List<Object?> data)
      : tasks = [
          for (final e in data)
            if (e is Map<String, Object?>) JellyfinScheduledTask.fromJson(e),
        ];

  /// The tasks whose state is `Running`.
  Iterable<JellyfinScheduledTask> get running =>
      tasks.where((t) => t.state == 'Running');
}

/// `ScheduledTaskEnded`: a scheduled task finished. Listed by the API
/// document for admin sessions; 12.2 did not send it to a socket in our
/// captures, so watch [JellyfinScheduledTasksInfoEvent] for a task going
/// back to `Idle` instead.
final class JellyfinScheduledTaskEndedEvent extends JellyfinEvent {
  /// The run's result (`TaskResult`, the same shape as a task's
  /// `LastExecutionResult`).
  final JellyfinTaskResult result;

  JellyfinScheduledTaskEndedEvent._(super.raw, Map<String, Object?> data)
      : result = JellyfinTaskResult.fromJson(data);

  /// The task's key, e.g. `RefreshLibrary`.
  String? get key => _str(result.raw['Key']);

  /// The task's id.
  String? get taskId => _str(result.raw['Id']);
}

/// `KeepAlive` (the answer to this client's keep-alive) or `ForceKeepAlive`
/// (sent once on connect: the server's inactivity timeout).
final class JellyfinKeepAliveEvent extends JellyfinEvent {
  /// `true` for `ForceKeepAlive`.
  final bool isForced;

  /// For `ForceKeepAlive`, how long the server waits for a keep-alive
  /// before closing the socket (60 s on 12.2); `null` for `KeepAlive`.
  final Duration? timeout;

  JellyfinKeepAliveEvent._(super.raw, String type)
      : isForced = type == 'ForceKeepAlive',
        timeout = switch (_int(raw['Data'])) {
          final int s => Duration(seconds: s),
          null => null,
        };
}

/// A frame without a typed event (`UserUpdated`, `ActivityLogEntry`,
/// `SyncPlayGroupUpdate`, `TimerCreated`, `RestartRequired`, …), or a known
/// one whose `Data` has an unexpected shape. [raw] is the whole frame.
final class JellyfinUnknownEvent extends JellyfinEvent {
  /// The frame's `MessageType`.
  final String messageType;

  /// Wraps a frame of [messageType].
  const JellyfinUnknownEvent(this.messageType, super.raw);

  /// The frame's `Data`.
  Object? get data => raw['Data'];
}

String? _str(Object? v) => v == null ? null : '$v';

int? _int(Object? v) => switch (v) {
      int() => v,
      double() => v.toInt(),
      String() => int.tryParse(v),
      _ => null,
    };

double? _double(Object? v) => switch (v) {
      double() => v,
      int() => v.toDouble(),
      String() => double.tryParse(v),
      _ => null,
    };

List<String> _strList(Object? v) => [
      if (v is List)
        for (final e in v)
          if (e != null) '$e',
    ];
