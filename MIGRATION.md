# Migrating to dart_jellyfin 0.3

## What breaks, and what to write instead

| 0.2.x | 0.3 |
|---|---|
| `JellyfinClient(credentials: c, dio: myDio)` | `JellyfinClient(credentials: c, httpClient: myHttpClient)` — any `package:http` `Client`; omit it for the default |
| `import 'package:dio/dio.dart'` for `Response`, `CancelToken`, `ResponseType` | `JellyfinResponse<T>`, `JellyfinCancelToken`, `JellyfinResponseType` (exported by `dart_jellyfin`) |
| `final res = await jf.get<Map<String, dynamic>>(path); res.data` | unchanged shape: `res.data` is there; the type is `JellyfinResponse<Map<String, Object?>>` |
| `jf.request(path, cancelToken: CancelToken())` | `jf.request(path, cancelToken: JellyfinCancelToken())` — or `jf.withCancelToken(token).items…` for every call |
| `on DioException` / `JellyfinException.fromDio` | `on JellyfinException` only; `e.isNetworkFailure`, `e.isTransient`, `e.isNotFound`, `e.isCancelled` |
| `jf.fetchBytes(url)` | `jf.requestBytes(url)` |
| `(await jf.library.counts())['SongCount']` | `(await jf.library.counts()).songCount` |
| `scheduledTasks`, `devices`, `activityLog.entries`, `images.listItemImages`, `lyrics.searchRemote`, `syncPlay.list/group`, `playlists.users` → maps | typed models (`.raw` keeps the map); `activityLog.entries()` is a `JellyfinQueryResult` |
| `playback.progress(playMethod: 'Transcode', repeatMode: 'RepeatAll')` | `playback.progress(method: JellyfinPlayMethod.transcode, repeat: JellyfinRepeatMode.all)` (Strings still work, deprecated) |
| `item.raw['PlaylistItemId']` | `item.playlistItemId` |
| hand-built `/Items/{id}/Images/Primary?maxWidth=…&format=Jpg` | `jf.images.url(itemId: id, tag: item.artworkVersion, maxWidth: 512, maxHeight: 512, quality: 85, format: JellyfinImagesApi.formatJpg)` |
| hand-built `/Audio/{id}/main.m3u8?…&deviceId=…&container=ts` | `jf.hls.audioVariantUrl(itemId: id, playSessionId: ps, segmentContainer: 'ts', …)` — `container` is not read by that route, and the device id must be the auth header's |
| `raw['a']['b']` (dynamic access) | `(raw['a'] as Map<String, Object?>)['b']` |
| `class Fake extends JellyfinItem` | models are `final`; build them with `JellyfinItem.fromJson` |

Tests that injected a Dio `HttpClientAdapter` to inspect the outgoing URI now
inject an `http.Client` (`MockClient` from `package:http/testing.dart`, or a
`BaseClient` subclass) through `httpClient:` and read `request.url`.

## New API to adopt

```dart
// Cancel what a page started when the page goes away.
final token = JellyfinCancelToken();
final albums = await jf.withCancelToken(token).items.list(
  parentId: musicLibraryId,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  fields: JellyfinItemsApi.browseFields, // grids; musicFields where media sources are read
  enableTotalRecordCount: false,
  limit: 50,
);
token.cancel();

// One library's artists: parentId on /Items does not scope MusicArtist.
final artists = await jf.artists.albumArtists(parentId: musicLibraryId);

// Genres: /Genres ids are the /MusicGenres ids, and filter music.
final genres = await jf.genres.list(
  parentId: musicLibraryId,
  includeItemTypes: const [JellyfinItemKind.musicAlbum, JellyfinItemKind.audio],
);
final mix = await jf.instantMix.fromItem(itemId: genres.items.first.id, limit: 50);

// Word-by-word lyrics, without converting by hand.
final lrc = (await jf.lyrics.forItem(itemId: trackId))?.toLrc(enhanced: true);

// Cover and its cache version.
final cover = track.artworkItemId;
final version = track.artworkVersion;

// Loudness normalisation.
final gainDb = track.normalizationGain ?? track.albumNormalizationGain;
```

See `CHANGELOG.md` for everything verified on Jellyfin 12.0 / 12.2 along
the way.
