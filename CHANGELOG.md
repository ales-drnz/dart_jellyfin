## [0.3.0] - 11-10-2026

A revision of the whole package, for Jellyfin `12.2`. See [MIGRATION.md](MIGRATION.md) for the changes to make in an app.

### Breaking
- The transport is `package:http`, not Dio. Pass any `http.Client` as `httpClient:` (`dio:` is gone). `request()` and its siblings return a `JellyfinResponse<T>` and take a `JellyfinResponseType` and a `JellyfinCancelToken`. `JellyfinException.fromDio` and `fetchBytes()` are gone.
- Every id, name and key is a named parameter: `items.byId(itemId: …)`, `playlists.delete(playlistId: …)`, `userData.setFavorite(itemId: …, isFavorite: …)` and so on. A method whose only argument is a request body keeps it positional.
- `includeItemTypes`, `excludeItemTypes`, `fields`, `sortBy`, `mediaTypes` and `filters` (and `suggestions.list()`'s `type` and `mediaType`, `sessions.postCapabilities()`'s `playableMediaTypes`) take `JellyfinItemKind`, `JellyfinItemField`, `JellyfinSortField`, `JellyfinMediaType` and `JellyfinItemFilter` instead of strings, so a misspelled value no longer compiles. A value the package does not list is `JellyfinItemKind('Kind')`.
- Playlist entry ids are a `JellyfinPlaylistEntryId`: `JellyfinItem.playlistItemId`, `playlists.removeItems(entryIds:)` and `moveItem(playlistItemId:)`.
- `system.endpointInfo()`, `utcTime()`, `scheduledTasks.list()`, `byId()`, `library.counts()`, `devices.list()`, `info()`, `activityLog.entries()`, `images.listItemImages()`, `lyrics.searchRemote()`, `syncPlay.list()`, `group()` and `playlists.users()` return typed models instead of maps. `scheduledTasks.byId()`, `devices.info()` and `syncPlay.group()` return `null` when there is no such item.
- The API exposes `Object?` instead of `dynamic` in its maps and lists.
- Models, `JellyfinException`, `JellyfinCredentials` and `JellyfinNotification` are `final`. `JellyfinClient` and the sub-APIs gained members, so a fake that implements one must add them.
- A list or object answer of the wrong shape throws a `parse` error instead of returning an empty result.
- `JellyfinItemsApi.musicFields` no longer lists `AlbumPrimaryImageTag`, which is not a field: the server sends it on every track.
- `images.url(backgroundColor:)` throws `ArgumentError` for a value that is not a hex colour.
- `JellyfinLyricLine.toLrcLine()` truncates timestamps to the centisecond instead of rounding them.
- In `request()`, a JSON string body asked for as a `String` is decoded, and an empty answer without a JSON content type is `null`, not `""`. Query values that are not strings are form-encoded, and a `List<int>` body is sent as bytes.

### Added
- `JellyfinClient.withCancelToken()`, a view of the client whose calls one token cancels, and `JellyfinClient.close()`.
- `JellyfinRetryPolicy`: opt-in resend of `GET` and `HEAD` after a network failure, `502`, `503`, `504` or `429`, with backoff and `Retry-After`.
- `JellyfinException.isNetworkFailure`, `isTransient`, `isNotFound`, `isCancelled` and `retryAfter`.
- `requestStream()`, and `downloadToFile()` in the new `package:dart_jellyfin/io.dart`.
- Typed notification events: `JellyfinEvent` with `JellyfinUserDataChangedEvent`, `JellyfinLibraryChangedEvent`, `JellyfinSessionsEvent`, `JellyfinPlayEvent`, `JellyfinPlaystateEvent`, `JellyfinGeneralCommandEvent`, `JellyfinRefreshProgressEvent`, `JellyfinScheduledTasksInfoEvent`, `JellyfinScheduledTaskEndedEvent`, `JellyfinKeepAliveEvent` and `JellyfinUnknownEvent`, through `notification.event` or `stream.events()`.
- `audio.transcodedStreamUrl()`: a progressive transcode at a given bitrate, for downloads. `audio.directStreamUrl()` takes a `playSessionId`.
- `JellyfinLyricLine.cues`, `JellyfinLyrics.metadata`, `hasCues` and `toLrc(enhanced: true)`, for word-level lyrics.
- `JellyfinItem.people`, `recursiveItemCount`, `albumCount`, `songCount`, `artistCount`, `musicVideoCount`, `movieCount`, `seriesCount`, `episodeCount`, `trailerCount` and `programCount`.
- `JellyfinItem.normalizationGain`, `albumNormalizationGain`, `primaryImageTag`, `artworkItemId`, `artworkVersion`, `genreItems`, `albumArtistItems` and `playlistItemId`.
- `JellyfinItemsApi.browseFields`, a light field set for grids.
- `images.url()` takes `maxWidth`, `maxHeight`, `blur` and `backgroundColor`, and `images.fetch()` the same sizing parameters and a cancel token.
- `hls.audioVariantUrl()` and `audioMasterUrl()` take `segmentContainer`, `segmentLength`, `minSegments`, `enableAutoStreamCopy`, `allowAudioStreamCopy`, `audioSampleRate`, `maxAudioBitDepth` and `context`.
- `playback.start(method:)` and `playback.progress(method:, order:, repeat:)`, with `JellyfinPlayMethod`, `JellyfinPlaybackOrder` and `JellyfinRepeatMode`.
- `subtitles.streamWithTicksUrl(endPositionTicks:)`.
- `JellyfinPaging.pages()` and `items()`.

