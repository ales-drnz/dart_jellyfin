## [0.3.0] - 11-10-2026

Targets Jellyfin `12.2` (the integration stack now runs `jellyfin/jellyfin:12.2`); behaviours noted as verified were checked against 12.0 and 12.2 servers.

### Breaking
- **The transport is `package:http`, not Dio.** `JellyfinClient(dio:)` is gone: pass any `http.Client` as `httpClient:` (a `CupertinoClient` or `CronetClient` for HTTP/2 and the system proxy, a `MockClient` in tests), or none for the default `dart:io` one. `request()` / `get()` / `post()` / `delete()` return a `JellyfinResponse<T>` (`.data`, `.statusCode`, `.headers`, `.contentType`) instead of Dio's `Response<T>`, take a `JellyfinResponseType` instead of Dio's `ResponseType`, and a `JellyfinCancelToken` instead of Dio's `CancelToken`. `requestBytes()` answers a `JellyfinResponse<Uint8List>`. `JellyfinException.fromDio` and the deprecated `fetchBytes()` are gone. The query string, body and headers on the wire are unchanged.
- **Typed answers instead of maps**: `system.endpointInfo()` / `utcTime()`, `scheduledTasks.list()` / `byId()`, `library.counts()` (`JellyfinItemCounts`), `devices.list()` / `info()`, `activityLog.entries()` (a paged `JellyfinQueryResult`), `images.listItemImages()`, `lyrics.searchRemote()`, `syncPlay.list()` / `group()` and `playlists.users()`. Each model keeps the body in `raw`.
- **`Object?` instead of `dynamic`** in every map and list the API exposes. Reading and assigning work as before; a chained dynamic access such as `raw['a']['b']` now needs a type check.
- **Models are `final`**: they can no longer be extended or implemented outside the package. `JellyfinClient` and the sub-API classes stay open, so test fakes still work.
- `JellyfinItemsApi.musicFields` no longer lists `AlbumPrimaryImageTag`: it is not an `ItemFields` member, and the server sends it on every track regardless (verified), so nothing on the wire changes in effect.

### Added
- `JellyfinClient.withCancelToken(token)`: a view of the client whose every sub-API call is cancelled by `token.cancel()`.
- `JellyfinRetryPolicy` (`retryPolicy:`): opt-in resend of `GET` / `HEAD` after a network failure, `502`, `503`, `504` or `429`, with backoff, jitter and `Retry-After`.
- `JellyfinException.isNetworkFailure`, `isTransient`, `isNotFound`, `isCancelled`, `retryAfter`, with the same meaning as in `dart_plex`.
- `requestStream()`, and `downloadToFile()` in the new `package:dart_jellyfin/io.dart` (streams to disk, whole file or none, with progress).
- Lyrics: `JellyfinLyricLine.cues` (`JellyfinLyricCue`, word-level ELRC timing), `JellyfinLyrics.metadata`, `hasCues`, and `toLrc(enhanced: true)` writing the enhanced-LRC form (verified with an enhanced `.lrc` uploaded to the server).
- `JellyfinItem.normalizationGain` / `albumNormalizationGain` (Jellyfin exposes no LUFS value, only the gain), `primaryImageTag`, `artworkItemId`, `artworkVersion`, `genreItems` (ids for `genreIds:`), `albumArtistItems`, `playlistItemId`.
- `JellyfinItemsApi.browseFields`: the light `fields` set for grids (~1.2 KB a track against ~3.2 KB with `musicFields`, measured).
- `images.url()` takes `maxWidth`, `maxHeight`, `blur` and `backgroundColor`; `fetch()` takes the same sizing parameters (`maxWidth`, `maxHeight`, `width`, `height`, `fill*`, `quality`, `format`) and a cancel token. Measured: `max*` fit inside the box, `fill*` cover it, `width`/`height` stretch, and `format=Jpg` is honoured together with `maxWidth`.
- `hls.audioVariantUrl()` / `audioMasterUrl()` take `segmentContainer`, `segmentLength`, `minSegments`, `enableAutoStreamCopy`, `allowAudioStreamCopy`, `audioSampleRate`, `maxAudioBitDepth` and `context`, under the names the route reads.
- `playback.start()` / `progress()` take `method:` (`JellyfinPlayMethod`), `order:` (`JellyfinPlaybackOrder`) and `repeat:` (`JellyfinRepeatMode`).
- `subtitles.streamWithTicksUrl(endPositionTicks:)`.
- `JellyfinPaging.pages()` / `items()`.

