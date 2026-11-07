# Migrating to 0.4.0

0.4.0 targets Jellyfin 12.4 and needs a server from 12.0 on and Dart
3.10. It removes every member deprecated in 0.3, moves `artists` to the
people routes, and returns typed models where 0.3 returned maps. The
analyzer names every call to change.

## Dart and the server

| 0.3.x | 0.4.0 |
| --- | --- |
| Dart `^3.5.0` | Dart `^3.10.0` |
| Jellyfin 12.2 targeted | Jellyfin 12.4 targeted, 12.0 or later required |

Use a server from 12.0 on: 12.0 fixed security advisories, disables the
legacy authorization by default, and removed the `/emby` and
`/mediabrowser` prefixes. The package sends only the `MediaBrowser`
header and never used the prefixes.

## Removed members

| 0.3.x | 0.4.0 |
| --- | --- |
| `jf.musicGenres.list(parentId: music)` | `jf.genres.list(parentId: music)`: the same ids |
| `jf.musicGenres.byName(name: n)` | `jf.genres.musicGenre(name: n, parentId: music)` |
| `jf.trailers.list(…)` | `jf.items.list(includeItemTypes: [JellyfinItemKind.trailer], …)` |
| `jf.tmdb.clientConfiguration()` | gone, with no replacement; `jf.request('/Tmdb/ClientConfiguration')` while 12.x serves it |
| `instantMix.fromMusicGenre(name: n)`, `fromMusicGenreById(genreId: id)` | `instantMix.fromItem(itemId: id)` with the `MusicGenre` id |
| `instantMix.fromArtistByName(name: n)` | `instantMix.fromArtist(artistId: id)` with the `MusicArtist` id |
| `startup.configuration()`, `updateInitialConfiguration()`, `setRemoteAccess()` | `configuration.get()`, `update()`, `updateNamed(key: 'network', body: …)`; during the wizard, `jf.request('/Startup/Configuration', method: 'POST', data: …)` |
| `startup.firstUserAlt()` | `startup.firstUser()` |
| `liveTv.recordingGroups()`, `recordingsSeries()` | `liveTv.recordingFolders()`, `recordings()` |
| `hls.stopEncoding()` | `playback.stopped()` |
| `audio.lyricsRaw(itemId: id)` | `(await audio.lyrics(itemId: id))?.toLrc(enhanced: true)` |
| `e.isRetriable`, `type.isRetriable` | `e.isNetworkFailure`, or `e.isTransient` to include 5xx and 429 |
| `user.hasPassword`, `hasConfiguredPassword`, `hasConfiguredEasyPassword` | gone: Jellyfin 12 made them meaningless; `user.raw['HasPassword']` |

## Removed parameters

Each was ignored by the server, so removing it changes no request.

| 0.3.x | 0.4.0 |
| --- | --- |
| `liveTv.channels(searchTerm: q)` | filter the answer by name |
| `tvShows.nextUp(disableFirstEpisode: …)` | drop it |
| `videos.streamUrl(maxStreamingBitrate: b)`, `hls.videoMasterUrl()`, `videoVariantUrl()`, `videoLiveUrl()` with it | `videoBitRate:` and `audioBitRate:` |
| `subtitles.streamWithTicksUrl(segmentLength: n)` | `endPositionTicks:` |
| `playback.start(playMethod: 'Transcode')` | `playback.start(method: JellyfinPlayMethod.transcode)` |
| `playback.progress(playbackOrder: 'Shuffle', repeatMode: 'RepeatAll')` | `playback.progress(order: JellyfinPlaybackOrder.shuffle, repeat: JellyfinRepeatMode.all)` |

## Artists are people

Jellyfin 12 stores music artists as people and marks `/Artists`,
`/Artists/AlbumArtists` and `/Artists/{name}` obsolete, naming
`/Persons` as their successor. `artists` now asks `/Persons`, as Jellyfin
Web 12 does.

| 0.3.x | 0.4.0 |
| --- | --- |
| `artists.list()` → `/Artists` | `/Persons?personTypes=Artist` |
| `artists.albumArtists()` → `/Artists/AlbumArtists` | `/Persons?personTypes=AlbumArtist` |
| `artists.byName(name: n)` → `/Artists/{name}` | `/Persons/{name}` |
| `sortBy:`, `descending:`, `genres:`, `genreIds:`, `tags:`, `officialRatings:`, `years:`, `mediaTypes:`, `minCommunityRating:`, `includeItemTypes:`, `excludeItemTypes:` | gone: `/Persons` has none of them |
| | `nameStartsWith:`, `nameStartsWithOrGreater:`, `nameLessThan:`, `enableImages:` |

The answers are `Person` items, with ids of their own. A person id filters
`items.list(artistIds:)` and `albumArtistIds:` like an artist id, and
scoped by `parentId` the lists match what `/Artists` answered. But a
person id seeds an empty instant mix and carries no MusicBrainz id. For
an instant mix, a sorted list or provider ids, use the `MusicArtist`
item:

```dart
// From a track.
final artistId = track.artistItems.first.id;

// Or by listing them.
final musicArtists = await jf.items.list(
  includeItemTypes: const [JellyfinItemKind.musicArtist],
  sortBy: const [JellyfinSortField.sortName],
);
final mix = await jf.instantMix.fromArtist(artistId: musicArtists.items.first.id);
```

