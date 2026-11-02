Follow the server's pushed events, download a file to disk, and call routes the sub-APIs do not cover.

## Notifications and typed events

<img src="https://raw.githubusercontent.com/ales-drnz/dart_jellyfin/main/imgs/diagrams/events.png" width="100%" alt="Socket frames become a JellyfinNotification, and events() decodes them into the sealed JellyfinEvent subtypes">

The server pushes changes over a WebSocket: user data, library changes,
sessions, scheduled tasks and remote-control commands for this client.

### Connecting

```dart
final socket = await jellyfin.notifications.connect();

final subscription = socket.events().listen((event) {
  switch (event) {
    case JellyfinUserDataChangedEvent(:final changes):
      for (final c in changes) {
        print('${c.itemId} favorite=${c.isFavorite} played=${c.played}');
      }
    case JellyfinLibraryChangedEvent(:final itemsUpdated, :final itemsRemoved):
      print('re-read $itemsUpdated, drop $itemsRemoved');
    case JellyfinPlaystateEvent(:final command, :final seekPosition):
      print('remote asks: $command $seekPosition');
    case _:
  }
});

// Later:
await subscription.cancel();
await jellyfin.notifications.close();
```

`connect()` needs the server and the session, and returns a broadcast
stream of `JellyfinNotification` frames (`messageType`, `data`, `raw`).
`events()` on the stream, or `event` on one frame, decodes them into the
sealed `JellyfinEvent` type. The client sends a keep-alive every
`keepAliveInterval` (30 seconds by default). Call `close()` before
connecting again.

### Typed events

| Event | `MessageType` | Holds |
| :--- | :--- | :--- |
| `JellyfinUserDataChangedEvent` | `UserDataChanged` | The user id and a `JellyfinUserDataChange` for each item (favorite, played, play count, position, last played); a track's change also carries its album |
| `JellyfinLibraryChangedEvent` | `LibraryChanged` | Items added, updated and removed, folders added to and removed from, sent in batches some seconds after the change |
| `JellyfinSessionsEvent` | `Sessions` | The `JellyfinSession` list, after `startSessions()` |
| `JellyfinPlayEvent`, `JellyfinPlaystateEvent`, `JellyfinGeneralCommandEvent` | `Play`, `Playstate`, `GeneralCommand` | Remote-control commands sent to this session |
| `JellyfinRefreshProgressEvent` | `RefreshProgress` | A library refresh's item id and progress |
| `JellyfinScheduledTasksInfoEvent`, `JellyfinScheduledTaskEndedEvent` | `ScheduledTasksInfo`, `ScheduledTaskEnded` | The `JellyfinScheduledTask` list after `startScheduledTasks()`, and a finished run |
| `JellyfinKeepAliveEvent` | `KeepAlive`, `ForceKeepAlive` | Keep-alive; `ForceKeepAlive` carries the server's timeout |
| `JellyfinUnknownEvent` | Anything else | `messageType` and the whole frame in `raw` |

Decoding never throws: a frame whose `Data` has an unexpected shape
becomes a `JellyfinUnknownEvent` too. Remote-control commands reach the
socket of the session that owns the token, the device that signed in.

### Subscriptions

Sessions and scheduled tasks are sent only on request:

```dart
jellyfin.notifications.startSessions(); // every 2 seconds by default
jellyfin.notifications.startScheduledTasks(interval: const Duration(seconds: 5)); // admin

socket.events().listen((event) {
  if (event case JellyfinSessionsEvent(:final sessions)) {
    print('${sessions.where((s) => s.isPlaying).length} playing');
  }
});

jellyfin.notifications.stopSessions();
jellyfin.notifications.stopScheduledTasks();
```

`send(messageType:, data:)` sends any other message the server accepts.

## Downloads

### Downloading to a file

`downloadToFile()` is an extension in `package:dart_jellyfin/io.dart`,
kept out of the main library so that one stays usable on the web:

```dart
import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dart_jellyfin/io.dart';

Future<void> saveTrack(JellyfinClient jellyfin, JellyfinItem track) async {
  final token = JellyfinCancelToken();
  final (url, _) = jellyfin.audio.directStreamUrl(itemId: track.id);
  final written = await jellyfin.downloadToFile(
    url,
    '/music/${track.id}', // the original file, as stored on the server
    cancelToken: token,   // token.cancel() stops it and removes the file
    onProgress: (received, total) => print('$received / ${total ?? '?'}'),
  );
  print('$written bytes');
}
```

The body goes to `<path>.part` as it arrives, at the pace the disk
takes, and is renamed to the target only once complete. The target holds
either the whole file or what was there before: a failure, a stall past
`receiveTimeout` or a cancellation removes the partial file and throws a
`JellyfinException`. `onProgress` gets the total when the server sent a
`Content-Length`. For a smaller copy, download a
transcoded file URL. See the [Audio streaming and HLS](https://pub.dev/documentation/dart_jellyfin/latest/topics/Audio%20streaming%20and%20HLS-topic.html) topic.

## Escape hatch

For a route the sub-APIs do not cover, call it directly. These calls use
the same HTTP client, headers, retry policy and `JellyfinException`
translation as the sub-APIs.

### Raw request

```dart
final response = await jellyfin.request<Map<String, Object?>>(
  '/Items',
  queryParameters: {
    'userId': jellyfin.userId,
    'includeItemTypes': 'Audio',
    'recursive': true,
    'limit': 0,
  },
);
final total = response.data?['TotalRecordCount'];
```

`request()` returns a `JellyfinResponse<T>` with `data`, `statusCode`,
`headers` and `uri`. It takes `method` (`'POST'`, `'DELETE'`),
`extraHeaders`, `data`, `absoluteUrl` and `cancelToken`; a `List` in
`queryParameters` repeats the key once for each value. `responseType`
picks the decoding: `JellyfinResponseType.json` (the default: JSON when
the server says so, text otherwise), `plain` (UTF-8 text) or `bytes` (a
`Uint8List`). `get()`, `post()` and `delete()` are shorthands.

```dart
final m3u8 = await jellyfin.request<String>(
  '/Audio/${track.id}/main.m3u8',
  responseType: JellyfinResponseType.plain,
);
print(m3u8.data);
```

### Raw bytes

```dart
final response = await jellyfin.requestBytes(
  '/Items/${item.id}/Download',
  absoluteUrl: false,
);
final bytes = response.data;
```

`requestBytes()` holds the whole body in memory, which suits artwork and
small files. Its `url` is absolute by default, for a URL a builder made;
with `absoluteUrl: false` it is a path on the server. For media, stream
the body (see Streamed body below) or write it to disk (see Downloading
to a file above).

### Streamed body

```dart
final (url, _) = jellyfin.audio.directStreamUrl(itemId: track.id);
final res = await jellyfin.requestStream(url);
print('${res.contentLength} bytes, ${res.contentType}');
await for (final chunk in res.stream) {
  sink.add(chunk);
}
```

`requestStream()` returns a `JellyfinStreamedResponse` as soon as the
headers arrive. Listen to `stream` once; cancelling the subscription
closes the connection. A pause in the body longer than `receiveTimeout`
fails the stream, unless you pass `stallTimeout: false`.
