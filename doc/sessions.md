List the sessions, make this client a cast target, control other sessions, and play together with SyncPlay.

## Sessions and remote control

`sessions` lists the clients connected to the server, registers this
client as a cast target and sends commands to other sessions. Commands
sent to this client arrive as notifications. See the [Events, downloads and raw requests](https://pub.dev/documentation/dart_jellyfin/latest/topics/Events,%20downloads%20and%20raw%20requests-topic.html) topic.

### Listing sessions

```dart
final sessions = await jellyfin.sessions.list();
for (final s in sessions) {
  print('${s.userName} on ${s.deviceName} (${s.client}): ${s.nowPlayingItem?.name}');
}

// Sessions the current user may control, active in the last 30 seconds.
final controllable = await jellyfin.sessions.list(
  controllableByUserId: jellyfin.userId,
  activeWithinSeconds: 30,
);
```

### Registering this client as a cast target

Once this client posts its capabilities, other Jellyfin clients list it
as a cast target:

```dart
await jellyfin.sessions.postCapabilities(
  playableMediaTypes: const ['Audio', 'Video'],
  supportedCommands: const [
    'Play', 'PlayState', // accept play and playstate commands
    JellyfinGeneralCommand.setVolume,
    JellyfinGeneralCommand.mute,
    JellyfinGeneralCommand.unmute,
    JellyfinGeneralCommand.toggleMute,
    JellyfinGeneralCommand.setAudioStreamIndex,
    JellyfinGeneralCommand.setSubtitleStreamIndex,
  ],
  supportsMediaControl: true,
);
```

`supportedCommands` takes `GeneralCommandType` values. Pause, stop, seek
and track skips are not among them: they arrive as
playstate commands (see below), which the `PlayState`
capability turns on. `postFullCapabilities()` posts the whole body as a
map.

When the user signs out, call `sessions.reportSessionEnded()` so the
server drops the session.

### Playing on a remote session

```dart
final target = sessions.firstWhere((s) => s.supportsMediaControl);
await jellyfin.sessions.play(
  sessionId: target.id,
  itemIds: const ['12345', '12346'],
  playCommand: JellyfinPlayCommand.playShuffle,
);
```

`playCommand` defaults to `JellyfinPlayCommand.playNow`, which replaces
the queue. The others are `playNext`, `playLast`, `playInstantMix` and
`playShuffle`.

### Playstate commands

```dart
await jellyfin.sessions.sendPlaystateCommand(
  sessionId: target.id,
  command: JellyfinPlaystateCommand.pause,
);
await jellyfin.sessions.sendPlaystateCommand(
  sessionId: target.id,
  command: JellyfinPlaystateCommand.seek,
  seekPositionTicks: 1200000000, // 2 minutes
);
```

`JellyfinPlaystateCommand` has `stop`, `pause`, `unpause`, `playPause`,
`nextTrack`, `previousTrack`, `seek`, `rewind` and `fastForward`.

### General and system commands

```dart
// A command without arguments.
await jellyfin.sessions.sendCommand(
  sessionId: target.id,
  command: JellyfinGeneralCommand.volumeUp,
);

// A command with arguments.
await jellyfin.sessions.sendFullCommand(
  sessionId: target.id,
  name: JellyfinGeneralCommand.setVolume,
  arguments: {'Volume': '80'},
);

// Navigation: GoHome, GoToSettings, GoToSearch.
await jellyfin.sessions.sendSystemCommand(
  sessionId: target.id,
  command: 'GoHome',
);
```

### Messages and content

```dart
// A message on the remote device.
await jellyfin.sessions.sendMessage(
  sessionId: target.id,
  text: 'Now playing on the kitchen TV.',
  header: 'Cast',
  timeoutMs: 4000,
);

// Open an item's page on the remote device, without playing it.
await jellyfin.sessions.displayContent(
  sessionId: target.id,
  itemId: album.id,
  itemType: 'MusicAlbum',
  itemName: album.name,
);
```

`reportViewing(itemId:)` tells the server what this client shows, and
`addUser()` and `removeUser()` add a second user to a session.

## SyncPlay

SyncPlay plays the same queue on several clients at once. One client
creates a group, the others join, and pause, seek and track changes
reach every member. Each member calls `ready()` once it has buffered, so
the server resumes the group together.

### Listing and joining groups

```dart
final groups = await jellyfin.syncPlay.list();
for (final g in groups) {
  print('${g.name} (${g.participants.length} participants, ${g.state})');
}

await jellyfin.syncPlay.createGroup(groupName: 'Friday movie night');
await jellyfin.syncPlay.joinGroup(groupId: groups.first.id);
await jellyfin.syncPlay.leaveGroup();
```

`list()` returns `JellyfinSyncPlayGroup`s (`id`, `name`, `state`,
`participants`, `lastUpdatedAt`). `group(id:)` fetches one, or `null`.

### Group playback control

```dart
await jellyfin.syncPlay.pause();
await jellyfin.syncPlay.unpause();
await jellyfin.syncPlay.seek(positionTicks: 1200000000); // 2 minutes
await jellyfin.syncPlay.stop();

await jellyfin.syncPlay.nextItem(playlistItemId: entryId);
await jellyfin.syncPlay.previousItem(playlistItemId: entryId);
await jellyfin.syncPlay.setPlaylistItem(playlistItemId: entryId);

await jellyfin.syncPlay.setRepeatMode(mode: 'RepeatAll');
await jellyfin.syncPlay.setShuffleMode(mode: 'Shuffle');
```

### Group queue

```dart
// Replace the queue.
await jellyfin.syncPlay.setNewQueue(
  playingQueue: const ['12345', '12346', '12347'],
  playingItemPosition: 0,
);

// Append ('Queue', the default) or insert after the current item.
await jellyfin.syncPlay.queue(itemIds: const ['12348'], mode: 'QueueNext');

// Reorder and remove.
await jellyfin.syncPlay.movePlaylistItem(playlistItemId: entryId, newIndex: 0);
await jellyfin.syncPlay.removeFromPlaylist(playlistItemIds: const ['entry-1']);

// While buffering, and once ready.
await jellyfin.syncPlay.buffering(playlistItemId: entryId, positionTicks: 0, isPlaying: false);
await jellyfin.syncPlay.ready(playlistItemId: entryId, positionTicks: 0, isPlaying: false);
```
