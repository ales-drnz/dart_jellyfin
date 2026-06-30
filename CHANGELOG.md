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
