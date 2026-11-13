// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Typed server events, decoded from the `/socket` notification stream.
///
/// The shapes follow frames captured from Jellyfin 12.2 (fixtures in
/// `test/fixtures/notifications/`) where there are captures, and the API
/// document otherwise (SyncPlay, users, timers, plugins, server state and
/// the activity log, which a test server rarely sends): every frame
/// carries a `MessageId`, `RefreshProgress` sends its progress as a string,
/// `UserDataChanged` for a track also carries its album's entry, and an
/// entry leaves `LastPlayedDate` out (rather than sending `null`) once the
/// item is marked unplayed.
library;

import 'api/jellyfin_notifications_api.dart';
import 'jellyfin_json.dart';
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
///
/// {@category Events and downloads}
sealed class JellyfinEvent {
  /// The whole frame as the server sent it (`MessageType`, `MessageId`,
  /// `Data`).
  final Map<String, Object?> raw;

  /// Wraps a decoded frame; the subtypes are built by [fromFrame].
  const JellyfinEvent(this.raw);

  /// The frame's `MessageId`, unique per frame; `null` when not sent.
  String? get messageId => asString(raw['MessageId']);

  /// Decodes [notification]; same as `notification.event`.
  static JellyfinEvent fromNotification(JellyfinNotification notification) =>
      fromFrame(notification.raw);

  /// Decodes one `{MessageType, MessageId, Data}` frame.
  static JellyfinEvent fromFrame(Map<String, Object?> frame) {
    final type = asString(frame['MessageType']) ?? 'Unknown';
    try {
      return _decode(type, frame) ??
          JellyfinUnknownEvent(type, frame, isMalformed: _typed.contains(type));
    } on Object {
      return JellyfinUnknownEvent(type, frame, isMalformed: true);
    }
  }

  /// Every `MessageType` with a typed event: one of these in a
  /// [JellyfinUnknownEvent] means its `Data` had the wrong shape.
  static const _typed = {
    'UserDataChanged',
    'LibraryChanged',
    'Sessions',
    'Play',
    'Playstate',
    'GeneralCommand',
    'RefreshProgress',
    'ScheduledTasksInfo',
    'ScheduledTaskEnded',
    'KeepAlive',
    'ForceKeepAlive',
    'SyncPlayCommand',
    'SyncPlayGroupUpdate',
    'UserUpdated',
    'UserDeleted',
    'RestartRequired',
    'ServerRestarting',
    'ServerShuttingDown',
    'TimerCreated',
    'TimerCancelled',
    'SeriesTimerCreated',
    'SeriesTimerCancelled',
    'PackageInstalling',
    'PackageInstallationCompleted',
    'PackageInstallationFailed',
    'PackageInstallationCancelled',
    'PackageUninstalled',
    'ActivityLogEntry',
  };