### Changed
- Large responses are decoded, inflated and parsed into models on a background isolate, above `jsonIsolateThreshold` (50 KB by default).
- `playlists.rename()`, `update()` and `delete()` wait until a second has passed since this client last changed that playlist's entries, because the server drops a rename sent right after.
- `musicGenres.list()` is deprecated in favour of `genres.list(parentId:)` with the music library, which returns the same ids. `musicGenres.byName()` is not deprecated, and `instantMix.fromMusicGenre()` points to it.
- `playback.start()` and `progress()` with `playMethod:`, `playbackOrder:` and `repeatMode:` strings are deprecated: use `method:`, `order:` and `repeat:`.
- `audio.lyricsRaw()` is deprecated: use `lyrics()` with `toLrc()` or `toPlainText()`.
- `liveTv.channels(searchTerm:)`, `tvShows.nextUp(disableFirstEpisode:)`, `videos.streamUrl(maxStreamingBitrate:)`, the video HLS builders' `maxStreamingBitrate` and `subtitles.streamWithTicksUrl(segmentLength:)` are deprecated and not sent: their routes do not read them.
- `isRetriable` is deprecated: use `isNetworkFailure`, or `isTransient` to include 5xx and 429.
- The integration stack runs Jellyfin `12.2`, and a contract test checks every request against its pinned API document.

### Fixed
- `subtitles.fetch()` and `fetchFromPosition()` read UTF-8 text as UTF-8: accented characters came back mangled.
- `DeviceId` is no longer sent on the legacy HLS segment URLs, which do not read it.
- A gzip body cut short fails instead of coming back short.

## [0.2.1] - 22-09-2026

### Changed
- The default transport decodes JSON responses of 50 KB or more on a background isolate (`JellyfinConnection.jsonIsolateThreshold`). A `Dio` you inject keeps its own transformer.

## [0.2.0] - 09-09-2026

For Jellyfin `12.0`.

### Breaking
- `library.criticReviews()`, `environment.networkShares()` and `liveTv.recordingGroup()` are gone: Jellyfin 12 removed their routes.
- `playback.legacyStart()`, `legacyProgress()` and `legacyStopped()` are gone: use `playback.start()`, `progress()` and `stopped()`.
- `JellyfinUser` no longer requires `hasPassword`, `hasConfiguredPassword` and `hasConfiguredEasyPassword`; they default to `false`.

### Added
- `library.collections(itemId:)`: the collections that include an item.
- `persons.list()` takes `startIndex`, `parentId`, `nameStartsWith`, `nameStartsWithOrGreater` and `nameLessThan`.

### Changed
- The routes Jellyfin 12 marks obsolete or hides are deprecated, each with its replacement: `trailers.list()`, `musicGenres.list()` and `byName()`, `instantMix.fromMusicGenre()`, `fromMusicGenreById()` and `fromArtistByName()`, `startup.configuration()`, `updateInitialConfiguration()`, `setRemoteAccess()` and `firstUserAlt()`, `liveTv.recordingGroups()` and `recordingsSeries()`, `hls.stopEncoding()` and `tmdb.clientConfiguration()`.
- `JellyfinUser.hasPassword`, `hasConfiguredPassword` and `hasConfiguredEasyPassword` are deprecated: Jellyfin 12 no longer fills them.
- `artists.list()`, `albumArtists()` and `byName()` are not deprecated: `/Persons` has no sort or genre filter to replace them.
- `items.list()` always sends `recursive` (default `true`).
- The integration stack runs Jellyfin `12.0`.

### Fixed
- Signed URLs and the notifications socket carry the token as `ApiKey`, not `api_key`, which Jellyfin 12 rejects by default.

## [0.1.1] - 11-08-2026