### Changed
- JSON decoding, model parsing and gzip inflation run on a background isolate above `jsonIsolateThreshold` (50 KB by default, now a constructor argument). Measured on six parallel 1.5 MB pages, the stall of the calling isolate went from 38–64 ms to 14–23 ms.
- Stricter lints; every documentation reference resolves.

### Fixed
- Parameters the routes do not read, found by the new spec contract test and no longer sent: `liveTv.channels(searchTerm:)`, the video builders' `maxStreamingBitrate` (use `videoBitRate` / `audioBitRate`), `subtitles.streamWithTicksUrl(segmentLength:)`, and `DeviceId` on the legacy HLS segment URLs. `tvShows.nextUp(disableFirstEpisode:)` was removed in 12.x and is now sent only when passed.

### Deprecated
- `playback.start/progress(playMethod:, playbackOrder:, repeatMode:)` (`String`) → `method:`, `order:`, `repeat:`.
- `liveTv.channels(searchTerm:)`, `tvShows.nextUp(disableFirstEpisode:)`, `videos.streamUrl(maxStreamingBitrate:)` and the video HLS builders' `maxStreamingBitrate`, `subtitles.streamWithTicksUrl(segmentLength:)`.

### Notes (verified)
- `/Genres` with `includeItemTypes: [MusicAlbum, Audio]` answers the same ids as `/MusicGenres`, and those ids filter albums and tracks; `instantMix.fromItem(itemId: genreId)` answers that genre's tracks.
- `items.list(parentId:)` scopes albums and tracks to one library but **not** `MusicArtist` items; `artists.albumArtists(parentId:)` does (two music libraries, 12.0).
- A playlist entry id is the item id on 12.2: removing it removes every copy of a duplicated track, moving it moves the first.
- A playlist rename sent within ~0.5 s of an entry change is lost (10/10), and a read right after a move can show the old order.
- `audio.universalStreamUrl()` keeps `PlaySessionId`: `/universal` does not declare it, but copies it into the HLS variant URL, which reads it.
- An HLS transcode is filed under the URL's `DeviceId` (the auth header's in every builder here); a paused session that reported `isPaused` kept its job for the 130 s observed without `ping()`.

### Tests
- A spec contract test calls every public method and checks each request's route, method and query parameters against the pinned 12.2 document (plus the 10.11.6 routes 12.x hides).
- Wire tests for the new surface, real anonymised fixtures, integration tests against 12.2, and read-only live tests against any server (`JELLYFIN_URL` / `JELLYFIN_TOKEN`, tag `live`).

## [0.2.1] - 22-09-2026

### Changed
- The default transport decodes JSON responses of 50 KB or more on a background isolate (`JellyfinConnection.jsonIsolateThreshold`), so large responses no longer block the caller's isolate. A `Dio` you inject keeps its own transformer.

## [0.2.0] - 09-09-2026

Targets Jellyfin `12.0` (released 8 September 2026).

### Fixed
- Every signed URL (`audio.universalStreamUrl()`, `audio.streamUrl()`, the HLS, subtitle, trickplay, video attachment, plugin image, live TV and `items.downloadUrl()` / `fileUrl()` builders) and the notifications WebSocket now carry the token as `ApiKey=…` instead of `api_key=…`. Jellyfin 12 only reads `api_key` when legacy authorization is enabled, which it no longer is by default, so on 12.0 the old URLs answered 401 and the socket handshake 403. Verified against a 12.0.0 server. If you build a stream URL by hand, switch the parameter name too.

