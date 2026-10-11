# Migrating to 0.3.0

0.3.0 replaces Dio with `package:http`, names every id, types the values of
the list endpoints, and returns typed models where 0.2 returned maps. Most
apps need the first four sections.

## The transport is package:http

`JellyfinClient` takes any `http.Client`, or none for the default
`dart:io` one. Dio types are gone from the API.

| 0.2.x | 0.3.0 |
| --- | --- |
| `JellyfinClient(credentials: c, dio: myDio)` | `JellyfinClient(credentials: c, httpClient: myClient)` |
| Dio's `Response<T>`, `ResponseType`, `CancelToken` | `JellyfinResponse<T>`, `JellyfinResponseType`, `JellyfinCancelToken` |
| `on DioException`, `JellyfinException.fromDio` | `on JellyfinException` |
| `jf.fetchBytes(url)` | `jf.requestBytes(url)` |
| `e.isRetriable` | `e.isNetworkFailure`, or `e.isTransient` to include 5xx and 429 |

`res.data` keeps its shape: `jf.get<Map<String, Object?>>(path)` returns a
`JellyfinResponse<Map<String, Object?>>`.

Tests that injected a Dio `HttpClientAdapter` inject an `http.Client`
instead (`MockClient` from `package:http/testing.dart`, or a `BaseClient`
subclass) and read `request.url`.

To cancel what a page started, use a view of the client:

```dart
final token = JellyfinCancelToken();
final albums = await jf.withCancelToken(token).items.list(
  parentId: musicLibraryId,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
);
token.cancel(); // every pending call of the view fails with isCancelled
```

## Every id is a named parameter

Ids, names and keys were positional in some methods and named in others.
All are named.

| 0.2.x | 0.3.0 |
| --- | --- |
| `jf.items.byId(id)` | `jf.items.byId(itemId: id)` |
| `jf.playlists.delete(id)`, `byId(id)` | `jf.playlists.delete(playlistId: id)`, `byId(playlistId: id)` |
| `jf.userData.markFavorite(id)` | `jf.userData.markFavorite(itemId: id)` |
| `jf.userData.setFavorite(id, true)` | `jf.userData.setFavorite(itemId: id, isFavorite: true)` |
| `jf.musicGenres.byName('Rock')` | `jf.musicGenres.byName(name: 'Rock')` |
| `jf.lyrics.forItem(id)`, `jf.audio.lyrics(id)` | `jf.lyrics.forItem(itemId: id)`, `jf.audio.lyrics(itemId: id)` |

The analyzer names every call to change. A method whose only argument is
a request body keeps it positional.

## Typed kinds, fields and sort keys

The server answers a value it does not know with a wider result, so these
parameters take types instead of strings.

| 0.2.x | 0.3.0 |
| --- | --- |
| `includeItemTypes: ['MusicAlbum']` | `includeItemTypes: [JellyfinItemKind.musicAlbum]` |
| `fields: ['Genres', 'ChildCount']` | `fields: [JellyfinItemField.genres, JellyfinItemField.childCount]` |
| `sortBy: ['SortName']` | `sortBy: [JellyfinSortField.sortName]` |
| `mediaTypes: ['Audio']` | `mediaTypes: [JellyfinMediaType.audio]` |
| `filters: ['IsFavorite']` | `filters: [JellyfinItemFilter.isFavorite]` |
| `List<String> fields = JellyfinItemsApi.musicFields` | `List<JellyfinItemField> fields = JellyfinItemsApi.musicFields` |

`JellyfinItemKind.audio` and the other constants keep their names. A value
the package does not list is `JellyfinItemKind('Kind')`.

Playlist entry ids are a `JellyfinPlaylistEntryId`. `item.playlistItemId`
already is one; a stored string becomes one with
`JellyfinPlaylistEntryId(id)`.

## Typed answers

| 0.2.x | 0.3.0 |
| --- | --- |
| `(await jf.library.counts())['SongCount']` | `(await jf.library.counts()).songCount` |
| `system.endpointInfo()`, `utcTime()` → maps | `JellyfinEndpointInfo`, `JellyfinUtcTime` |
| `scheduledTasks`, `devices`, `images.listItemImages`, `lyrics.searchRemote`, `syncPlay.list` and `group`, `playlists.users` → maps | typed models |
| `activityLog.entries()` → list | a `JellyfinQueryResult` |
| `scheduledTasks.byId(id)`, `devices.info(id)`, `syncPlay.group(id)` | `null` when there is no such item |
| `item.raw['PlaylistItemId']` | `item.playlistItemId` |
| `item.raw['People']` | `item.people` |
| `item.raw['RecursiveItemCount']`, `raw['AlbumCount']` | `item.recursiveItemCount`, `item.albumCount` |

Each model keeps the server's map in `raw`. Maps and lists the API exposes
are `Object?` instead of `dynamic`: `raw['a']['b']` becomes
`(raw['a'] as Map<String, Object?>)['b']`.

## Final classes

Models, `JellyfinException`, `JellyfinCredentials` and
`JellyfinNotification` are `final`: build a model with its `fromJson`
instead of extending it. `JellyfinClient` and the sub-APIs stay open but
gained members (`close`, `withCancelToken`, `requestStream`, new
methods), so a fake that implements one must add them, or use
`noSuchMethod`.

## Genres, streams and lyrics

| 0.2.x | 0.3.0 |
| --- | --- |
| `musicGenres.list(parentId: music)` | `genres.list(parentId: music)`: the same ids |
| `genres.list(includeItemTypes: […])` without `parentId` | add the music library's `parentId`: unscoped ids give an empty instant mix |
| `playback.progress(playMethod: 'Transcode', repeatMode: 'RepeatAll')` | `playback.progress(method: JellyfinPlayMethod.transcode, repeat: JellyfinRepeatMode.all)` |
| a hand-built `/Audio/{id}/stream?audioCodec=…&maxStreamingBitrate=…` | `jf.audio.transcodedStreamUrl(itemId: id, audioCodec: 'aac', container: 'm4a', audioBitRate: …, playSessionId: …)` |
| a hand-built `/Audio/{id}/main.m3u8?…&container=ts` | `jf.hls.audioVariantUrl(itemId: id, segmentContainer: 'ts', …)` |
| a hand-built `/Items/{id}/Images/Primary?maxWidth=…` | `jf.images.url(itemId: id, maxWidth: 512, maxHeight: 512)` or `images.fetch(…)` |
| `audio.lyricsRaw(id)` | `(await audio.lyrics(itemId: id))?.toLrc(enhanced: true)` |

The old `musicGenres.list()`, the playback strings and `lyricsRaw()` still
work and are deprecated.

## Behavior changes

- A list or object answer of the wrong shape throws a `parse` error
  instead of returning an empty result.
- `playlists.rename()`, `update()` and `delete()` wait until a second has
  passed since this client last changed that playlist's entries.
- `images.url(backgroundColor:)` throws `ArgumentError` for a value that
  is not a hex colour.
- `JellyfinItemsApi.musicFields` no longer lists `AlbumPrimaryImageTag`;
  the server sends it on every track.
- In `request()`, a JSON string asked for as a `String` is decoded, an
  empty answer without a JSON content type is `null`, not `""`, a
  `List<int>` body is sent as bytes, and query values that are not
  strings are form-encoded.
- The wait for the response headers is bounded by `connectTimeout` plus
  `receiveTimeout`. An injected client brings its own connect timeout.