### Breaking
- `items.list()` takes `genreIds`, `artistIds` and `albumIds` as `List<String>` instead of a joined `String`.
- `items.list()` and `playlists.items()` no longer default `fields` to the music set: pass `fields: JellyfinItemsApi.musicFields`.
- `JellyfinItemsApiFieldsAdapter` is gone: use `JellyfinItemsApi.musicFields`.
- `tvShows.episodes()` takes `sortBy` as one `String?`: the endpoint sorts by a single column.
- `library.similarItems()` takes `excludeArtistIds` as `List<String>`.

### Added
- `items.list()` takes `excludeItemIds`, `albumArtistIds`, `contributingArtistIds`, `studioIds`, `personIds`, `tags`, `officialRatings`, `years`, `nameStartsWith`, `isFavorite`, `isPlayed`, `enableTotalRecordCount`, `genres`, `artists`, `albums` and `studios`.
- `genres.list()` and `musicGenres.list()` take `descending`.

### Changed
- A multi-value query parameter is sent as one parameter per value (`genreIds=a&genreIds=b`), the encoding every endpoint reads, also for values that contain a comma or a pipe.
- `items.count()` takes the same narrowing parameters as `items.list()`.
- `items.list()` sends a sort order only with a sort column.

### Fixed
- `artists.list()` and `albumArtists()` filter by more than one genre.
- `tvShows.episodes()` sorts.
- A filter value containing a comma or a pipe is no longer split.

## [0.1.0] - 30-06-2026

### Breaking
- `JellyfinDeviceProfile.directPlayProfiles` is a list of `JellyfinDirectPlayProfile`, each for audio or video.
- `images.userImageUrl()` and `splashscreenUrl()` take `tag` and `format` only.
- `mediaInfo.info()` takes only `itemId` and `userId`; use `postedInfo()` for full playback info.
- `liveTv.recordings()` drops `groupId`; `liveTv.recordingsSeries()` takes `channelId`, `status`, `isInProgress` and `seriesTimerId`.
- `liveTv.channels()` keeps the server's channel order by default.
- The `notify…` methods send `tmdbId`, `imdbId` and `tvdbId` the way the server reads them.
- `criticReviews()` returns typed results.
- `trailers.list()` drops `includeItemTypes`.
- Sign-in sends only the `Authorization: MediaBrowser` header.
- `notifications.connect()` returns a `Future` that completes once the socket is open, and a failed connection throws.

### Added
- `JellyfinDirectPlayProfile`, with `.audio` and `.video`.
- `JellyfinPlayCommand` constants for the remote-control play modes.

### Changed
- `artists.list()` and `albumArtists()` sort; `user.list()` filters hidden and disabled accounts.
- Every `userData.*` method takes an optional `userId`, and `markPlayed` a date.
- Image URLs take `fillWidth`, `fillHeight` and `format`, and draw watched-progress and unplayed-count overlays.
- `audio.universalStreamUrl()` takes audio-channel controls.
- Search hints include the album, and media streams have `isEmbeddedImage` and `isData`.
- `clientLog.upload()` returns the saved filename.
- `request()` and `requestBytes()` take a `CancelToken`; a cancelled request is `JellyfinErrorType.cancelled`.
- `JellyfinException` keeps the original stack trace.
- `JellyfinClient.fetchBytes` is deprecated: use `requestBytes`.

### Fixed
- `playlists.setUserAccess()` shares a playlist.
- `sessions.sendMessage()` sends the message.
- Image uploads are encoded the way the server reads them.
- `items.latest()` returns all recent items by default.
- "Has lyrics" is detected.
- Filtering artists by genre joins the ids with the right separator.
- `instantMix.fromMusicGenre()` handles names with special characters.
- `items.byId()` sends only the arguments the endpoint takes.
- Sign-in header values are escaped.
- `sessions.postCapabilities()` advertises real command names.
- `syncPlay.queue()` uses a valid default mode.
- `user.updatePassword()` changes another user's password.
- `hls.stopEncoding()` sends the session id.
- The trickplay playlist URL points at the right route.
- A body that cannot be decoded is a `parse` error.

## [0.0.2] - 25-05-2026

### Fixed
- General minor fixes.

## [0.0.1] - 25-05-2026

### Added
- Initial release, for Jellyfin `v10.11.9`.
- Sign-in by name and with Quick Connect.
- The `Authorization: MediaBrowser` header with the token and the device fields.
- `JellyfinException` with a semantic `JellyfinErrorType`.
- Music endpoints: user views, items by type, playlists, image URLs, audio streaming (universal, direct and HLS), lyrics, playback reporting, search and favourites.
- Typed models, each with a `raw` map.