### Breaking
- `library.criticReviews()` is gone. Jellyfin 12 removed `GET /Items/{itemId}/CriticReviews`; the call answered 404 on 12.0.
- `environment.networkShares()` is gone. Jellyfin 12 removed `GET /Environment/NetworkShares`.
- `liveTv.recordingGroup()` is gone. Jellyfin 12 removed `GET /LiveTv/Recordings/Groups/{groupId}`.
- `playback.legacyStart()`, `legacyProgress()` and `legacyStopped()` are gone. They hit the `/PlayingItems/*` routes, which are hidden from the Jellyfin 12 API and may vanish without notice; `playback.start()`, `progress()` and `stopped()` send the same reports through `/Sessions/Playing`.
- `JellyfinUser` no longer requires `hasPassword`, `hasConfiguredPassword` and `hasConfiguredEasyPassword` in its constructor. They default to `false` and are deprecated (below). Only code that builds a `JellyfinUser` by hand is affected.

### Deprecated
Everything below still works on 12.0. Jellyfin marks these routes obsolete or hides them from the API document, and its stated policy is that hidden routes may be removed in any major release without warning, so each one is `@Deprecated` with its replacement.
- `trailers.list()` → `items.list(includeItemTypes: ['Trailer'])`.
- `musicGenres.list()` → `genres.list(includeItemTypes: ['MusicAlbum', 'Audio'])`; `musicGenres.byName()` → `genres.byName()`.
- `instantMix.fromMusicGenre()` and `fromMusicGenreById()` → `instantMix.fromItem(itemId: genreId)`; `instantMix.fromArtistByName()` → `fromArtist()` or `fromItem()` with the artist id.
- `startup.configuration()`, `updateInitialConfiguration()`, `setRemoteAccess()` → the `configuration` API; `startup.firstUserAlt()` → `startup.firstUser()`.
- `liveTv.recordingGroups()` and `recordingsSeries()` → `recordings()` / `recordingFolders()`. Hidden upstream, no direct replacement.
- `hls.stopEncoding()` → `playback.stopped()`. Every HLS controller is hidden from the Jellyfin 12 API.
- `tmdb.clientConfiguration()`. Hidden upstream, no replacement.
- `JellyfinUser.hasPassword`, `hasConfiguredPassword` and `hasConfiguredEasyPassword`. Jellyfin 12 marks them obsolete; `HasPassword` no longer carries information and the EasyPassword feature was removed.

### Added
- `library.collections(itemId:)` — `GET /Items/{itemId}/Collections`, new in Jellyfin 12: every collection that includes an item, for an "Included in" row.
- `persons.list()` gained `startIndex`, `parentId`, `nameStartsWith`, `nameStartsWithOrGreater` and `nameLessThan`. Jellyfin 12 merges artists into people and names `GET /Persons` the successor of the `/Artists` routes, so the wrapper now exposes the endpoint's full parameter set.

### Changed
- `artists.list()`, `albumArtists()` and `byName()` are marked obsolete upstream in favour of `/Persons`, but stay undeprecated here: `/Persons` has no sort or genre filter yet, so it is not an equivalent replacement. Expect them to go in Jellyfin 13.
- Auth wording: the `Authorization: MediaBrowser` header is the only one Jellyfin 12 accepts by default (`EnableLegacyAuthorization` is off on new and upgraded installs, and the `/emby/*` and `/mediabrowser/*` prefixes are gone). The package already sent only that header since 0.1.0; docs and comments now say 12.0 instead of 10.12.
- Integration stack defaults to the `jellyfin/jellyfin:12.0` image. Wipe old volumes (`docker compose down -v`) before the first run so the bootstrap starts from a clean 12.0 database instead of migrating a 10.11 one.

### Notes
- Jellyfin 12 changed `GET /Items` to apply `recursive` whenever filters and `includeItemTypes` are present. `items.list()` always sends `recursive` explicitly (default `true`), so results are unchanged.
- Quick Connect is unaffected: the package already used `POST /QuickConnect/Initiate`; only the `GET` form was removed.

## [0.1.1] - 11-08-2026