  static JellyfinEvent? _decode(String type, Map<String, Object?> frame) {
    final data = frame['Data'];
    final map = data is Map<String, Object?> ? data : null;
    final list = data is List<Object?> ? data : null;
    return switch (type) {
      'UserDataChanged' when map != null => JellyfinUserDataChangedEvent._(
        frame,
        map,
      ),
      'LibraryChanged' when map != null => JellyfinLibraryChangedEvent._(
        frame,
        map,
      ),
      'Sessions' when list != null => JellyfinSessionsEvent._(frame, list),
      'Play' when map != null => JellyfinPlayEvent._(frame, map),
      'Playstate' when map != null => JellyfinPlaystateEvent._(frame, map),
      'GeneralCommand' when map != null => JellyfinGeneralCommandEvent._(
        frame,
        map,
      ),
      'RefreshProgress' when map != null => JellyfinRefreshProgressEvent._(
        frame,
        map,
      ),
      'ScheduledTasksInfo' when list != null =>
        JellyfinScheduledTasksInfoEvent._(frame, list),
      'ScheduledTaskEnded' when map != null =>
        JellyfinScheduledTaskEndedEvent._(frame, map),
      'KeepAlive' || 'ForceKeepAlive' => JellyfinKeepAliveEvent._(frame, type),
      'SyncPlayCommand' when map != null => JellyfinSyncPlayCommandEvent._(
        frame,
        map,
      ),
      'SyncPlayGroupUpdate' when map != null =>
        JellyfinSyncPlayGroupUpdateEvent._(frame, map),
      'UserUpdated' when map != null => JellyfinUserUpdatedEvent._(frame, map),
      'UserDeleted' when data is String => JellyfinUserDeletedEvent._(
        frame,
        data,
      ),
      'RestartRequired' => JellyfinRestartRequiredEvent._(frame),
      'ServerRestarting' => JellyfinServerRestartingEvent._(frame),
      'ServerShuttingDown' => JellyfinServerShuttingDownEvent._(frame),
      'TimerCreated' ||
      'TimerCancelled' ||
      'SeriesTimerCreated' ||
      'SeriesTimerCancelled' when map != null => JellyfinTimerEvent._(
        frame,
        type,
        map,
      ),
      'PackageInstalling' ||
      'PackageInstallationCompleted' ||
      'PackageInstallationFailed' ||
      'PackageInstallationCancelled' when map != null =>
        JellyfinPluginInstallationEvent._(frame, type, map),
      'PackageUninstalled' when map != null => JellyfinPluginUninstalledEvent._(
        frame,
        map,
      ),
      'ActivityLogEntry' when list != null => JellyfinActivityLogEvent._(
        frame,
        list,
      ),
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
    : userId = asString(data['UserId']) ?? '',
      changes = asObjectList(
        data['UserDataList'],
        JellyfinUserDataChange.fromJson,
      );

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
        itemId: asString(json['ItemId']) ?? '',
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
  double? get rating => userData.rating;
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
    : itemsAdded = asStringList(data['ItemsAdded']),
      itemsUpdated = asStringList(data['ItemsUpdated']),
      itemsRemoved = asStringList(data['ItemsRemoved']),
      foldersAddedTo = asStringList(data['FoldersAddedTo']),
      foldersRemovedFrom = asStringList(data['FoldersRemovedFrom']),
      collectionFolders = asStringList(data['CollectionFolders']);

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
    : sessions = asObjectList(data, JellyfinSession.fromJson);
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
    : itemIds = asStringList(data['ItemIds']),
      playCommand = asString(data['PlayCommand']) ?? '',
      startPositionTicks = asInt(data['StartPositionTicks']),
      startIndex = asInt(data['StartIndex']),
      mediaSourceId = asString(data['MediaSourceId']),
      audioStreamIndex = asInt(data['AudioStreamIndex']),
      subtitleStreamIndex = asInt(data['SubtitleStreamIndex']),
      controllingUserId = asString(data['ControllingUserId']);
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
    : command = asString(data['Command']) ?? '',
      seekPositionTicks = asInt(data['SeekPositionTicks']),
      controllingUserId = asString(data['ControllingUserId']);

  /// [seekPositionTicks] as a [Duration].
  Duration? get seekPosition => asTicksDuration(seekPositionTicks);
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
    : name = asString(data['Name']) ?? '',
      arguments = {
        if (data['Arguments'] is Map)
          for (final e in (data['Arguments'] as Map).entries)
            '${e.key}': asString(e.value),
      },
      controllingUserId = asString(data['ControllingUserId']);
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
    : itemId = asString(data['ItemId']) ?? '',
      progress = asDouble(data['Progress']);

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
    : tasks = asObjectList(data, JellyfinScheduledTask.fromJson);

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
  String? get key => result.key;

  /// The task's id.
  String? get taskId => result.id;
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
      timeout = switch (asInt(raw['Data'])) {
        final int s => Duration(seconds: s),
        null => null,
      };
}

/// `SyncPlayCommand`: the SyncPlay group asks this client to play, pause,
/// stop or seek at a given time, so every member acts together. Arrives
/// after `syncPlay.joinGroup()` or `createGroup()`.
final class JellyfinSyncPlayCommandEvent extends JellyfinEvent {
  /// The group (`GroupId`).
  final String groupId;

  /// The queue entry the command applies to (`PlaylistItemId`).
  final String? playlistItemId;

  /// `Unpause`, `Pause`, `Stop` or `Seek` (`Command`).
  final String command;

  /// When to act, in server time (`When`).
  final DateTime? when;

  /// Where to be at [when], in ticks (`PositionTicks`).
  final int? positionTicks;

  /// When the server sent the command (`EmittedAt`).
  final DateTime? emittedAt;

  JellyfinSyncPlayCommandEvent._(super.raw, Map<String, Object?> data)
    : groupId = asString(data['GroupId']) ?? '',
      playlistItemId = asString(data['PlaylistItemId']),
      command = asString(data['Command']) ?? '',
      when = asUtcDateTime(data['When']),
      positionTicks = asInt(data['PositionTicks']),
      emittedAt = asUtcDateTime(data['EmittedAt']);

  /// [positionTicks] as a [Duration].
  Duration? get position => asTicksDuration(positionTicks);
}

/// `SyncPlayGroupUpdate`: something changed in this client's SyncPlay
/// group. [updateType] says what, and [data] carries the details, whose
/// shape depends on it; the getters read the common ones.
final class JellyfinSyncPlayGroupUpdateEvent extends JellyfinEvent {
  /// The group (`GroupId`).
  final String groupId;

  /// `GroupUpdateType`: `UserJoined`, `UserLeft`, `GroupJoined`,
  /// `GroupLeft`, `StateUpdate`, `PlayQueue`, `NotInGroup`,
  /// `GroupDoesNotExist` or `LibraryAccessDenied` (`Type`).
  final String updateType;

  /// The update's `Data`, as the server sent it.
  final Object? data;

  JellyfinSyncPlayGroupUpdateEvent._(super.raw, Map<String, Object?> body)
    : groupId = asString(body['GroupId']) ?? '',
      updateType = asString(body['Type']) ?? '',
      data = body['Data'];

  /// For `GroupJoined`, the group this client joined; `null` otherwise.
  JellyfinSyncPlayGroup? get group => switch (data) {
    final Map<String, Object?> m when updateType == 'GroupJoined' =>
      JellyfinSyncPlayGroup.fromJson(m),
    _ => null,
  };

  /// For `UserJoined` and `UserLeft`, the user's name; `null` otherwise.
  String? get userName => updateType == 'UserJoined' || updateType == 'UserLeft'
      ? asString(data)
      : null;

  /// For `StateUpdate`, the group's new state (`Idle`, `Waiting`,
  /// `Paused` or `Playing`); `null` otherwise.
  String? get state => updateType == 'StateUpdate' ? _field('State') : null;

  /// For `StateUpdate` and `PlayQueue`, why the server sent it
  /// (`Reason`); `null` otherwise.
  String? get reason => _field('Reason');

  String? _field(String key) => switch (data) {
    final Map<String, Object?> m => asString(m[key]),
    _ => null,
  };
}

/// `UserUpdated`: a user's name, policy or configuration changed. Sent to
/// that user's sessions and to admins.
final class JellyfinUserUpdatedEvent extends JellyfinEvent {
  /// The user after the change.
  final JellyfinUser user;

  JellyfinUserUpdatedEvent._(super.raw, Map<String, Object?> data)
    : user = JellyfinUser.fromJson(data);
}

/// `UserDeleted`: a user was deleted.
final class JellyfinUserDeletedEvent extends JellyfinEvent {
  /// The deleted user's id.
  final String userId;

  JellyfinUserDeletedEvent._(super.raw, this.userId);
}

/// `RestartRequired`: a change (a plugin, a setting) takes effect only
/// after the server restarts. Sent to admins.
final class JellyfinRestartRequiredEvent extends JellyfinEvent {
  JellyfinRestartRequiredEvent._(super.raw);
}

/// `ServerRestarting`: the server is restarting; the socket closes and the
/// server comes back.
final class JellyfinServerRestartingEvent extends JellyfinEvent {
  JellyfinServerRestartingEvent._(super.raw);
}

/// `ServerShuttingDown`: the server is stopping; the socket closes.
final class JellyfinServerShuttingDownEvent extends JellyfinEvent {
  JellyfinServerShuttingDownEvent._(super.raw);
}

/// `TimerCreated`, `TimerCancelled`, `SeriesTimerCreated` or
/// `SeriesTimerCancelled`: a live TV recording was scheduled or cancelled.
final class JellyfinTimerEvent extends JellyfinEvent {
  /// The frame's `MessageType`.
  final String messageType;

  /// The timer (`Id`): a `liveTv.timers()` id, or a `seriesTimers()` id
  /// when [isSeriesTimer].
  final String timerId;

  /// The program it records (`ProgramId`).
  final String? programId;

  JellyfinTimerEvent._(super.raw, this.messageType, Map<String, Object?> data)
    : timerId = asString(data['Id']) ?? '',
      programId = asString(data['ProgramId']);

  /// A recurring rule rather than a single recording.
  bool get isSeriesTimer => messageType.startsWith('Series');

  /// The timer was cancelled rather than created.
  bool get isCancelled => messageType.endsWith('Cancelled');
}

/// `PackageInstalling`, `PackageInstallationCompleted`,
/// `PackageInstallationFailed` or `PackageInstallationCancelled`: a plugin
/// install moved on. Sent to admins.
final class JellyfinPluginInstallationEvent extends JellyfinEvent {
  /// The frame's `MessageType`.
  final String messageType;

  /// The plugin (`Guid`).
  final String pluginId;

  /// The plugin's name (`Name`).
  final String name;

  /// The version being installed (`Version`).
  final String? version;

  /// Where the package comes from (`SourceUrl`).
  final String? sourceUrl;

  JellyfinPluginInstallationEvent._(
    super.raw,
    this.messageType,
    Map<String, Object?> data,
  ) : pluginId = asString(data['Guid']) ?? '',
      name = asString(data['Name']) ?? '',
      version = asString(data['Version']),
      sourceUrl = asString(data['SourceUrl']);

  /// The install has started.
  bool get isInstalling => messageType == 'PackageInstalling';

  /// The install finished; a restart may be required.
  bool get isCompleted => messageType == 'PackageInstallationCompleted';

  /// The install failed.
  bool get isFailed => messageType == 'PackageInstallationFailed';

  /// The install was cancelled.
  bool get isCancelled => messageType == 'PackageInstallationCancelled';
}

/// `PackageUninstalled`: a plugin was uninstalled. Sent to admins.
final class JellyfinPluginUninstalledEvent extends JellyfinEvent {
  /// The plugin that was removed.
  final JellyfinPluginInfo plugin;

  JellyfinPluginUninstalledEvent._(super.raw, Map<String, Object?> data)
    : plugin = JellyfinPluginInfo.fromJson(data);
}

/// `ActivityLogEntry`: new entries in the activity log, after
/// `JellyfinNotificationsApi.startActivityLog`. Admin only.
final class JellyfinActivityLogEvent extends JellyfinEvent {
  /// The new entries, as `activityLog.entries()` returns them.
  final List<JellyfinActivityLogEntry> entries;

  JellyfinActivityLogEvent._(super.raw, List<Object?> data)
    : entries = asObjectList(data, JellyfinActivityLogEntry.fromJson);
}

/// A frame without a typed event (a `MessageType` the API document does not
/// list), or a known one whose `Data` has an unexpected shape. [raw] is the
/// whole frame.
final class JellyfinUnknownEvent extends JellyfinEvent {
  /// The frame's `MessageType`.
  final String messageType;

  /// `true` when [messageType] has a typed event and this frame's `Data`
  /// could not be read as one; `false` for a type the package does not
  /// know.
  final bool isMalformed;

  /// Wraps a frame of [messageType].
  const JellyfinUnknownEvent(
    this.messageType,
    super.raw, {
    this.isMalformed = false,
  });

  /// The frame's `Data`.
  Object? get data => raw['Data'];
}

/// One frame received from the Jellyfin `/socket` WebSocket.
final class JellyfinNotification {
  /// Upstream `MessageType` (e.g. `'Sessions'`, `'LibraryChanged'`,
  /// `'UserDataChanged'`, `'ScheduledTasksInfo'`, `'KeepAlive'`).
  final String messageType;

  /// Payload of the frame. Most types carry a Map; the sessions
  /// stream carries a list, the keep-alive carries nothing.
  final Object? data;

  /// Raw frame, useful when the message type is not yet promoted to
  /// a typed [JellyfinEvent].
  final Map<String, Object?> raw;

  /// Build a [JellyfinNotification] from its decomposed fields.
  const JellyfinNotification({
    required this.messageType,
    required this.data,
    required this.raw,
  });

  /// Parse a Jellyfin websocket frame (`{MessageType, Data}`).
  factory JellyfinNotification.fromJson(Map<String, Object?> json) =>
      JellyfinNotification(
        messageType: json['MessageType']?.toString() ?? 'Unknown',
        data: json['Data'],
        raw: json,
      );

  /// This frame as a typed [JellyfinEvent]; a [JellyfinUnknownEvent] for a
  /// type without one or a payload of an unexpected shape. Never throws.
  JellyfinEvent get event => JellyfinEvent.fromNotification(this);

  @override
  String toString() => 'JellyfinNotification($messageType)';
}

/// Typed decoding of a [JellyfinNotificationsApi.connect] stream.
///
/// {@category Events and downloads}
extension JellyfinNotificationEvents on Stream<JellyfinNotification> {
  /// Every frame as a [JellyfinEvent]: user-data and library changes,
  /// sessions, remote-control commands, refresh and task progress,
  /// keep-alives; [JellyfinUnknownEvent] for the rest.
  Stream<JellyfinEvent> events() => map((n) => n.event);
}
