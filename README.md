# dart_jellyfin

#### Jellyfin client for Flutter and Dart.

[![](https://img.shields.io/pub/v/dart_jellyfin.svg?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/dart_jellyfin)
[![](https://img.shields.io/badge/jellyfin-v12.2-orange.svg?style=for-the-badge)](https://api.jellyfin.org)
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg?style=for-the-badge)](LICENSE)
[![](https://img.shields.io/github/stars/ales-drnz/dart_jellyfin?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ales-drnz/dart_jellyfin)
[![](https://img.shields.io/discord/1485588004029333516?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/g2Qf4Mq9MP)
[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)
[![](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/ales.drnz)

<table>
<tr>
<td valign="middle" width="90"><img src="https://raw.githubusercontent.com/ales-drnz/dart_jellyfin/main/imgs/dart_jellyfin.png" width="70" alt="logo"></td>
<td valign="middle"><code>dart_jellyfin</code> is a Dart client for Jellyfin <code>v12.2</code> (tested against 12.0 and 12.2). It covers libraries, playlists, audio streaming, lyrics, playback reporting and search through typed Dart objects, and handles the session lifecycle for you.</td>
</tr>
</table>

---

## Installation

Add `dart_jellyfin` to your `pubspec.yaml`:

```yaml
dependencies:
  dart_jellyfin: ^0.3.0
```

`package:dart_jellyfin/dart_jellyfin.dart` is the library; file downloads
live in `package:dart_jellyfin/io.dart`, because they need `dart:io`.
Coming from 0.2.x? [MIGRATION.md](MIGRATION.md) lists every breaking change
with what to write instead.

---

## Contents

*   [Features](#features)
*   [Quick start](#quick-start)
*   [Guide](#guide)
    <details>
    <summary><a href="#1-initialization-and-lifecycle"><b>1. Initialization and lifecycle</b></a></summary>

    * [1.1 Creating a client](#11-creating-a-client)
    * [1.2 Credentials and the Authorization header](#12-credentials-and-the-authorization-header)
    * [1.3 Connecting to a server](#13-connecting-to-a-server)
    * [1.4 Session management](#14-session-management)
    * [1.5 Disposing](#15-disposing)
    * [1.6 Choosing the HTTP stack](#16-choosing-the-http-stack)
    * [1.7 Cancellation](#17-cancellation)
    * [1.8 Retries](#18-retries)

    </details>

    <details>
    <summary><a href="#2-authentication"><b>2. Authentication</b></a></summary>

    * [2.1 Username and password](#21-username-and-password)
    * [2.2 Quick Connect flow](#22-quick-connect-flow)
    * [2.3 Current user](#23-current-user)
    * [2.4 Public users](#24-public-users)

    </details>

    <details>
    <summary><a href="#3-system-info"><b>3. System info</b></a></summary>

    * [3.1 Public system info (no auth)](#31-public-system-info-no-auth)
    * [3.2 Authenticated info](#32-authenticated-info)
    * [3.3 Ping](#33-ping)
    * [3.4 Server and housekeeping](#34-server-and-housekeeping)

    </details>

    <details>
    <summary><a href="#4-library-browsing"><b>4. Library browsing</b></a></summary>

    * [4.1 User views](#41-user-views)
    * [4.2 Listing items](#42-listing-items)
    * [4.3 Counting items](#43-counting-items)
    * [4.4 Single item](#44-single-item)
    * [4.5 Resume and latest](#45-resume-and-latest)
    * [4.6 BaseItemKind reference](#46-baseitemkind-reference)
    * [4.7 Field presets](#47-field-presets)
    * [4.8 Paging](#48-paging)

    </details>

    <details>
    <summary><a href="#5-playlists"><b>5. Playlists</b></a></summary>

    * [5.1 Creating a playlist](#51-creating-a-playlist)
    * [5.2 Listing items](#52-listing-items)
    * [5.3 Adding and removing](#53-adding-and-removing)
    * [5.4 Renaming and deleting](#54-renaming-and-deleting)

    </details>

    <details>
    <summary><a href="#6-search"><b>6. Search</b></a></summary>

    * [6.1 Search hints](#61-search-hints)

    </details>

    <details>
    <summary><a href="#7-audio-streaming"><b>7. Audio streaming</b></a></summary>

    * [7.1 Universal stream URL](#71-universal-stream-url)
    * [7.2 Direct stream URL](#72-direct-stream-url)
    * [7.3 Lyrics](#73-lyrics)

    </details>

    <details>
    <summary><a href="#8-video-streaming"><b>8. Video streaming</b></a></summary>

    * [8.1 Stream URL](#81-stream-url)
    * [8.2 Additional parts](#82-additional-parts)
    * [8.3 Recommended pre-flight](#83-recommended-pre-flight)

    </details>

    <details>
    <summary><a href="#9-hls-playlists"><b>9. HLS playlists</b></a></summary>

    * [9.1 Audio master and variant](#91-audio-master-and-variant)
    * [9.2 Video master and variant](#92-video-master-and-variant)
    * [9.3 Segments and live](#93-segments-and-live)

    </details>

    <details>
    <summary><a href="#10-subtitles"><b>10. Subtitles</b></a></summary>

    * [10.1 Subtitle stream URL](#101-subtitle-stream-url)
    * [10.2 Fetching subtitle text](#102-fetching-subtitle-text)
    * [10.3 Supported formats](#103-supported-formats)
    * [10.4 Upload and delete](#104-upload-and-delete)
    * [10.5 Remote search and download](#105-remote-search-and-download)
    * [10.6 Fallback fonts](#106-fallback-fonts)

    </details>

    <details>
    <summary><a href="#11-trickplay"><b>11. Trickplay</b></a></summary>

    * [11.1 Tile URL](#111-tile-url)
    * [11.2 HLS tile playlist](#112-hls-tile-playlist)

    </details>

    <details>
    <summary><a href="#12-media-info-and-playback-negotiation"><b>12. Media info and playback negotiation</b></a></summary>

    * [12.1 Quick playback info](#121-quick-playback-info)
    * [12.2 Posting a device profile](#122-posting-a-device-profile)
    * [12.3 Live streams](#123-live-streams)
    * [12.4 Bitrate probe](#124-bitrate-probe)

    </details>

    <details>
    <summary><a href="#13-images"><b>13. Images</b></a></summary>

    * [13.1 Building an image URL](#131-building-an-image-url)
    * [13.2 Fetching bytes](#132-fetching-bytes)
    * [13.3 Image types](#133-image-types)

    </details>

    <details>
    <summary><a href="#14-playback-reporting"><b>14. Playback reporting</b></a></summary>

    * [14.1 Start](#141-start)
    * [14.2 Progress](#142-progress)
    * [14.3 Stopped](#143-stopped)
    * [14.4 Ping](#144-ping)

    </details>

    <details>
    <summary><a href="#15-sessions-and-remote-control"><b>15. Sessions and remote control</b></a></summary>

    * [15.1 Listing sessions](#151-listing-sessions)
    * [15.2 Registering this client as a cast target](#152-registering-this-client-as-a-cast-target)
    * [15.3 Playing on a remote session](#153-playing-on-a-remote-session)
    * [15.4 Playstate commands](#154-playstate-commands)
    * [15.5 General and system commands](#155-general-and-system-commands)
    * [15.6 Messages and DisplayContent](#156-messages-and-displaycontent)

    </details>

    <details>
    <summary><a href="#16-user-data"><b>16. User data</b></a></summary>

    * [16.1 Favorites](#161-favorites)
    * [16.2 Played flag](#162-played-flag)
    * [16.3 Reading and writing the record](#163-reading-and-writing-the-record)

    </details>

    <details>
    <summary><a href="#17-instant-mix"><b>17. Instant Mix</b></a></summary>

    * [17.1 From any seed item](#171-from-any-seed-item)
    * [17.2 From a typed seed](#172-from-a-typed-seed)

    </details>

    <details>
    <summary><a href="#18-live-tv"><b>18. Live TV</b></a></summary>

    * [18.1 Channels](#181-channels)
    * [18.2 Programs and EPG](#182-programs-and-epg)
    * [18.3 Recordings](#183-recordings)
    * [18.4 Timers](#184-timers)

    </details>

    <details>
    <summary><a href="#19-syncplay"><b>19. SyncPlay</b></a></summary>

    * [19.1 Listing and joining groups](#191-listing-and-joining-groups)
    * [19.2 Group playback control](#192-group-playback-control)
    * [19.3 Group queue](#193-group-queue)

    </details>

    <details>
    <summary><a href="#20-tv-shows"><b>20. TV Shows</b></a></summary>

    * [20.1 Seasons of a series](#201-seasons-of-a-series)
    * [20.2 Episodes of a season](#202-episodes-of-a-season)
    * [20.3 Next Up](#203-next-up)
    * [20.4 Upcoming episodes](#204-upcoming-episodes)

    </details>

    <details>
    <summary><a href="#21-movies"><b>21. Movies</b></a></summary>

    * [21.1 Movie recommendations](#211-movie-recommendations)

    </details>

    <details>
    <summary><a href="#22-suggestions"><b>22. Suggestions</b></a></summary>

    * [22.1 Homepage suggestions](#221-homepage-suggestions)

    </details>

    <details>
    <summary><a href="#23-media-segments"><b>23. Media segments</b></a></summary>

    * [23.1 Listing segments](#231-listing-segments)
    * [23.2 Segment types](#232-segment-types)

    </details>

    <details>
    <summary><a href="#24-filters"><b>24. Filters</b></a></summary>

    * [24.1 Modern facets (with ids)](#241-modern-facets-with-ids)
    * [24.2 Legacy facets](#242-legacy-facets)

    </details>

    <details>
    <summary><a href="#25-artists"><b>25. Artists</b></a></summary>

    * [25.1 Listing artists](#251-listing-artists)
    * [25.2 Album artists only](#252-album-artists-only)
    * [25.3 Lookup by name](#253-lookup-by-name)

    </details>

    <details>
    <summary><a href="#26-display-preferences"><b>26. Display preferences</b></a></summary>

    * [26.1 Reading a document](#261-reading-a-document)
    * [26.2 Writing back](#262-writing-back)
    * [26.3 Custom prefs](#263-custom-prefs)

    </details>

    <details>
    <summary><a href="#27-lyrics"><b>27. Lyrics</b></a></summary>

    * [27.1 Reading attached lyrics](#271-reading-attached-lyrics)
    * [27.2 Uploading a file](#272-uploading-a-file)
    * [27.3 Deleting](#273-deleting)
    * [27.4 Remote search and download](#274-remote-search-and-download)

    </details>

    <details>
    <summary><a href="#28-channels"><b>28. Channels</b></a></summary>

    * [28.1 Listing channels](#281-listing-channels)
    * [28.2 Items inside a channel](#282-items-inside-a-channel)
    * [28.3 Latest across channels](#283-latest-across-channels)
    * [28.4 Channel features](#284-channel-features)

    </details>

    <details>
    <summary><a href="#29-collections"><b>29. Collections</b></a></summary>

    * [29.1 Creating a collection](#291-creating-a-collection)
    * [29.2 Adding and removing](#292-adding-and-removing)
    * [29.3 Collections containing an item](#293-collections-containing-an-item)

    </details>

    <details>
    <summary><a href="#30-user-views-alternate"><b>30. User views (alternate)</b></a></summary>

    * [30.1 Listing with filters](#301-listing-with-filters)
    * [30.2 Grouping options](#302-grouping-options)

    </details>

    <details>
    <summary><a href="#31-browse-facets"><b>31. Browse facets</b></a></summary>

    * [31.1 Persons](#311-persons)
    * [31.2 Studios](#312-studios)
    * [31.3 Genres](#313-genres)
    * [31.4 Music genres](#314-music-genres)
    * [31.5 Years](#315-years)

    </details>

    <details>
    <summary><a href="#32-localization"><b>32. Localization</b></a></summary>

    * [32.1 Countries and cultures](#321-countries-and-cultures)
    * [32.2 Parental ratings](#322-parental-ratings)
    * [32.3 Server localization options](#323-server-localization-options)

    </details>

    <details>
    <summary><a href="#33-error-handling"><b>33. Error handling</b></a></summary>

    * [33.1 JellyfinException and JellyfinErrorType](#331-jellyfinexception-and-jellyfinerrortype)
    * [33.2 Retriable vs terminal](#332-retriable-vs-terminal)
    * [33.3 Auth invalidation](#333-auth-invalidation)

    </details>

    <details>
    <summary><a href="#34-escape-hatch"><b>34. Escape hatch</b></a></summary>

    * [34.1 Raw request](#341-raw-request)
    * [34.2 Raw bytes](#342-raw-bytes)
    * [34.3 Streamed body](#343-streamed-body)

    </details>

    <details>
    <summary><a href="#35-downloads"><b>35. Downloads</b></a></summary>

    * [35.1 Downloading to a file](#351-downloading-to-a-file)

    </details>
*   [Project background](#project-background)

---

## Features

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/package.png" width="32"></td>
<td valign="middle" width="45%"><b>Pure Dart</b><br>no native plugin, no Flutter dependency. Runs on every Dart-supported platform.</td>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/shield-check.png" width="32"></td>
<td valign="middle" width="45%"><b>Typed DTOs</b><br>every response is a typed Dart object (items, media, streams, users, search hints), each with a <code>.raw</code> map so new server fields are never lost.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/key-round.png" width="32"></td>
<td valign="middle"><b>Both auth flows</b><br><code>user.authenticateByName()</code> for credentials, plus <code>quickConnect.initiate()</code> + <code>state()</code> + <code>user.authenticateWithQuickConnect()</code> for the Quick Connect link flow.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/wrench.png" width="32"></td>
<td valign="middle"><b>Authorization header builder</b><br><code>MediaBrowser Client="…", Device="…", DeviceId="…", Version="…", Token="…"</code> built correctly and refreshed when the token changes. Emitted as the single <code>Authorization: MediaBrowser</code> header. It is the only auth path Jellyfin 12 accepts out of the box.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/layers.png" width="32"></td>
<td valign="middle"><b>Stateful façade</b><br>one <code>JellyfinClient</code> holds your identity, server, token and user. Every sub-API works through it, so you set things up once.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/file-code.png" width="32"></td>
<td valign="middle"><b>Built on the official OpenAPI spec</b><br>endpoint names, field names and casing match the upstream contract at <a href="https://api.jellyfin.org">api.jellyfin.org</a>. Nothing is reinvented.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/music.png" width="32"></td>
<td valign="middle"><b>Lyrics with timing</b><br><code>JellyfinLyrics</code> exposes parsed lines with <code>Duration</code> getters and word-level cues, plus <code>.toLrc()</code> to render LRC (or enhanced LRC) for any synced-lyrics player.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/audio-lines.png" width="32"></td>
<td valign="middle"><b>Audio streaming</b><br><code>audio.universalStreamUrl()</code> lets the server decide direct-play vs transcoding; <code>audio.directStreamUrl()</code> gives the zero-transcode original.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/triangle-alert.png" width="32"></td>
<td valign="middle"><b>Semantic errors</b><br>every failure is a <code>JellyfinException</code> you can branch on (auth, not found, timeout, connection, cancelled), never a raw network error in your code.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/terminal.png" width="32"></td>
<td valign="middle"><b>Escape hatch</b><br><code>client.request&lt;T&gt;()</code>, <code>client.requestBytes()</code> and <code>client.requestStream()</code> for endpoints not yet covered by the typed sub-APIs.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/globe.png" width="32"></td>
<td valign="middle"><b>Any HTTP stack</b><br>built on <code>package:http</code>: inject a <code>CupertinoClient</code> or <code>CronetClient</code> for HTTP/2 and the system proxy, or a <code>MockClient</code> in tests.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/cpu.png" width="32"></td>
<td valign="middle"><b>Off the caller's isolate</b><br>large responses are inflated, decoded and parsed into models on a background isolate, so a 1.5 MB page does not stall your UI.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/zap.png" width="32"></td>
<td valign="middle"><b>Cancellation and retries</b><br><code>withCancelToken()</code> makes every call of a view cancellable; an opt-in <code>JellyfinRetryPolicy</code> resends idempotent requests after transient failures.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/download.png" width="32"></td>
<td valign="middle"><b>Streaming downloads</b><br><code>downloadToFile()</code> in <code>package:dart_jellyfin/io.dart</code> writes a body to disk as it arrives, with progress, and never leaves a partial file.</td>
</tr>
</table>

---

## Quick start

```dart
import 'package:dart_jellyfin/dart_jellyfin.dart';

Future<void> main() async {
  final jellyfin = JellyfinClient(
    baseUrl: 'https://jellyfin.example.com',
    credentials: const JellyfinCredentials(
      client: 'MyApp',
      device: 'iPhone',
      deviceId: 'PUT-YOUR-UUID-HERE', // stable per install
      version: '1.0.0',
    ),
  );

  // 1. Authenticate.
  final auth = await jellyfin.user.authenticateByName(
    username: 'me',
    password: 'hunter2',
  );
  jellyfin.setSession(token: auth.accessToken, userId: auth.user.id);

  // 2. Browse the user's libraries.
  final views = await jellyfin.library.userViews();
  final music = views.firstWhere((v) => v.isMusic);

  // 3. List 50 albums.
  final albums = await jellyfin.items.list(
    parentId: music.id,
    includeItemTypes: const [JellyfinItemKind.musicAlbum],
    sortBy: const ['SortName'],
    limit: 50,
  );

  // 4. Play a track.
  final track = albums.items.first;
  final url = jellyfin.audio.universalStreamUrl(
    itemId: track.id,
    maxStreamingBitrate: 320000,
    audioCodec: 'aac',
    playSessionId: 'my-session-uuid',
  );
  // hand `url` to your audio engine

  // 5. Release the HTTP client when the app is done with the server.
  jellyfin.close();
}
```

---

## Guide

### 1. Initialization and lifecycle

#### 1.1 Creating a client

```dart
final jellyfin = JellyfinClient(
  baseUrl: 'https://jellyfin.example.com',
  credentials: const JellyfinCredentials(
    client: 'MyApp',
    device: 'iPhone',
    deviceId: '2f5b-…-uuid',
    version: '1.0.0',
  ),
);
```

The `baseUrl` is optional and can be set later via `connect()`. The
other constructor parameters are optional too:

| Parameter | Default | Meaning |
| :--- | :--- | :--- |
| `httpClient` | a `dart:io` / browser client | the `package:http` client to send through (see [1.6](#16-choosing-the-http-stack)) |
| `connectTimeout` | 15 s | bounds the handshake (default client) and, with `receiveTimeout`, the wait for response headers |
| `receiveTimeout` | 30 s | also bounds every pause inside a response body |
| `jsonIsolateThreshold` | 50 KB | bodies this size or larger are decoded, and parsed into models, on a background isolate |
| `retryPolicy` | `JellyfinRetryPolicy.none` | opt-in resend of idempotent requests (see [1.8](#18-retries)) |

With the default `dart:io` client, a gzip body is inflated as part of
that decode, so above the threshold it too leaves the caller's isolate.
On the web there are no isolates and the work runs in place.

`JellyfinClient` and its sub-API classes are not `final`, so your tests
can implement or mock them. The models are `final` data classes.

#### 1.2 Credentials and the Authorization header

`JellyfinCredentials` describes who the client is. Every request
carries:

```
Authorization: MediaBrowser Client="MyApp", Device="iPhone", DeviceId="…uuid…", Version="1.0.0"
```

After login the same line gets a `, Token="…"` suffix. Only this
`Authorization: MediaBrowser` header is emitted; the deprecated
`X-Emby-Authorization` and `X-MediaBrowser-Token` headers are no longer
sent. Jellyfin 12 rejects them by default (`EnableLegacyAuthorization`
is off on new and upgraded installs) and the `/emby/*` and
`/mediabrowser/*` route prefixes are gone, so this is the only header
that works.

`deviceId` MUST be a **stable per-installation UUID**. Jellyfin
tracks sessions by it. Generate it once, persist it (SharedPreferences,
Keychain, Android Keystore…), and reuse it forever.

You can also build the header value directly via the public helper:

```dart
final header = JellyfinAuthHeader.build(credentials, token: someToken);
```

#### 1.3 Connecting to a server

```dart
jellyfin.connect('https://jellyfin.example.com');
```

A trailing slash is stripped. Calling `connect()` again switches the
client to a new server; the session (token + userId) is **not**
cleared automatically. Call `clearSession()` first if needed.

#### 1.4 Session management

```dart
jellyfin.setSession(token: '…', userId: '…');
jellyfin.clearSession();    // drop token + userId, keep baseUrl
jellyfin.disconnect();      // drop everything
```

`token` and `userId` are exposed read-only via getters so you can
persist them yourself:

```dart
final token = jellyfin.token;
final userId = jellyfin.userId;
```

#### 1.5 Disposing

```dart
jellyfin.close();
```

`close()` closes the HTTP client the `JellyfinClient` created. Later
requests, through it or any `withCancelToken()` view, fail with
`JellyfinErrorType.state`. An injected `httpClient` is left alone: you
created it, you close it.

#### 1.6 Choosing the HTTP stack

The transport is `package:http`, so any `http.Client` works. On Apple
platforms and Android the native stacks give HTTP/2, the system proxy
and the platform's certificate store:

```dart
// CupertinoClient.defaultSessionConfiguration() (package:cupertino_http),
// CronetClient.defaultCronetEngine() (package:cronet_http), or any other
// http.Client.
final http.Client httpClient = http.Client();

final jellyfin = JellyfinClient(
  baseUrl: 'https://jellyfin.example.com',
  credentials: credentials,
  httpClient: httpClient,
);

// … later: an injected client is yours to close.
httpClient.close();
```

In tests, pass a `MockClient` from `package:http/testing.dart`. An
injected client handles gzip itself (native stacks do it on their own
threads).

#### 1.7 Cancellation

`withCancelToken()` returns a view of the client whose every sub-API
call is cancelled by one `JellyfinCancelToken`. The view shares the
connection pool, server and session, and costs nothing to create, so
make one per page, filter or search term:

```dart
JellyfinCancelToken? pageToken;

Future<void> showAlbums(String libraryId) async {
  pageToken?.cancel(); // drop the previous page's requests
  final token = pageToken = JellyfinCancelToken();
  try {
    final albums = await jellyfin.withCancelToken(token).items.list(
          parentId: libraryId,
          includeItemTypes: const [JellyfinItemKind.musicAlbum],
          limit: 50,
        );
    print(albums.items.length);
  } on JellyfinException catch (e) {
    if (e.isCancelled) return; // not a failure
    rethrow;
  }
}
```

A cancelled call throws a `JellyfinException` of type
`JellyfinErrorType.cancelled`. A token cancels once; make a new one for
the next page. `request()`, `requestBytes()`, `requestStream()` and
`images.fetch()` also take a `cancelToken:` directly. The notifications
WebSocket is not a request and is not cancelled.

#### 1.8 Retries

Off by default. Pass a `JellyfinRetryPolicy` to resend idempotent
requests after a transient failure:

```dart
final jellyfin = JellyfinClient(
  credentials: credentials,
  retryPolicy: const JellyfinRetryPolicy(), // up to 3 attempts in all
);

// Or tune it:
const patient = JellyfinRetryPolicy(
  maxAttempts: 5,
  initialDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 10),
);
```

The defaults are `maxAttempts: 3` (the first attempt included),
`initialDelay: 300 ms` and `maxDelay: 5 s`.

Only `GET` and `HEAD` are resent, and only after no answer at all
(connection lost, timeout), `502`, `503`, `504` or `429`. A `500` is not
retried. The wait grows exponentially with full jitter; a `Retry-After`
header (in seconds) is honoured up to `maxDelay`, and a cancel token
also cancels the wait. Opening a stream is retried too; a body already
flowing is not replayed.

---

### 2. Authentication

#### 2.1 Username and password

```dart
final auth = await jellyfin.user.authenticateByName(
  username: 'me',
  password: 'hunter2',
);
jellyfin.setSession(token: auth.accessToken, userId: auth.user.id);
```

Returns a `JellyfinAuthResult` with `accessToken`, `serverId`, and the
full `JellyfinUser`. Throws `JellyfinException(type: auth)` on bad
credentials.

#### 2.2 Quick Connect flow

Quick Connect lets a new device authenticate without typing a
password, by approving a 6-character code on an already-logged-in
device.

```dart
// 0. Is Quick Connect enabled on the server?
if (!await jellyfin.quickConnect.enabled()) { return; }

// 1. Start the flow on the new device.
final init = await jellyfin.quickConnect.initiate();
print('Open Jellyfin elsewhere → Settings → Quick Connect → enter ${init.code}');

// 2. Poll until the user authorises.
while (true) {
  await Future<void>.delayed(const Duration(seconds: 2));
  final state = await jellyfin.quickConnect.state(init.secret);
  if (state.authenticated) break;
}

// 3. Exchange the secret for a real token.
final auth = await jellyfin.user.authenticateWithQuickConnect(secret: init.secret);
jellyfin.setSession(token: auth.accessToken, userId: auth.user.id);
```

To approve a code from an already-authenticated device (the
"authorise other device" side):

```dart
await jellyfin.quickConnect.authorize('ABC123');
```

#### 2.3 Current user

```dart
final me = await jellyfin.user.currentUser();
print('${me.name} (${me.id})');
```

#### 2.4 Public users

```dart
final users = await jellyfin.user.publicUsers();
for (final u in users) {
  print('${u.name} (primaryImageTag=${u.primaryImageTag})');
}
```

No authentication required. Use this to render the server's
"who's logging in?" picker.

---

### 3. System info

#### 3.1 Public system info (no auth)

```dart
final info = await jellyfin.system.publicInfo();
// info.serverName, info.version, info.id, info.productName
```

Useful for reachability checks and to confirm the URL really points
at a Jellyfin server before asking the user for credentials.

#### 3.2 Authenticated info

```dart
final info = await jellyfin.system.info();
```

Same shape, but includes operating-system details and other
admin-only fields when the token belongs to an admin user.

#### 3.3 Ping

```dart
if (await jellyfin.system.ping()) { /* server reachable */ }
```

Swallows all transport errors. Hits `/System/Info/Public` under the
hood.

#### 3.4 Server and housekeeping

```dart
final counts = await jellyfin.library.counts();
print('${counts.albumCount} albums, ${counts.songCount} tracks');

final endpoint = await jellyfin.system.endpointInfo(); // isLocal, isInNetwork
final clock = await jellyfin.system.utcTime(); // for clock-skew correction

// Admin token:
final tasks = await jellyfin.scheduledTasks.list();
final devices = await jellyfin.devices.list();
final log = await jellyfin.activityLog.entries(limit: 50);
```

These answer typed models: `JellyfinItemCounts`, `JellyfinEndpointInfo`,
`JellyfinUtcTime`, `JellyfinScheduledTask`, `JellyfinDevice` and a
`JellyfinQueryResult<JellyfinActivityLogEntry>`. Like every model, each
keeps the decoded body in `raw`. The "Audio Normalization" scheduled
task is the one that fills `JellyfinItem.normalizationGain`. Admin-only
setup endpoints (Live TV tuners, plugins, packages, localization) still
answer maps.

---

### 4. Library browsing

#### 4.1 User views

```dart
final views = await jellyfin.library.userViews();
for (final v in views) {
  print('${v.collectionType ?? '?'} → ${v.name}');
}
```

`collectionType` is one of `music`, `movies`, `tvshows`,
`musicvideos`, `photos`, `books`, `livetv`, `homevideos`, `boxsets`,
`playlists`, `folders`. Convenience getters: `view.isMusic`,
`view.isMovies`, `view.isTvShows`, `view.isPhotos`.

#### 4.2 Listing items

`/Items` is Jellyfin's workhorse and accepts ~85 query parameters.
Pass them through `items.list()`:

```dart
final page = await jellyfin.items.list(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  sortBy: const ['SortName', 'ProductionYear'],
  descending: true,
  startIndex: 50, // second page
  limit: 50,
  searchTerm: 'pink',          // optional substring filter
  filters: const ['IsFavorite'], // optional ItemFilters
  artistIds: [artistId],
  genreIds: [genreId],
  fields: JellyfinItemsApi.browseFields, // light set for a grid
);
print('${page.items.length} of ${page.totalRecordCount}');
```

The result is `JellyfinQueryResult<JellyfinItem>` carrying `items`,
`totalRecordCount` and `startIndex`.

**Id and name filters.** Every filter that takes more than one value is
a `List<String>` — `ids`, `excludeItemIds`, `genreIds`, `artistIds`,
`albumArtistIds`, `contributingArtistIds`, `albumIds`, `studioIds`,
`personIds`, `tags`, `officialRatings`, and the name-based
`genres`, `artists`, `albums`, `studios` (plus `years`, a `List<int>`).
Pass the list; never join it yourself. Each element is sent as its own
query parameter, which is the one encoding every Jellyfin endpoint reads
correctly and the only one that survives a genre or tag containing a
comma or a pipe.

Prefer the id form over the name form where you have a choice: ids come
back from `filter.facets()` and survive a rename.

**Fields.** `fields` defaults to empty — the server's own projection.
Two presets are ready-made; see [4.7](#47-field-presets).

**Artists are not scoped by `parentId`.** With
`includeItemTypes: [JellyfinItemKind.musicArtist]`, `/Items` ignores
`parentId` and answers the artists of every library (verified with two
music libraries). List one library's artists with
`artists.albumArtists(parentId: …)` or `artists.list(parentId: …)`,
which do honour it. Albums and tracks are scoped as expected.

**Totals cost a second query.** `enableTotalRecordCount` (default
`true`) makes the server count the whole result set for
`totalRecordCount`. Pass `false` when you page until a short page and
never show a total; `totalRecordCount` then reports only the items in
the page.

#### 4.3 Counting items

`count()` takes the same narrowing parameters as `list()` — minus
paging, sorting and field selection — so any query you can page you can
also count:

```dart
final count = await jellyfin.items.count(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  genreIds: [genreId],
  searchTerm: 'pink',
);
```

Issues a request with `Limit=0&EnableTotalRecordCount=true` so the
server answers with just the total, without transferring the items.

#### 4.4 Single item

```dart
final item = await jellyfin.items.byId('12345');
if (item != null) {
  print(item.name);
  print(item.mediaSources.first.bitrate);
}
```

Returns `null` on 404.

#### 4.5 Resume and latest

```dart
final resume = await jellyfin.items.resume(
  mediaTypes: const ['Audio'],
  limit: 10,
);
final latest = await jellyfin.items.latest(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  limit: 10,
);
```

`resume()` returns `JellyfinQueryResult<JellyfinItem>` ("Continue
Listening or Watching"). `latest()` returns `List<JellyfinItem>`; the
endpoint does not wrap them in a query result.

#### 4.6 BaseItemKind reference

Use `JellyfinItemKind` constants as `includeItemTypes` values:

| Constant | String | Notes |
| :--- | :--- | :--- |
| `audio`        | `Audio`        | music tracks |
| `audioBook`    | `AudioBook`    | |
| `musicAlbum`   | `MusicAlbum`   | |
| `musicArtist`  | `MusicArtist`  | |
| `musicGenre`   | `MusicGenre`   | |
| `musicVideo`   | `MusicVideo`   | |
| `playlist`     | `Playlist`     | works for any mediaType |
| `movie`        | `Movie`        | |
| `series`       | `Series`       | TV |
| `season`       | `Season`       | TV |
| `episode`      | `Episode`      | TV |
| `photo`        | `Photo`        | |
| `photoAlbum`   | `PhotoAlbum`   | |
| `folder`       | `Folder`       | |
| `collectionFolder` | `CollectionFolder` | library roots |
| `userView`     | `UserView`     | |
| `genre`        | `Genre`        | |
| `person`       | `Person`       | |
| `studio`       | `Studio`       | |
| `book`         | `Book`         | |

#### 4.7 Field presets

| Preset | Fields | Use for |
| :--- | :--- | :--- |
| `JellyfinItemsApi.browseFields` | `Genres, DateCreated, ChildCount, SortName, PrimaryImageAspectRatio` | grids and lists of albums, artists, playlists, genres |
| `JellyfinItemsApi.musicFields` | `Overview, Genres, MediaSources, MediaStreams, ProviderIds, PrimaryImageAspectRatio, SortName, DateCreated, ChildCount, ParentId, Path, OriginalTitle` | a queue or a track info sheet, where media sources and streams are read |

`musicFields` is the expensive one: measured on Jellyfin 12.0, a track
costs ~3.2 KB with it against ~1.2 KB with `browseFields`, and a
500-track album page was 1.5 MB of JSON that took the server ~230 ms to
build. `MediaSources` and `MediaStreams` are most of both. Neither preset
is a default, because `/Items` also serves video and photo libraries.

Image tags (`ImageTags`, `AlbumPrimaryImageTag`) are not fields: the
server always sends them, so covers work with either preset. 0.2 listed
`AlbumPrimaryImageTag` in `musicFields`; the server ignored it.

With `Genres` requested, `JellyfinItem.genreItems` carries each genre's
id and name (`JellyfinNameGuidPair`), the ids `items.list(genreIds:)` and
`instantMix.fromItem()` take. Other typed fields worth knowing:
`albumArtistItems` (album artists with ids), `people` (with the
`People` field: `JellyfinItemPerson`s — name, id, role, a `type` such as
`'Composer'` or `'AlbumArtist'`, image tag), `recursiveItemCount` (with
`RecursiveItemCount`), `albumCount`, `songCount` and the other counts
(with `ItemCounts`: the server sends them flat on the item, no
`ItemCounts` object), `normalizationGain` and
`albumNormalizationGain` (dB, filled by the server's "Audio
Normalization" task; Jellyfin exposes no LUFS value), and
`artworkItemId` / `artworkVersion`, the id whose cover to show and the
image tag to put in a cache key:

```dart
final coverId = track.artworkItemId;
if (coverId != null) {
  final url = jellyfin.images.url(
    itemId: coverId,
    tag: track.artworkVersion, // changes when the cover does
    maxWidth: 512,
    maxHeight: 512,
  );
}
```

#### 4.8 Paging

`JellyfinPaging.pages()` and `JellyfinPaging.items()` walk any paged
endpoint as a stream, one request per page, nothing fetched ahead:

```dart
final tracks = JellyfinPaging.items(
  (start, size) async => (await jellyfin.items.list(
    parentId: music.id,
    includeItemTypes: const [JellyfinItemKind.audio],
    sortBy: const ['SortName'],
    startIndex: start,
    limit: size,
    enableTotalRecordCount: false,
  ))
      .items,
  pageSize: 200,
);
await for (final track in tracks) {
  print(track.name);
}
```

Paging stops at the first page shorter than `pageSize`, or after
`limit` rows when you pass one. Cancelling the subscription stops it
before the next request; pair it with a cancel token
([1.7](#17-cancellation)) to drop the request in flight too.

---

### 5. Playlists

#### 5.1 Creating a playlist

```dart
final playlist = await jellyfin.playlists.create(
  name: 'My Mix',
  mediaType: 'Audio',  // 'Audio' | 'Video' | 'Photo' | 'Book'
  itemIds: const ['12345', '12346'],
  isPublic: true, // private by default
);
```

#### 5.2 Listing items

```dart
final page = await jellyfin.playlists.items(
  playlistId: playlist.id,
  limit: 100,
);
```

`fields` defaults to empty (the server's own projection). Playlists hold
video as readily as audio, so pass `JellyfinItemsApi.musicFields`
explicitly when you want the music field set.

#### 5.3 Adding and removing

```dart
await jellyfin.playlists.addItems(
  playlistId: playlist.id,
  itemIds: const ['99999', '99998'],
);

// To remove, pass the entries' playlistItemId.
final items = await jellyfin.playlists.items(playlistId: playlist.id);
final entryIds = items.items
    .map((i) => i.playlistItemId)
    .whereType<String>()
    .toList();
await jellyfin.playlists.removeItems(
  playlistId: playlist.id,
  entryIds: entryIds.take(2).toList(),
);
```

`removeItems` and `moveItem` take `JellyfinItem.playlistItemId`, present
on items read from `playlists.items()`. On Jellyfin 12.2 it equals the
item id (verified): with a track listed twice, removing its entry
removes **every** copy and moving it moves the first. The server offers
no way to address one copy of a duplicate. After `moveItem`, a read
right away can still show the old order for a moment.

#### 5.4 Renaming and deleting

```dart
await jellyfin.playlists.rename(playlistId: '123', name: 'New name');
await jellyfin.playlists.delete('123');
```

Jellyfin 12.2 loses a rename sent within about half a second of a write
that changed the entries (`create` with `itemIds`, `addItems`) and still
answers success: the server saves the entry change over the new name.
Name the playlist in `create()`, or leave a gap.

`playlists.users()` lists who can access a shared playlist as
`JellyfinPlaylistUserPermission` (`userId`, `canEdit`).

---

### 6. Search

#### 6.1 Search hints

```dart
final hints = await jellyfin.search.hints(
  query: 'pink floyd',
  includeItemTypes: const [
    JellyfinItemKind.musicAlbum,
    JellyfinItemKind.musicArtist,
    JellyfinItemKind.audio,
  ],
  limit: 30,
);
for (final h in hints.items) {
  print('${h.type}: ${h.name}');
}
```

Returns `JellyfinQueryResult<JellyfinSearchHint>`, a flat list with
`itemId`, `name`, `matchedTerm`, `type`, `mediaType`, runtime hints,
plus a `primaryImageTag` you can pass straight to `images.url(...)`.

---

### 7. Audio streaming

These methods primarily **build URLs**. They don't fetch the audio
stream themselves; hand the URL to your audio engine (mpv, AVPlayer,
ExoPlayer, …). The token is appended as `ApiKey=…` so segment
requests work without custom headers.

#### 7.1 Universal stream URL

The recommended endpoint: the server decides direct-play vs
transcoding from the supplied parameters.

```dart
final url = jellyfin.audio.universalStreamUrl(
  itemId: track.id,
  containers: const ['mp3', 'aac', 'flac', 'ogg', 'opus'],
  maxStreamingBitrate: 320000,
  audioCodec: 'aac',
  transcodingProtocol: 'hls',    // 'hls' | 'http'
  transcodingContainer: 'ts',
  playSessionId: 'my-uuid',
);
```

Common pinning knobs: `audioBitRate`, `audioChannels`,
`maxAudioChannels`, `maxAudioSampleRate`, `maxAudioBitDepth`,
`startTimeTicks`.

#### 7.2 Direct stream URL

Bypass transcoding entirely (best quality, smallest server CPU):

```dart
final (url, ext) = jellyfin.audio.directStreamUrl(
  itemId: track.id,
  container: 'flac',
);
```

`isStatic` defaults to `true` (serve the file as stored); `ext` echoes
`container` for naming a file.

#### 7.3 Lyrics

```dart
final lyrics = await jellyfin.audio.lyrics(track.id);
if (lyrics == null) { /* no lyrics on server */ }
else if (lyrics.hasCues) {
  print(lyrics.toLrc(enhanced: true)); // ELRC: per-word <mm:ss.cc> times
} else if (lyrics.isSynced) {
  print(lyrics.toLrc()); // mm:ss.cc LRC document
} else {
  print(lyrics.toPlainText()); // line per entry, no timestamps
}
```

`JellyfinLyrics` exposes the parsed lines (`startTicks` in
100-nanosecond units and `start` as a `Duration`, `text`, and `cues`:
word-level `JellyfinLyricCue`s with their own start and end), the lyric
file's tags as `metadata` (`JellyfinLyricMetadata`: artist, album,
title, offset, …) and the renderers. `toLrc(enhanced: true)` writes
lines that have cues in the enhanced LRC syntax and the others as plain
LRC.

`lyrics()` returns `null` on a 404, which Jellyfin answers both for a
track without lyrics and for an id that names no item. `metadata` is
often empty: 12.2 answered `Metadata: {}` for an LRC with `[ar:]` and
`[ti:]` tags.

No route serves the original `.lrc` or `.txt` file: `GET
/Audio/{id}/Lyrics` answers the parsed lyric as JSON whatever the
`Accept` header. `audio.lyricsRaw()`, which returned that JSON as text,
is deprecated; rebuild a file with `toLrc()` or `toPlainText()`.

---

### 8. Video streaming

Mirrors the `Videos` OpenAPI tag. URL builders only, like
[`audio`](#7-audio-streaming) they don't fetch the stream themselves.
Hand the URL to your video engine (mpv, AVPlayer, ExoPlayer, …). The
token is appended as `ApiKey=…` so HLS segment requests work without
custom headers.

For proper direct-play vs transcoding negotiation, run
[`mediaInfo.postedInfo()`](#122-posting-a-device-profile) first; its
response carries a `transcodingUrl` you can use verbatim.

#### 8.1 Stream URL

```dart
final (url, ext) = jellyfin.videos.streamUrl(
  itemId: movie.id,
  mediaSourceId: movie.mediaSources.first.id,
  videoCodec: 'h264',
  audioCodec: 'aac',
  videoBitRate: 8000000,
  audioBitRate: 192000,
  audioStreamIndex: 1,
  subtitleStreamIndex: 3,
  maxAudioChannels: 2,
  maxWidth: 1920,
  maxHeight: 1080,
  playSessionId: 'my-uuid',
);
```

No video route reads `maxStreamingBitrate`: it is deprecated on
`videos.streamUrl()` and the video HLS builders and no longer sent. Cap a
video transcode with `videoBitRate` and `audioBitRate`.

Pass `isStatic: true` to force the original-file passthrough (no
muxing, no transcoding). Set `params` to replay a server-decided
transcode whose query string came from
`PlaybackInfo.mediaSources[0].transcodingUrl`.

#### 8.2 Additional parts

Movies split across multiple files (CD1, CD2, parts and halves):

```dart
final parts = await jellyfin.videos.additionalParts(movieId);
for (final p in parts) {
  print('${p['Name']} (${p['Id']})');
}
```

Returns the raw `List<Map<String, Object?>>`; a typed DTO can be
promoted later if usage grows.

#### 8.3 Recommended pre-flight

```dart
final info = await jellyfin.mediaInfo.postedInfo(
  itemId: movie.id,
  deviceProfile: myDeviceProfile,
  maxStreamingBitrate: 8000000,
);

final source = info.mediaSources.first;
if (source.supportsDirectPlay) {
  final (url, _) = jellyfin.videos.streamUrl(itemId: movie.id, isStatic: true);
  play(url);
} else if (source.transcodingUrl != null) {
  // Server already built the right transcoding URL, use it verbatim.
  play('${jellyfin.baseUrl}${source.transcodingUrl}');
}
```

See section [12. Media info and playback negotiation](#12-media-info-and-playback-negotiation)
for the full flow.

---

### 9. HLS playlists

Wraps the `DynamicHls` and `HlsSegment` tags. Both audio and video
have a `master.m3u8` (adaptive bandwidth) and `main.m3u8`
(single-variant). Use the master when you want the player to do its
own ABR, the variant when you've already pinned a quality.

#### 9.1 Audio master and variant

```dart
final masterUrl = jellyfin.hls.audioMasterUrl(
  itemId: track.id,
  maxStreamingBitrate: 320000,
  audioCodec: 'aac',
  playSessionId: 'my-uuid',
);
final mainUrl = jellyfin.hls.audioVariantUrl(
  itemId: track.id,
  audioCodec: 'aac',
  audioBitRate: 256000,
  segmentContainer: 'mp4', // 'ts' | 'mp4'; the route reads no `container`
  segmentLength: 6, // seconds
  minSegments: 1, // segments made before the server answers
  enableAutoStreamCopy: false, // with allowAudioStreamCopy: false,
  allowAudioStreamCopy: false, // force a real transcode
  playSessionId: 'my-uuid',
);
```

Also typed: `audioSampleRate`, `maxAudioBitDepth`, `audioChannels`,
`maxAudioChannels`, `startTimeTicks`, `breakOnNonKeyFrames`, `context`
(`Streaming` or `Static`); `params` adds any other query parameter verbatim.

The playlist builders send the token as `ApiKey` and, as `DeviceId`, the id the
auth header carries (`JellyfinCredentials.deviceId`), never a constant:
Jellyfin files the transcoding job under that device, and the playback
reports and `playback.ping()` find the job through it and
`playSessionId` (see [14.4](#144-ping)).

#### 9.2 Video master and variant

```dart
final masterUrl = jellyfin.hls.videoMasterUrl(
  itemId: movie.id,
  videoCodec: 'h264',
  audioCodec: 'aac',
  videoBitRate: 8000000,
  audioBitRate: 192000,
  maxWidth: 1920,
  maxHeight: 1080,
  subtitleStreamIndex: 3,
  subtitleMethod: 'Hls',
);
```

#### 9.3 Segments and live

Manual segment URLs are rarely needed (the player walks the playlist),
but they're exposed for cache-warming or debugging:

```dart
final segUrl = jellyfin.hls.videoSegmentUrl(
  itemId: movie.id,
  playlistId: 'main',
  segmentId: 0,
  container: 'ts',
);
```

For live TV channels the server keeps the playlist growing in
real-time. Use the live variant:

```dart
final liveUrl = jellyfin.hls.videoLiveUrl(
  itemId: channelId,
  videoCodec: 'h264',
  audioCodec: 'aac',
);
```

---

### 10. Subtitles

Subtitles live alongside a video's `mediaSources[*].mediaStreams`
(entries where `type == 'Subtitle'`). The `index` you pass below is
the stream's `index` field, the same value you'd use as
`subtitleStreamIndex` in [`videos.streamUrl()`](#81-stream-url).

#### 10.1 Subtitle stream URL

```dart
final url = jellyfin.subtitles.streamUrl(
  itemId: movie.id,
  mediaSourceId: movie.mediaSources.first.id,
  index: 3,
  format: JellyfinSubtitlesApi.formatVtt,
);
```

For seeking mid-playback through transcoded subs, pass a tick offset:

```dart
final url = jellyfin.subtitles.streamWithTicksUrl(
  itemId: movie.id,
  mediaSourceId: msid,
  index: 3,
  startPositionTicks: 6000000000, // 10 minutes
  endPositionTicks: 6600000000, // 11 minutes
);
```

`format` defaults to `vtt`. The `segmentLength` parameter is deprecated
here (it belongs to the subtitle playlist route, below) and no longer
sent; bound the slice with `endPositionTicks`.

For HLS-delivered subtitles (when `subtitleMethod: 'Hls'` was set on
the video URL):

```dart
final playlistUrl = jellyfin.subtitles.playlistUrl(
  itemId: movie.id,
  mediaSourceId: msid,
  index: 3,
  segmentLength: 10,
);
```

#### 10.2 Fetching subtitle text

For sidecar rendering (LRC-style overlays, custom positioning), pull
the body as a string:

```dart
final body = await jellyfin.subtitles.fetch(
  itemId: movie.id,
  mediaSourceId: msid,
  index: 3,
  format: JellyfinSubtitlesApi.formatSrt,
);
if (body == null) {
  // 404 → subtitle stream removed server-side.
}
```

#### 10.3 Supported formats

| Constant | Wire | Notes |
| :--- | :--- | :--- |
| `formatSrt` | `srt` | recommended for sidecar; widely supported |
| `formatVtt` | `vtt` | HTML5 `<track>` |
| `formatAss` | `ass` | libass for advanced styling |
| `formatSsa` | `ssa` | legacy SubStation Alpha |
| `formatSub` | `sub` | DVD-style bitmap (rare) |

#### 10.4 Upload and delete

```dart
// `data` is base64-encoded subtitle file content.
await jellyfin.subtitles.upload(
  itemId: movie.id,
  language: 'eng',
  format: 'srt',
  data: base64Subtitle,
  isForced: true, // isHearingImpaired is the other flag
);

await jellyfin.subtitles.delete(itemId: movie.id, index: 3);
```

Both calls require an admin token.

#### 10.5 Remote search and download

When the server has a subtitle provider plugin installed
(OpenSubtitles, Addic7ed, …), search and pull missing subtitles
without leaving the client:

```dart
final hits = await jellyfin.subtitles.searchRemote(
  itemId: movie.id,
  language: 'eng',
);
for (final h in hits) {
  print('${h['ProviderName']} - ${h['Name']} '
        '(${h['DownloadCount']} downloads, ${h['Format']})');
}

await jellyfin.subtitles.downloadRemote(
  itemId: movie.id,
  subtitleId: hits.first['Id'] as String,
);
```

#### 10.6 Fallback fonts

For libass-rendered `.ass` and `.ssa` subtitles, the server hosts a
set of fallback fonts the client can fetch on demand:

```dart
final fonts = await jellyfin.subtitles.fallbackFonts();
final fontUrl = jellyfin.subtitles.fallbackFontUrl(
  name: fonts.first['Name'] as String,
);
```

---

### 11. Trickplay

Scrubbing thumbnails. Each video item carries one or more trickplay
resolutions (`320×`, `160×`, …) discoverable on
`JellyfinItem.raw['Trickplay']`. Pick a width the server has
pre-generated, then index the tile by playhead position.

#### 11.1 Tile URL

```dart
// Tile index is computed from playhead position and the resolution's
// `Interval` (also in raw['Trickplay']).
final url = jellyfin.trickplay.tileUrl(
  itemId: movie.id,
  width: 320,
  index: tileIndex,
);
```

#### 11.2 HLS tile playlist

If your player wants to lazy-load tiles via HTTP range from a
playlist instead of building each URL itself:

```dart
final playlistUrl = jellyfin.trickplay.hlsPlaylistUrl(
  itemId: movie.id,
  mediaSourceId: msid,
  width: 320,
);
```

---

### 12. Media info and playback negotiation

`/Items/{itemId}/PlaybackInfo` is the heart of any non-trivial video
client. The server inspects a `DeviceProfile` describing what the
client can decode and answers with a `JellyfinPlaybackInfo` whose
`mediaSources` already carries `supportsDirectPlay`,
`supportsDirectStream`, `supportsTranscoding` and a `transcodingUrl`
to use verbatim.

#### 12.1 Quick playback info

`GET /Items/{itemId}/PlaybackInfo`, the lightweight version. No device
profile, so the server falls back to generic defaults. Fine for
audio, often wrong for video.

```dart
final info = await jellyfin.mediaInfo.info(
  itemId: track.id,
);
```

#### 12.2 Posting a device profile

`POST /Items/{itemId}/PlaybackInfo`, the right call for video.

```dart
const profile = JellyfinDeviceProfile(
  name: 'MyApp',
  maxStreamingBitrate: 8000000,
  musicStreamingTranscodingBitrate: 320000,
  directPlayProfiles: [
    JellyfinDirectPlayProfile.audio(container: 'mp3,aac,flac'),
    JellyfinDirectPlayProfile.video(container: 'mp4,mkv,webm'),
  ],
  // Each profile carries an explicit media-kind `Type` (`'Audio'`,
  // `'Video'`, …), so audio sources match an `Audio` profile and
  // direct-play correctly instead of being forced down the video path.
  // For finer-grained codec and container constraints, pass them in
  // transcodingProfiles, codecProfiles and containerProfiles. The
  // `extra` map is merged verbatim into the JSON body for any other
  // top-level field the spec exposes.
);

final info = await jellyfin.mediaInfo.postedInfo(
  itemId: movie.id,
  deviceProfile: profile,
  maxStreamingBitrate: 8000000,
  subtitleStreamIndex: 3,
);
final src = info.mediaSources.first;
print('directPlay=${src.supportsDirectPlay} transcoding=${src.transcodingUrl}');
```

#### 12.3 Live streams

Sources whose `mediaSources[0].requiresOpening == true` (live TV,
on-the-fly transcodes) need an explicit open and close:

```dart
final opened = await jellyfin.mediaInfo.openLiveStream(
  openToken: src.raw['OpenToken'] as String,
  itemId: movie.id,
  deviceProfile: profile,
);
final liveStreamId = opened.mediaSources.first.raw['LiveStreamId'] as String;
// … play …
await jellyfin.mediaInfo.closeLiveStream(liveStreamId: liveStreamId);
```

#### 12.4 Bitrate probe

The server streams `[size]` zero-bytes; use the elapsed time to pick
a starting `maxStreamingBitrate`:

```dart
final stopwatch = Stopwatch()..start();
final size = await jellyfin.mediaInfo.bitrateTestBytesLength(size: 1000000);
stopwatch.stop();
final bps = (size ?? 0) * 8 * 1000 ~/ stopwatch.elapsedMilliseconds;
```

---

### 13. Images

Jellyfin's image URLs are deterministic: `/Items/{id}/Images/{type}`
with a `tag` query parameter (the hash from
`JellyfinItem.imageTags[type]`) for cache busting. The server resizes,
so no client-side scaling is needed. Without `format` it answers in the
source's own format (a PNG upload comes back as PNG).

#### 13.1 Building an image URL

```dart
final url = jellyfin.images.url(
  itemId: track.artworkItemId ?? track.id,
  tag: track.artworkVersion, // cache-bust hash
  maxWidth: 512,
  maxHeight: 512,
  format: JellyfinImagesApi.formatJpg,
  quality: 85,
);
```

`type` defaults to `JellyfinImagesApi.typePrimary`. Sizing, as Jellyfin
12.0 was measured to apply it to a 1200×800 source:

| Parameters | Effect | 512 / 512 gives |
| :--- | :--- | :--- |
| `maxWidth` / `maxHeight` | fit *inside* the box, aspect kept (the pair for a cover cache) | 512×341 |
| `fillWidth` / `fillHeight` | *cover* the box, aspect kept | 768×512 |
| `width` / `height` | exactly those dimensions, stretched | 512×512 |

`format` re-encodes (`formatJpg`, `formatPng`, `formatWebp`, `formatGif`,
`formatBmp`, `formatSvg`), and `format=Jpg` together with `maxWidth` is
honoured. `quality` (0–100) applies to the lossy formats:
`maxWidth=512&format=Jpg&quality=85` measured 9.8 KB against 22 KB at the
server's default. `url()` also takes `percentPlayed` and
`unplayedCount` (baked-in progress bar and badge), `blur` (radius) and
`backgroundColor` (fills transparency, e.g. `'000000'`). The entity
builders (`artistImageUrl`, `genreImageUrl`, `studioImageUrl`,
`personImageUrl`, …) take `maxWidth` / `maxHeight` too, and
`images.listItemImages(itemId)` lists an item's images as
`JellyfinImageInfo` (type, index, tag, size, dimensions).

#### 13.2 Fetching bytes

```dart
final Uint8List? bytes = await jellyfin.images.fetch(
  itemId: track.artworkItemId ?? track.id,
  tag: track.artworkVersion,
  maxWidth: 512,
  maxHeight: 512,
  format: JellyfinImagesApi.formatJpg,
  cancelToken: token, // optional: drop it when the cell scrolls away
);
```

`fetch()` takes the sizing and encoding parameters of `url()` (not
`percentPlayed`, `unplayedCount`, `blur` or `backgroundColor`) plus a
`cancelToken`. Returns `null` on 404. Throws `JellyfinException` on transient failures
(5xx, network down) so the caller can distinguish "no image ever"
from "try again later".

#### 13.3 Image types

| Constant | Wire value | |
| :--- | :--- | :--- |
| `typePrimary`  | `Primary`  | Album cover, movie poster, track art |
| `typeArt`      | `Art`      | Fan art (clear logo placement) |
| `typeBackdrop` | `Backdrop` | Hero or cinematic backdrop |
| `typeBanner`   | `Banner`   | Wide banner |
| `typeLogo`     | `Logo`     | Title logo |
| `typeThumb`    | `Thumb`    | Wide thumbnail |
| `typeDisc`     | `Disc`     | Disc art |

---

### 14. Playback reporting

Jellyfin uses 100-nanosecond "ticks". 1 ms = 10 000 ticks, 1 s =
10 000 000 ticks. The API accepts `Duration` directly and converts
internally.

#### 14.1 Start

```dart
await jellyfin.playback.start(
  itemId: track.id,
  playSessionId: 'my-uuid',
  mediaSourceId: track.mediaSources.first.id,
  method: JellyfinPlayMethod.transcode, // directPlay (default) | directStream
);
```

#### 14.2 Progress

Send every ~10 s and on every state change.

```dart
await jellyfin.playback.progress(
  itemId: track.id,
  position: const Duration(seconds: 42),
  isPaused: false,
  volumeLevel: 80,
  playSessionId: 'my-uuid',
  method: JellyfinPlayMethod.transcode,
  order: JellyfinPlaybackOrder.shuffle, // or defaultOrder
  repeat: JellyfinRepeatMode.all, // none | all | one
);
```

`method`, `order` and `repeat` are enums. The 0.2 `String` parameters
(`playMethod`, `playbackOrder`, `repeatMode`) still work but are
deprecated; passing one together with its enum throws an
`ArgumentError`.

#### 14.3 Stopped

```dart
await jellyfin.playback.stopped(
  itemId: track.id,
  position: const Duration(seconds: 240),
  playSessionId: 'my-uuid',
);
```

#### 14.4 Ping

Tells the server the transcode of a play session is still wanted.

```dart
await jellyfin.playback.ping(playSessionId: 'my-uuid');
```

Measured on Jellyfin 12.0 with an HLS audio transcode: the job is filed
under the stream URL's `DeviceId` (the auth header's, in every builder
here), so ping, `progress` and `stopped` reach it. A paused session that
sent one `progress` with `isPaused: true` kept its job for the 130 s
observed without pings, and `stopped` ends it. A player that sends
`progress` every ~10 s needs no ping; ping covers stretches with nothing
to report, such as buffering before the first `start`.

---

### 15. Sessions and remote control

`GET /Sessions` plus the `/Sessions/{id}/...` command family. Use
this to list every other client connected to the same Jellyfin
server, register this client as a cast target, and push playback
commands to remote sessions.

#### 15.1 Listing sessions

```dart
final sessions = await jellyfin.sessions.list();
for (final s in sessions) {
  print('${s.userName} on ${s.deviceName} (${s.client})'
        ' nowPlaying=${s.nowPlayingItem?.name}');
}

// Scope to sessions the current user is allowed to control:
final controllable = await jellyfin.sessions.list(
  controllableByUserId: jellyfin.userId,
  activeWithinSeconds: 30,
);
```

#### 15.2 Registering this client as a cast target

Once capabilities are posted, other Jellyfin clients will list this
device as a cast target.

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

`supportedCommands` takes `GeneralCommandType` values. Pause, stop,
seek and track skips are not among them: they arrive as playstate
commands ([15.4](#154-playstate-commands)), which the `PlayState`
capability advertises.

When the user logs out, call `jellyfin.sessions.reportSessionEnded()`
so the server clears any pending now-playing entries.

#### 15.3 Playing on a remote session

```dart
final target = sessions.firstWhere((s) => s.supportsMediaControl);
await jellyfin.sessions.play(
  sessionId: target.id,
  itemIds: const ['12345', '12346'],
  playCommand: JellyfinPlayCommand.playShuffle,
);
```

`playCommand` defaults to `JellyfinPlayCommand.playNow` (replace the
queue); the other constants are `playNext`, `playLast`,
`playInstantMix` and `playShuffle`.

#### 15.4 Playstate commands

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

Constants on `JellyfinPlaystateCommand`: `stop`, `pause`, `unpause`,
`playPause`, `nextTrack`, `previousTrack`, `seek`, `rewind`,
`fastForward`.

#### 15.5 General and system commands

```dart
// Single-token commands (volume, mute, fullscreen):
await jellyfin.sessions.sendCommand(
  sessionId: target.id,
  command: JellyfinGeneralCommand.volumeUp,
);

// Commands with arguments (set a specific volume, switch audio track):
await jellyfin.sessions.sendFullCommand(
  sessionId: target.id,
  name: JellyfinGeneralCommand.setVolume,
  arguments: {'Volume': '80'},
);

// Navigation-level (GoHome, GoToSettings, GoToSearch, …):
await jellyfin.sessions.sendSystemCommand(
  sessionId: target.id,
  command: 'GoHome',
);
```

#### 15.6 Messages and DisplayContent

```dart
// Toast on the remote device:
await jellyfin.sessions.sendMessage(
  sessionId: target.id,
  text: 'Now playing on the kitchen TV.',
  header: 'Cast',
  timeoutMs: 4000,
);

// Open the detail page of an item without playing it:
await jellyfin.sessions.displayContent(
  sessionId: target.id,
  itemId: album.id,
  itemType: 'MusicAlbum',
  itemName: album.name,
);
```

---

### 16. User data

#### 16.1 Favorites

```dart
await jellyfin.userData.markFavorite(track.id);
await jellyfin.userData.unmarkFavorite(track.id);

// Convenience toggle:
await jellyfin.userData.setFavorite(track.id, true);
```

Each call returns a fresh `JellyfinUserData` with the new state.

#### 16.2 Played flag

```dart
await jellyfin.userData.markPlayed(track.id);
await jellyfin.userData.markUnplayed(track.id);
```

#### 16.3 Reading and writing the record

Both calls return the freshest `JellyfinUserData` (`isFavorite`,
`playCount`, `playbackPositionTicks`, `lastPlayedDate`). You can also
fetch and write the whole record:

```dart
final data = await jellyfin.userData.get(itemId);
print('position=${data.playbackPositionTicks} count=${data.playCount}');

// Reset the resume position, keep the rest.
await jellyfin.userData.update(
  itemId: itemId,
  userData: JellyfinUserData(
    playCount: data.playCount,
    isFavorite: data.isFavorite,
    played: data.played,
    playbackPositionTicks: 0,
  ),
);
```

> Jellyfin 10.11 dropped the legacy `/Users/{userId}/FavoriteItems/...`
> and `/Users/{userId}/PlayedItems/...` routes; the wrappers above
> already speak the new flat `/UserFavoriteItems/{itemId}` and
> `/UserPlayedItems/{itemId}`. For pre-10.11 servers, use the escape
> hatch.

---

### 17. Instant Mix

Server-side radio. Jellyfin generates a "Mix" (a list of related
audio items) from any seed (song, album, artist, playlist, music
genre). The mix quality depends on the server's metadata + similar
artist recommendations.

#### 17.1 From any seed item

The seed can be any item the server understands:

```dart
final mix = await jellyfin.instantMix.fromItem(
  itemId: track.id,
  limit: 50,
);
for (final item in mix.items) {
  print('${item.name} - ${item.albumArtist}');
}
```

#### 17.2 From a typed seed

When you know the seed's kind, the typed variants give clearer call
sites:

```dart
final fromSong   = await jellyfin.instantMix.fromSong(songId: track.id);
final fromAlbum  = await jellyfin.instantMix.fromAlbum(albumId: album.id);
final fromArtist = await jellyfin.instantMix.fromArtist(artistId: artist.id);
final fromList   = await jellyfin.instantMix.fromPlaylist(playlistId: playlist.id);
final rock       = await jellyfin.musicGenres.byName('Rock');
final fromGenre  = await jellyfin.instantMix.fromItem(itemId: rock!.id);
```

A genre seeds a mix by its music-genre id: from a track's `genreItems`,
`genres.list(parentId: musicLibraryId)` or `musicGenres.byName()`.
`genres.byName()` and `genres.list()` without `parentId` answer the
generic genre item instead, with another id — `fromItem()` takes it
and answers an empty mix (see [31.4](#314-music-genres)).

Each helper returns a `JellyfinQueryResult<JellyfinItem>`, the same
shape as `items.list()`, so the result drops straight into a UI list.

> Jellyfin 12 marks the music-genre seeds (`fromMusicGenre`,
> `fromMusicGenreById`) and the name-keyed artist seed
> (`fromArtistByName`) obsolete. They still answer but are deprecated
> here; `fromItem()` takes any seed id, genres included.

---

### 18. Live TV

Channels, EPG, recordings and timers. The wrapper covers the
consumer-facing slice (~14 of the 41 upstream operations on the
`LiveTv` tag). Tuner provisioning and listings-provider setup are
admin-only and stay behind the escape hatch.

#### 18.1 Channels

```dart
final channels = await jellyfin.liveTv.channels(
  type: 'TV',           // or 'Radio'
  isFavorite: false,
  sortBy: const ['Default'],
  limit: 50,
);
for (final ch in channels.items) {
  print('${ch.indexNumber} ${ch.name}');
}

final ch = await jellyfin.liveTv.channel(channelId);
// ch.raw['CurrentProgram'] carries the now-airing show.
```

`/LiveTv/Channels` has no search parameter: `searchTerm` is deprecated
here and no longer sent. Filter the answer by name instead.

#### 18.2 Programs and EPG

```dart
final now = DateTime.now().toUtc();
final epg = await jellyfin.liveTv.programs(
  channelIds: const ['ch1', 'ch2', 'ch3'],
  minStartDate: now.toIso8601String(),
  maxStartDate: now.add(const Duration(hours: 6)).toIso8601String(),
  sortBy: const ['StartDate'],
);

// Recommended airings, server-curated.
final recommended = await jellyfin.liveTv.recommendedPrograms(
  isAiring: true,
  isMovie: true,
  limit: 20,
);
```

#### 18.3 Recordings

```dart
final recordings = await jellyfin.liveTv.recordings(
  isInProgress: false,
  limit: 100,
);
for (final rec in recordings.items) {
  print('${rec.name} - ${rec.runTimeTicks} ticks');
}

final detail = await jellyfin.liveTv.recording(recordingId);
await jellyfin.liveTv.deleteRecording(recordingId);
```

#### 18.4 Timers

Both one-shot timers (record this airing) and series timers
(record every airing of a series):

```dart
final scheduled = await jellyfin.liveTv.timers(isActive: true);

await jellyfin.liveTv.createTimer(
  body: {
    'ProgramId': 'pgm-1234',
    'PrePaddingSeconds': 60,
    'PostPaddingSeconds': 300,
  },
);

await jellyfin.liveTv.deleteTimer(timerId);

// Recurring rules:
final series = await jellyfin.liveTv.seriesTimers();
await jellyfin.liveTv.createSeriesTimer(
  body: {
    'ProgramId': 'pgm-1234',
    'RecordAnyTime': false,
    'RecordNewOnly': true,
  },
);
```

---

### 19. SyncPlay

Synchronised playback across multiple clients ("watch party"). One
client creates a group, others join; pause, seek and next-track
actions propagate to every member. Each member calls
[`syncPlay.ready()`](#193-group-queue) when buffered so the server
can resume the group simultaneously.

#### 19.1 Listing and joining groups

```dart
final groups = await jellyfin.syncPlay.list();
for (final g in groups) {
  print('${g.name} (${g.participants.length} participants, ${g.state})');
}

await jellyfin.syncPlay.createGroup(groupName: 'Friday movie night');
await jellyfin.syncPlay.joinGroup(groupId: groups.first.id);
await jellyfin.syncPlay.leaveGroup();
```

`list()` answers `JellyfinSyncPlayGroup`s (`id`, `name`, `state`,
`participants`, `lastUpdatedAt`); `syncPlay.group(id)` fetches one, or
`null`.

#### 19.2 Group playback control

Every command propagates to every member of the group:

```dart
await jellyfin.syncPlay.pause();
await jellyfin.syncPlay.unpause();
await jellyfin.syncPlay.seek(positionTicks: 1200000000); // 2 min
await jellyfin.syncPlay.stop();

await jellyfin.syncPlay.nextItem(playlistItemId: nextEntryId);
await jellyfin.syncPlay.previousItem(playlistItemId: prevEntryId);
await jellyfin.syncPlay.setPlaylistItem(playlistItemId: entryId);

await jellyfin.syncPlay.setRepeatMode(mode: 'RepeatAll');
await jellyfin.syncPlay.setShuffleMode(mode: 'Shuffle');
```

#### 19.3 Group queue

```dart
// Replace the queue.
await jellyfin.syncPlay.setNewQueue(
  playingQueue: const ['12345', '12346', '12347'],
  playingItemPosition: 0,
);

// Append ('Queue', the default) or insert after the current item.
await jellyfin.syncPlay.queue(
  itemIds: const ['12348'],
  mode: 'QueueNext',
);

// Reorder and remove.
await jellyfin.syncPlay.movePlaylistItem(
  playlistItemId: entryId,
  newIndex: 0,
);
await jellyfin.syncPlay.removeFromPlaylist(
  playlistItemIds: const ['entry-1', 'entry-2'],
);

// While buffering or when ready:
await jellyfin.syncPlay.buffering(
  playlistItemId: entryId,
  positionTicks: 0,
  isPlaying: false,
);
await jellyfin.syncPlay.ready(
  playlistItemId: entryId,
  positionTicks: 0,
  isPlaying: false,
);
```

---

### 20. TV Shows

Series-aware browsing endpoints. Use these when listing episodes per
season, seasons per series, building a "Next Up" rail, or surfacing
"coming soon" premieres. Each helper returns a `JellyfinQueryResult<JellyfinItem>`
so the result plugs straight into the same UI lists used by `items.list()`.

#### 20.1 Seasons of a series

```dart
final seasons = await jellyfin.tvShows.seasons(
  seriesId: someSeriesId,
  isSpecialSeason: false,
);
for (final s in seasons.items) {
  print('${s.indexNumber} ${s.name}');
}
```

#### 20.2 Episodes of a season

```dart
final episodes = await jellyfin.tvShows.episodes(
  seriesId: someSeriesId,
  season: 2,
  fields: const ['Overview', 'PrimaryImageAspectRatio'],
  sortBy: 'PremiereDate',
);
```

Use `seasonId` instead of `season` to scope by the season item id
rather than its index number.

`sortBy` here is a single sort column, not a list: this endpoint binds
one `ItemSortBy` value and has no sort-order knob, unlike the
multi-column `sortBy` on `items.list()`.

#### 20.3 Next Up

```dart
final nextUp = await jellyfin.tvShows.nextUp(
  limit: 12,
  enableResumable: true,
  enableRewatching: false,
);
```

`nextUpDateCutoff` restricts results to episodes whose last-watched date is on or after
the cutoff (ISO 8601 string). `disableFirstEpisode` was removed from
`/Shows/NextUp` in Jellyfin 12: it is deprecated here and sent only when
passed, for 10.11 servers.

#### 20.4 Upcoming episodes

```dart
final upcoming = await jellyfin.tvShows.upcoming(
  limit: 20,
);
```

Returns episodes whose premiere date is in the future (typically
fed by the upstream metadata provider).

---

### 21. Movies

Movie-specific browsing. The Jellyfin server precomputes recommendation
"rows" (categories like "Because you watched X", "Top picks") that
group recommended titles by reason.

#### 21.1 Movie recommendations

```dart
final rails = await jellyfin.movies.recommendations(
  parentId: someMovieLibraryId,
  categoryLimit: 6,
  itemLimit: 12,
);
for (final rail in rails) {
  print('${rail.recommendationType} ${rail.baselineItemName}: ${rail.items.length} items');
}
```

Each entry exposes `categoryId`, `recommendationType`
(e.g. `SimilarToRecentlyPlayed`, `HasDirectorFromRecentlyPlayed`),
`baselineItemName`, and the [JellyfinItem] list that belongs to the row.

---

### 22. Suggestions

A single endpoint that returns a server-side curated mix of items for
the current user. Different from `movies.recommendations()` (which is
movie-specific and groups by category): `suggestions.list()` returns
a flat, mixed-kind feed.

#### 22.1 Homepage suggestions

```dart
final picks = await jellyfin.suggestions.list(
  mediaType: const ['Audio'],
  type: const ['MusicAlbum', 'Audio'],
  limit: 30,
);
for (final item in picks.items) {
  print('${item.type}: ${item.name}');
}
```

---

### 23. Media segments

Annotated time ranges on a media item (intro, recap, outro, commercial,
preview). Produced by Jellyfin plugins (Intro Skipper and similar) and
consumed by players to draw a "skip" button at the right moment.

#### 23.1 Listing segments

```dart
final segments = await jellyfin.mediaSegments.forItem(
  itemId: episode.id,
  includeSegmentTypes: const [
    JellyfinMediaSegmentType.intro,
    JellyfinMediaSegmentType.outro,
  ],
);
for (final s in segments.items) {
  print('${s.type}: ${s.start} to ${s.end}');
}
```

#### 23.2 Segment types

`JellyfinMediaSegmentType` enumerates the upstream string values:
`unknown`, `commercial`, `preview`, `recap`, `outro`, `intro`. The
[JellyfinMediaSegment.start] and [JellyfinMediaSegment.end] getters
convert the raw tick fields into `Duration`s for use in player UIs.

---

### 24. Filters

Dynamic facet endpoints. Ask the server which genres, tags, years,
and ratings actually exist inside a library, then feed the user's
selection back into `items.list(genreIds: …)` to drive filter chips.

#### 24.1 Modern facets (with ids)

```dart
final facets = await jellyfin.filter.facets(
  parentId: musicLibraryId,
  includeItemTypes: const ['MusicAlbum'],
);
for (final g in facets.genres) {
  print('${g.id} ${g.name}');
}
```

Pair the returned ids with `items.list(genreIds: ids)` — pass the list
as-is, the wrapper encodes it.

#### 24.2 Legacy facets

```dart
final legacy = await jellyfin.filter.legacy(
  parentId: movieLibraryId,
  includeItemTypes: const ['Movie'],
);
print(legacy.years);            // [1999, 2001, 2024, ...]
print(legacy.officialRatings);  // ['PG-13', 'R', ...]
```

The legacy endpoint returns flat string arrays plus the year and
rating facets the modern endpoint omits.

---

### 25. Artists

Artist-aware endpoints that respect the server's canonical artist
deduplication (an artist appears once even when credited on many
tracks). `items.list()` works for raw item browsing but uses item
records as the unit, so the same artist can appear N times. Use
`artists.list()` or `artists.albumArtists()` for an "Artists" tab.

> Jellyfin 12 merges artists into people and marks the three
> `/Artists` routes obsolete in favour of `persons.list()` (see
> [31.1](#311-persons)). They keep working through the 12.x cycle,
> and `/Persons` has no sort or genre filter yet, so these wrappers
> stay undeprecated for now. Plan on `persons.list(personTypes:
> ['Artist'])` for 13.0.

#### 25.1 Listing artists

```dart
final all = await jellyfin.artists.list(
  parentId: musicLibraryId,
  searchTerm: 'beat',
  limit: 50,
);
```

#### 25.2 Album artists only

```dart
final albumArtists = await jellyfin.artists.albumArtists(
  parentId: musicLibraryId,
  limit: 100,
);
```

Only artists credited on at least one album are returned. This is
the right call for an "Artists" library tab.

#### 25.3 Lookup by name

```dart
final ai = await jellyfin.artists.byName('Aphex Twin');
if (ai != null) {
  print(ai.id);
}
```

Returns null on 404.

---

### 26. Display preferences

Per-client UI state stored on the server: view type, sort order,
scroll direction, sidebar visibility, plus a free-form `customPrefs`
map for arbitrary key and value layout state. Layout choices follow the
user across devices.

The `displayPreferencesId` is the namespace for the document (e.g.
`usersettings`, or a library id for library-scoped state). The
`client` query parameter disambiguates between clients writing into
the same id.

#### 26.1 Reading a document

```dart
final prefs = await jellyfin.displayPreferences.get(
  displayPreferencesId: 'usersettings',
  client: 'my_app',
);
print('${prefs.viewType} sorted by ${prefs.sortBy}');
```

#### 26.2 Writing back

```dart
await jellyfin.displayPreferences.update(
  displayPreferencesId: 'usersettings',
  client: 'my_app',
  preferences: const JellyfinDisplayPreferences(
    id: 'usersettings',
    client: 'my_app',
    viewType: 'Poster',
    sortBy: 'SortName',
    sortOrder: 'Ascending',
    rememberSorting: true,
  ),
);
```

#### 26.3 Custom prefs

`customPrefs` is a `Map<String, String>` for app-specific state the
server itself doesn't interpret:

```dart
await jellyfin.displayPreferences.update(
  displayPreferencesId: 'usersettings',
  client: 'my_app',
  preferences: const JellyfinDisplayPreferences(
    client: 'my_app',
    customPrefs: {
      'home.layout': 'compact',
      'home.rails': 'continueWatching,nextUp,recentlyAdded',
    },
  ),
);
```

---

### 27. Lyrics

The audio sub-API exposes a read-only `lyrics()` getter. This
dedicated sub-API adds the write side: uploading a lyric file,
deleting the attached one, and searching remote lyric providers.

#### 27.1 Reading attached lyrics

```dart
final lyrics = await jellyfin.lyrics.forItem(track.id);
print(lyrics?.toLrc());
```

Mirror of `jellyfin.audio.lyrics(itemId)`. Use whichever entry point
is closer to the call site.

#### 27.2 Uploading a file

```dart
final bytes = await File('track.lrc').readAsBytes();
await jellyfin.lyrics.upload(
  itemId: track.id,
  fileName: 'track.lrc',
  body: bytes,
);
```

The server picks the parser from the file extension.

#### 27.3 Deleting

```dart
await jellyfin.lyrics.delete(track.id);
```

#### 27.4 Remote search and download

```dart
final hits = await jellyfin.lyrics.searchRemote(track.id);
for (final hit in hits) {
  print('${hit.providerName}: ${hit.id} (${hit.lyrics?.lines.length} lines)');
}

final attached = await jellyfin.lyrics.downloadRemote(
  itemId: track.id,
  lyricId: hits.first.id,
);
```

Each hit is a `JellyfinRemoteLyric` (`id`, `providerName`, and the
lyric itself as `JellyfinLyrics` when the provider sent it).

Use `previewRemote(lyricId)` to fetch a remote result without
attaching it.

---

### 28. Channels

Plugin-provided content sources (YouTube, podcasts, online radio).
Not Live TV. Each channel surfaces a tree of items the user can
browse like a regular library.

#### 28.1 Listing channels

```dart
final channels = await jellyfin.channels.list(
  supportsLatestItems: true,
);
```

#### 28.2 Items inside a channel

```dart
final episodes = await jellyfin.channels.items(
  channelId: someChannelId,
  limit: 50,
  sortBy: const ['DateCreated'],
  descending: true,
);
```

Pass `folderId` to drill into a sub-folder.

#### 28.3 Latest across channels

```dart
final latest = await jellyfin.channels.latest(
  channelIds: [channelA, channelB],
  limit: 20,
);
```

#### 28.4 Channel features

```dart
final feats = await jellyfin.channels.features(channelId);
print(feats['SupportsContentDownloading']);

final all = await jellyfin.channels.allFeatures();
```

`allFeatures()` returns the feature map for every channel in one
call (useful for showing capability badges in a UI).

---

### 29. Collections

Curated groupings of items (`BoxSet`-typed). Collections live in
the library like any other item, browsable through
`items.list(includeItemTypes: ['BoxSet'])`.

#### 29.1 Creating a collection

```dart
final result = await jellyfin.collection.create(
  name: 'Best of 2024',
  ids: [albumA, albumB, albumC],
);
final id = result['Id'] as String;
```

#### 29.2 Adding and removing

```dart
await jellyfin.collection.addItems(
  collectionId: id,
  ids: [albumD, albumE],
);

await jellyfin.collection.removeItems(
  collectionId: id,
  ids: [albumA],
);
```

Removed items keep existing as regular library items; only the
collection membership is cleared.

#### 29.3 Collections containing an item

```dart
final includedIn = await jellyfin.library.collections(
  itemId: album.id,
  limit: 20,
);
for (final boxSet in includedIn.items) {
  print(boxSet.name);
}
```

The reverse lookup, added in Jellyfin 12.0: every collection the item
belongs to, with user data attached. Handy for an "Included in" row
on an item page.

---

### 30. User views (alternate)

`library.userViews()` covers the common case. This sub-API exposes
the richer `/UserViews` endpoint with hidden libraries, external
(channel and plugin) content, and the server's grouping recommendations.

#### 30.1 Listing with filters

```dart
final views = await jellyfin.userViews.list(
  includeHidden: true,
  includeExternalContent: false,
  presetViews: const ['music', 'tvshows'],
);
```

#### 30.2 Grouping options

```dart
final options = await jellyfin.userViews.groupingOptions();
```

Returned as a flat list of option maps; each map describes a
recommended way to group the user's views in the UI.

---

### 31. Browse facets

Five small sub-APIs that each wrap an "entity index" endpoint pair:
a paged `list()` to enumerate the entities, plus a `byName()` or
`byYear()` to look one up. Each entity is returned as a
[JellyfinItem], so callers can pipe the result into the same UI
widgets as `items.list()`.

#### 31.1 Persons

```dart
final actors = await jellyfin.persons.list(
  personTypes: const ['Actor'],
  searchTerm: 'cumberbatch',
  limit: 20,
);
final one = await jellyfin.persons.byName('Benedict Cumberbatch');
```

Pass `appearsInItemId` to scope the list to people credited on a
specific item (e.g. cast for one movie). `parentId` scopes it to one
library, `startIndex` pages it, and `nameStartsWith` /
`nameStartsWithOrGreater` / `nameLessThan` drive an alphabet picker.

Since Jellyfin 12 artists are people too, and `/Persons` is the
declared successor of the `/Artists` routes:

```dart
final artists = await jellyfin.persons.list(
  parentId: musicLibraryId,
  personTypes: const ['Artist'],
  nameStartsWith: 'A',
  limit: 50,
);
```

#### 31.2 Studios

```dart
final studios = await jellyfin.studios.list(
  parentId: movieLibraryId,
  nameStartsWith: 'A',
);
final pixar = await jellyfin.studios.byName('Pixar');
```

#### 31.3 Genres

```dart
final genres = await jellyfin.genres.list(
  parentId: movieLibraryId,
  includeItemTypes: const ['Movie'],
);
final action = await jellyfin.genres.byName('Action');
```

Generic across-library variant.

#### 31.4 Music genres

```dart
final musicGenres = await jellyfin.genres.list(parentId: musicLibraryId);
final ambient = await jellyfin.musicGenres.byName('Ambient');
```

Jellyfin keeps two items per genre name: a generic `Genre` and, for
music, a `MusicGenre`, with different ids. `genres.list()` answers the
music genres only when `parentId` is a music library's id; without it,
it answers the generic ones, even with
`includeItemTypes: ['MusicAlbum', 'Audio']`. `genres.byName()` takes no
`parentId` and always answers the generic one. Both ids filter
`items.list(genreIds:)`, but only the music-genre id seeds an instant
mix: `instantMix.fromItem()` with a generic genre id answers an empty
mix (verified on 12.2).

Jellyfin 12 also hides `GET /MusicGenres` from the API document and marks
`GET /MusicGenres/{name}` obsolete; both still answer on 12.2.
`musicGenres.list()` is deprecated in favour of
`genres.list(parentId: musicLibraryId)`, which answers the same genres
with the same ids. `musicGenres.byName()` is not: no other route looks up
a music genre by exact name. `genres.list(parentId: musicLibraryId,
searchTerm: name)` finds it too, among partial matches.

#### 31.5 Years

```dart
final yrs = await jellyfin.years.list(
  parentId: musicLibraryId,
  includeItemTypes: const ['MusicAlbum'],
  sortBy: const ['ProductionYear'],
  descending: true,
);
final y1999 = await jellyfin.years.byYear(1999);
```

---

### 32. Localization

Server-side catalogs that picker UIs need to populate: countries,
cultures (languages), parental rating scales, and the localization
options the admin configured. Reading these saves the client from
hard-coding values that the server may not accept.

#### 32.1 Countries and cultures

```dart
final countries = await jellyfin.localization.countries();
final cultures = await jellyfin.localization.cultures();
```

Each entry is a raw map. Country entries carry `Name`,
`DisplayName`, `TwoLetterISORegionName`; cultures carry the two-
and three-letter ISO codes plus display names.

#### 32.2 Parental ratings

```dart
final ratings = await jellyfin.localization.parentalRatings();
for (final r in ratings) {
  print('${r['Value']}: ${r['Name']}');
}
```

The numeric `Value` is what the server stores; `Name` is the
display string (e.g. `'PG-13'`, `'TV-14'`).

#### 32.3 Server localization options

```dart
final options = await jellyfin.localization.options();
```

The choices the admin picked for preferred metadata language and
fallback behaviour.

---

### 33. Error handling

#### 33.1 JellyfinException and JellyfinErrorType

Every public call throws `JellyfinException` on failure:

```dart
try {
  await jellyfin.items.list(parentId: '…');
} on JellyfinException catch (e) {
  print('${e.type} → ${e.statusCode} → ${e.message}');
}
```

`JellyfinErrorType` values: `connection`, `timeout`, `auth`,
`notFound`, `badRequest`, `serverError`, `parse`, `state`, `cancelled`,
`unknown`. The exception also carries `statusCode`, `path`, `cause`,
`stackTrace` and `retryAfter` (the server's `Retry-After`, on a `429` or
`503`).

#### 33.2 Retriable vs terminal

```dart
try {
  await jellyfin.items.list(parentId: musicLibraryId);
} on JellyfinException catch (e) {
  if (e.isCancelled) {
    // the caller cancelled: not a failure, ignore it
  } else if (e.isTransient) { // network failure, 5xx or 429
    scheduleRetry();
  } else if (e.isAuthError) { // 401 or 403, token rejected
    await reAuthenticate();
  } else if (e.isNotFound) { // confirmed absence
    surfaceError('Gone from the server');
  } else {
    surfaceError(e.message);
  }
}
```

| Getter | True for |
| :--- | :--- |
| `isNetworkFailure` | no answer at all: connection failed or timed out (`isRetriable` is a deprecated alias) |
| `isTransient` | may pass later: a network failure, a 5xx or `429` |
| `isNotFound` | the server answered `404` |
| `isCancelled` | the request was cancelled through a cancel token |
| `isAuthError` | `401` or `403` |

For idempotent reads, a `JellyfinRetryPolicy` ([1.8](#18-retries)) can
do the retrying for you.

#### 33.3 Auth invalidation

`JellyfinException.isAuthError` is the signal to re-run
`authenticateByName` or the Quick Connect flow. The library will not
automatically re-fetch a token; that's an app-level policy decision.

---

### 34. Escape hatch

When the typed sub-APIs don't yet cover an endpoint, drop down to:

#### 34.1 Raw request

```dart
final response = await jellyfin.request<Map<String, Object?>>(
  '/Users/${jellyfin.userId}/Items',
  queryParameters: {
    'IncludeItemTypes': 'Audio',
    'Recursive': true,
    'Limit': 0,
  },
);
final total = response.data?['TotalRecordCount'];
```

Same HTTP client, headers, retry policy and `JellyfinException`
translation as the typed sub-APIs. It returns a `JellyfinResponse<T>`
(`data`, `statusCode`, `headers`, `uri`). Pass `method: 'POST'` /
`'DELETE'`, `extraHeaders`, `data`, `absoluteUrl: true` and
`cancelToken` as needed; a `List` in `queryParameters` repeats the key
once per element. `responseType` picks the decoding:
`JellyfinResponseType.json` (default: JSON when the server says so,
otherwise text), `.plain` (UTF-8 text) or `.bytes` (a `Uint8List`).
`get()`, `post()` and `delete()` are shorthands.

```dart
final m3u8 = await jellyfin.request<String>(
  '/Audio/${track.id}/main.m3u8',
  responseType: JellyfinResponseType.plain,
);
print(m3u8.data);
```

#### 34.2 Raw bytes

```dart
final response = await jellyfin.requestBytes(
  '/Items/$id/Download',
  absoluteUrl: false,
);
final bytes = response.data;
```

`requestBytes()` holds the whole body in memory: fine for artwork and
small files. `url` is absolute by default (pass a URL a builder made);
with `absoluteUrl: false` it is a path on the server. For media, stream
it ([34.3](#343-streamed-body)) or write it to disk
([35](#35-downloads)).

#### 34.3 Streamed body

```dart
final res = await jellyfin.requestStream(
  jellyfin.audio.directStreamUrl(itemId: track.id).$1,
);
print('${res.contentLength} bytes, ${res.contentType}');
await for (final chunk in res.stream) {
  sink(chunk);
}
```

`requestStream()` answers a `JellyfinStreamedResponse` as soon as the
headers arrive. Listen to `stream` once; cancelling the subscription
closes the connection. A pause in the body longer than `receiveTimeout`
fails the stream unless you pass `stallTimeout: false`.

---

### 35. Downloads

#### 35.1 Downloading to a file

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
    cancelToken: token, // token.cancel() aborts and removes the file
    onProgress: (received, total) => print('$received / ${total ?? '?'}'),
  );
  print('$written bytes');
}
```

The body is written as it arrives to `<path>.part` and renamed to the
target only once complete, so the target either holds the whole file or
does not exist: a failure, a stall past the receive timeout or a
cancellation removes the partial file and throws a `JellyfinException`
(of type `cancelled` for a cancellation). `onProgress` gets the total
when the server sent a `Content-Length`.

---

## Project background

All the typed DTOs, sub-APIs, and architectural patterns were implemented through the use of Claude Code.

---

*Developed by Alessandro Di Ronza*