### Breaking
- `items.list()` takes `genreIds`, `artistIds` and `albumIds` as `List<String>` instead of a pre-joined `String`. Write `genreIds: ['id1', 'id2']` instead of `genreIds: 'id1,id2'`. The old form made you guess the separator, and the guess was wrong on some endpoints.
- `items.list()` no longer defaults `fields` to the music field set — it now defaults to empty, which is the server's own projection. `/Items` also serves video and photo libraries, where those fields were cost with no benefit. Pass `fields: JellyfinItemsApi.musicFields` to get the old payload back.
- `playlists.items()` likewise no longer defaults `fields` to the music field set. Same fix: pass `fields: JellyfinItemsApi.musicFields`.
- `JellyfinItemsApiFieldsAdapter` is gone. It was a copy of `JellyfinItemsApi.musicFields` that could drift from the original. Use `JellyfinItemsApi.musicFields`.
- `tvShows.episodes()` takes `sortBy` as a single `String?`, not a `List<String>`. Write `sortBy: 'PremiereDate'` instead of `sortBy: const ['PremiereDate']`. This endpoint accepts one sort column, unlike `items.list()`; a list of two never sorted by either.
- `library.similarItems()` takes `excludeArtistIds` as `List<String>` instead of a pre-joined `String`. Write `excludeArtistIds: ['id1', 'id2']`.

### Added
- `items.list()` gained the rest of the filter panel: `excludeItemIds`, `albumArtistIds`, `contributingArtistIds`, `studioIds`, `personIds`, `tags`, `officialRatings`, `years`, `nameStartsWith`, `isFavorite`, `isPlayed`, `enableTotalRecordCount`, and the name-based counterparts `genres`, `artists`, `albums`, `studios`. All of them were reachable on the server already; none of them were reachable from this package.
- `genres.list()` and `musicGenres.list()` gained `descending`. They accepted `sortBy` but had no way to reverse it.

### Changed
- Every multi-value query parameter is now sent as one repeated parameter per value (`genreIds=a&genreIds=b`) instead of a joined string. Jellyfin reads array parameters with a comma-delimited binder on some endpoints and a pipe-delimited one on others, and both take repeated values as-is — so this is the one encoding that is right everywhere, and it no longer breaks on a genre, tag or studio name that contains a comma or a pipe.
- `items.count()` takes the same narrowing parameters as `items.list()`. It previously accepted only `parentId`, `includeItemTypes` and `filters`, so counting a genre- or search-scoped set meant calling `list()` and throwing the items away.
- `items.list()` only sends a sort order when you actually asked for a sort. The server ignores an order with no column to apply it to; the other browse methods already behaved this way.
- `musicGenres.list()` documents that `GET /MusicGenres` is hidden from the published API document and obsolete upstream. It still works. `genres.list(includeItemTypes: ['MusicAlbum', 'Audio'])` is the supported replacement.

### Fixed
- Filtering artists by genre works with more than one genre now. `artists.list()` and `artists.albumArtists()` joined `genreIds` with `|`, but that endpoint reads it comma-separated, so the whole value failed to parse and was dropped — leaving the results unfiltered rather than erroring. The 0.1.0 fix only ever worked for a single genre, where the separator never appears.
- Sorting episodes works now. `tvShows.episodes()` sent `sortBy` comma-joined to a parameter that accepts a single value.
- Filter values containing a comma or a pipe are no longer split into fragments. A genre named `Rock, Pop` now filters on `Rock, Pop`.

## [0.1.0] - 30-06-2026

### Deprecated
- `JellyfinClient.fetchBytes` is deprecated. Use `requestBytes` instead (it already handles full URLs, query parameters and relative paths).

### Breaking
- `JellyfinDeviceProfile.directPlayProfiles` is now a list of `JellyfinDirectPlayProfile` objects instead of strings, and each one says whether it is for audio or video. This fixes audio direct-play, which used to be wrongly tagged as video.
- `images.userImageUrl()` and `images.splashscreenUrl()` now take `tag` and `format` only; the old `width`, `height` and `quality` arguments were dropped because those endpoints ignore them.
- `mediaInfo.info()` now takes only `itemId` and `userId`. The endpoint ignores everything else. Use `postedInfo()` when you need full, bitrate-aware playback info.
- `liveTv.recordings()` dropped `groupId` (it was ignored); `liveTv.recordingsSeries()` swapped its ignored filters for ones the server actually uses (`channelId`, `status`, `isInProgress`, `seriesTimerId`).
- `liveTv.channels()` no longer sorts by default. It keeps the server's own channel order instead of a value Jellyfin rejected.
- The `notify…` methods (added or updated movies and series) now pass the ids (`tmdbId`, `imdbId`, `tvdbId`) the way the server reads them, instead of a body it ignored.
- `criticReviews()` now returns a typed result list instead of raw maps.
- `trailers.list()` dropped `includeItemTypes`. The endpoint never used it.
- Removed the old Emby auth header and the legacy `X-Emby-Authorization` and `X-MediaBrowser-Token` headers; sign-in now uses the single header modern Jellyfin (10.12+) accepts.
- `notifications.connect()` now returns a `Future` and waits for the connection to open before returning. `isConnected` is only `true` (and the keep-alive timer only starts) once the socket is really open, and a failed connection throws straight away.