An artist id stored by 0.3 is a `MusicArtist` id and keeps working with
`items.list()` and `instantMix`.

## Typed answers

These return typed models instead of maps. Each keeps the server's map in
`raw`, so `x['Name']` becomes `x.name`, or `x.raw['Name']` for a field
the model does not lift.

| Method | 0.4.0 |
| --- | --- |
| `apiKey.list()` | `List<JellyfinApiKey>` |
| `backup.list()`, `create()`, `manifest()` | `List<JellyfinBackupManifest>`, `JellyfinBackupManifest` |
| `branding.configuration()` | `JellyfinBrandingOptions` |
| `channels.features()`, `allFeatures()` | `JellyfinChannelFeatures`, a list of them |
| `collection.create()` | `JellyfinCollectionCreationResult`: `created['Id']` becomes `created.id` |
| `configuration.get()`, `defaultMetadataOptions()` | `JellyfinServerConfiguration`, `JellyfinMetadataOptions` |
| `dashboard.configurationPages()` | `List<JellyfinConfigurationPage>` |
| `devices.options()` | `JellyfinDeviceOptions` |
| `environment.directoryContents()`, `drives()`, `defaultDirectoryBrowser()` | `List<JellyfinFileSystemEntry>`, `JellyfinDefaultDirectoryBrowser` |
| `itemLookup.externalIdInfos()` | `List<JellyfinExternalIdInfo>` |
| `itemLookup.searchMovies()` and the other eight `search…()` | `List<JellyfinRemoteSearchResult>`; pass `result.raw` to `applySearchResult()` |
| `items.metadataEditorInfo()` | `JellyfinMetadataEditorInfo` |
| `library.themeMedia()`, `availableOptions()` | `JellyfinThemeMedia`, `JellyfinLibraryAvailableOptions` |
| `libraryStructure.list()` | `List<JellyfinVirtualFolder>` |
| `liveTv.timers()`, `seriesTimers()` | `JellyfinQueryResult<JellyfinTimer>`, `JellyfinQueryResult<JellyfinSeriesTimer>` |
| `liveTv.info()`, `guideInfo()` | `JellyfinLiveTvInfo`, `JellyfinGuideInfo` |
| `liveTv.channelMappingOptions()`, `setChannelMapping()` | `JellyfinChannelMappingOptions`, `JellyfinTunerChannelMapping` |
| `liveTv.addTunerHost()`, `discoverTuners()`, `discoverTunersAlt()` | `JellyfinTunerHost`, a list of them |
| `liveTv.tunerHostTypes()`, `lineups()` | `List<JellyfinNameIdPair>` |
| `liveTv.addListingProvider()`, `defaultListingProvider()` | `JellyfinListingsProvider` |
| `liveTv.defaultTimer()` | `JellyfinSeriesTimer` |
| `localization.countries()`, `cultures()`, `parentalRatings()` | `List<JellyfinCountry>`, `List<JellyfinCulture>`, `List<JellyfinParentalRating>` |
| `localization.options()` | `List<JellyfinNameValuePair>` |
| `packages.list()`, `byName()`, `repositories()` | `List<JellyfinPackageInfo>`, `JellyfinPackageInfo`, `List<JellyfinRepository>` |
| `playlists.userAccess()` | `JellyfinPlaylistUserPermission?` |
| `plugins.list()`, `manifest()` | `List<JellyfinPluginInfo>`, `JellyfinPluginManifest` |
| `remoteImage.list()`, `providers()` | `JellyfinRemoteImageResult`, `List<JellyfinImageProviderInfo>` |
| `startup.firstUser()` | `JellyfinStartupUser` |
| `subtitles.searchRemote()`, `fallbackFonts()` | `List<JellyfinRemoteSubtitle>`, `List<JellyfinServerFile>` |
| `subtitles.getRemote()` | `String?`: the subtitle text, not JSON |
| `system.storage()`, `logs()` | `JellyfinSystemStorage`, `List<JellyfinServerFile>` |
| `user.forgotPassword()`, `forgotPasswordPin()` | `JellyfinForgotPasswordResult`, `JellyfinPinRedeemResult` |
| `user.authProviders()`, `passwordResetProviders()` | `List<JellyfinNameIdPair>` |
| `userViews.groupingOptions()` | `List<JellyfinNameIdPair>` |
| `videos.additionalParts()` | `JellyfinQueryResult<JellyfinItem>`: iterate `.items` |

`configuration.getNamed()`, `plugins.configuration()` and
`liveTv.schedulesDirectCountries()` still return maps: each answers a
document whose shape depends on the key, the plugin or the provider.

A single-object answer of the wrong shape now throws a `parse` error, as
the lists already did.

## Events and other changes

- Frames that 0.3 surfaced as `JellyfinUnknownEvent` have their own
  types: `SyncPlayCommand`, `SyncPlayGroupUpdate`, `UserUpdated`,
  `UserDeleted`, `RestartRequired`, `ServerRestarting`,
  `ServerShuttingDown`, the four timer frames, the five plugin frames and
  `ActivityLogEntry`. A `switch` that matched them as
  `JellyfinUnknownEvent(messageType: 'UserUpdated')` matches
  `JellyfinUserUpdatedEvent()` instead.
- `item.raw['Trickplay']` is `item.trickplay`, typed by media source id
  and width.

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