### Added
- `JellyfinDirectPlayProfile`, with `.audio` and `.video` shortcuts for building device profiles.
- `JellyfinPlayCommand` constants for the remote-control play modes (PlayNow, PlayNext, PlayLast, …).

### Changed
- `artists.list()` and `albumArtists()` can now sort; `user.list()` can filter hidden and disabled accounts.
- Every `userData.*` method now takes an optional `userId`, so an admin can change another user's favourites and play state; `markPlayed` can also backfill a watch date.
- Image URLs gained `fillWidth`, `fillHeight` and `format` (with ready-made `ImageFormat` constants) and can draw watched-progress and unplayed-count overlays.
- `audio.universalStreamUrl()` gained audio-channel controls and dropped an argument the endpoint ignored.
- Search hints now include the album info, and there are two new media-stream checks, `isEmbeddedImage` and `isData`.
- `clientLog.upload()` now returns the filename the server saved.
- You can pass a `CancelToken` to `request()` and `requestBytes()` to cancel a request that is still running; a cancelled request now reports `JellyfinErrorType.cancelled` instead of a generic `unknown`.
- `JellyfinException` now keeps the original stack trace, so crash reports point at where the failure actually happened.

### Fixed
- Sharing a playlist works now. `playlists.setUserAccess()` sends the permission the way the server reads it, instead of in a spot it ignored.
- Sending an on-screen message works now. `sessions.sendMessage()` sends the text in the body the server expects.
- Image uploads work now. The picture is encoded the way the server expects, so avatar, item and splash-screen uploads no longer fail.
- `items.latest()` returns all recent items by default again; the "unplayed only" filter is now optional instead of always on.
- "Has lyrics" is detected correctly now (the value was checked with the wrong spelling, so it was always false).
- Filtering artists by genre works now (the ids were joined with the wrong separator).
- `instantMix.fromMusicGenre()` handles genre names with special characters (`/`, `&`, spaces, `?`) instead of failing.
- `items.byId()` no longer sends an argument the endpoint doesn't accept.
- Sign-in header values are now escaped, so a version with a `+` or a device or client name with quotes or commas no longer corrupts the header.
- `sessions.postCapabilities()` now advertises valid commands by default (the old defaults weren't real command names).
- `syncPlay.queue()` now uses a valid default mode (the old one wasn't accepted).
- `user.updatePassword()` can change another user's password again, using the right argument.
- `hls.stopEncoding()` now always sends the session id it needs.
- The trickplay (scrubbing-thumbnail) playlist URL now points at the right route.
- A response body that can't be decoded is now reported as a `parse` error instead of a generic `unknown` (matching dart_plex).

## [0.0.2] - 25-05-2026

### Fixed
- General minor fixes.

## [0.0.1] - 25-05-2026

### Added
- Initial scaffold targeting Jellyfin `v10.11.9`.
- Authentication flows: AuthenticateByName and Quick Connect.
- `MediaBrowser` `Authorization` header builder with token + device fields.
- Exception hierarchy with semantic error classification (`auth`, `notFound`, `serverError`, `parse`, `state`, `connection`, `timeout`, `badRequest`, `unknown`).
- Music endpoints: user views, items by type, playlists, image URLs, audio streaming (universal + direct + HLS), lyrics, playback reporting, search, favorites.
- Typed DTOs across the documented API surface, plus a `raw` escape hatch on every model for fields not yet promoted.
