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
<td valign="middle"><code>dart_jellyfin</code> is a Dart client for Jellyfin 12. It covers libraries, playlists, streaming, lyrics, playback reporting, remote control and search through typed Dart objects, and keeps the session for you.</td>
</tr>
</table>

---

## Installation

Add `dart_jellyfin` to your `pubspec.yaml`:

```yaml
dependencies:
  dart_jellyfin: ^0.3.0
```

`package:dart_jellyfin/dart_jellyfin.dart` is the library. File downloads
live in `package:dart_jellyfin/io.dart`, because they need `dart:io` (see
[Downloads](#28-downloads)).

---

## Contents

*   [Features](#features)
*   [Quick start](#quick-start)
*   [Guide](#guide)
    <details>
    <summary><a href="#1-initialization-and-lifecycle"><b>1. Initialization and lifecycle</b></a></summary>

    * [1.1 Creating a client](#11-creating-a-client)
    * [1.2 Credentials and the Authorization header](#12-credentials-and-the-authorization-header)
    * [1.3 Server and session](#13-server-and-session)
    * [1.4 Choosing the HTTP stack](#14-choosing-the-http-stack)
    * [1.5 Closing the client](#15-closing-the-client)

    </details>

    <details>
    <summary><a href="#2-authentication"><b>2. Authentication</b></a></summary>

    * [2.1 Username and password](#21-username-and-password)
    * [2.2 Quick Connect](#22-quick-connect)
    * [2.3 Users](#23-users)

    </details>

    <details>
    <summary><a href="#3-system"><b>3. System</b></a></summary>

    * [3.1 Server info](#31-server-info)
    * [3.2 Counts, endpoint and clock](#32-counts-endpoint-and-clock)
    * [3.3 Server administration](#33-server-administration)

    </details>

    <details>
    <summary><a href="#4-library-browsing"><b>4. Library browsing</b></a></summary>

    * [4.1 Libraries](#41-libraries)
    * [4.2 Listing items](#42-listing-items)
    * [4.3 Item kinds, sort keys and filters](#43-item-kinds-sort-keys-and-filters)
    * [4.4 Fields](#44-fields)
    * [4.5 Counting items](#45-counting-items)
    * [4.6 Single item and related items](#46-single-item-and-related-items)
    * [4.7 Artists](#47-artists)
    * [4.8 Genres](#48-genres)
    * [4.9 People, studios and years](#49-people-studios-and-years)
    * [4.10 Filter facets](#410-filter-facets)
    * [4.11 Collections](#411-collections)

    </details>

    <details>
    <summary><a href="#5-playlists"><b>5. Playlists</b></a></summary>

    * [5.1 Creating a playlist](#51-creating-a-playlist)
    * [5.2 Listing entries](#52-listing-entries)
    * [5.3 Adding, removing and moving entries](#53-adding-removing-and-moving-entries)
    * [5.4 Renaming, updating and deleting](#54-renaming-updating-and-deleting)
    * [5.5 Sharing](#55-sharing)

    </details>

    <details>
    <summary><a href="#6-search-suggestions-and-instant-mix"><b>6. Search, suggestions and instant mix</b></a></summary>

    * [6.1 Search hints](#61-search-hints)
    * [6.2 Suggestions](#62-suggestions)
    * [6.3 Instant mix](#63-instant-mix)

    </details>

    <details>
    <summary><a href="#7-lyrics"><b>7. Lyrics</b></a></summary>

    * [7.1 Reading lyrics](#71-reading-lyrics)
    * [7.2 Uploading and deleting](#72-uploading-and-deleting)
    * [7.3 Remote search and download](#73-remote-search-and-download)

    </details>

    <details>
    <summary><a href="#8-audio-streaming"><b>8. Audio streaming</b></a></summary>

    * [8.1 Universal stream URL](#81-universal-stream-url)
    * [8.2 Direct stream URL](#82-direct-stream-url)
    * [8.3 Transcoded file URL](#83-transcoded-file-url)

    </details>

    <details>
    <summary><a href="#9-hls-playlists"><b>9. HLS playlists</b></a></summary>

    * [9.1 Audio master and variant](#91-audio-master-and-variant)
    * [9.2 Video master and variant](#92-video-master-and-variant)
    * [9.3 Segments, live and stopping a transcode](#93-segments-live-and-stopping-a-transcode)

    </details>

    <details>
    <summary><a href="#10-media-info-and-playback-negotiation"><b>10. Media info and playback negotiation</b></a></summary>

    * [10.1 Playback info](#101-playback-info)
    * [10.2 Posting a device profile](#102-posting-a-device-profile)
    * [10.3 Live streams](#103-live-streams)
    * [10.4 Bitrate probe](#104-bitrate-probe)

    </details>

    <details>
    <summary><a href="#11-playback-reporting"><b>11. Playback reporting</b></a></summary>

    * [11.1 Start](#111-start)
    * [11.2 Progress](#112-progress)
    * [11.3 Stopped](#113-stopped)
    * [11.4 Ping](#114-ping)

    </details>

    <details>
    <summary><a href="#12-sessions-and-remote-control"><b>12. Sessions and remote control</b></a></summary>

    * [12.1 Listing sessions](#121-listing-sessions)
    * [12.2 Registering this client as a cast target](#122-registering-this-client-as-a-cast-target)
    * [12.3 Playing on a remote session](#123-playing-on-a-remote-session)
    * [12.4 Playstate commands](#124-playstate-commands)
    * [12.5 General and system commands](#125-general-and-system-commands)
    * [12.6 Messages and content](#126-messages-and-content)

    </details>

    <details>
    <summary><a href="#13-user-data"><b>13. User data</b></a></summary>

    * [13.1 Favorites](#131-favorites)
    * [13.2 Played state and ratings](#132-played-state-and-ratings)
    * [13.3 Reading and writing the record](#133-reading-and-writing-the-record)

    </details>

    <details>
    <summary><a href="#14-images"><b>14. Images</b></a></summary>

    * [14.1 Building an image URL](#141-building-an-image-url)
    * [14.2 Fetching bytes](#142-fetching-bytes)
    * [14.3 Image types and other images](#143-image-types-and-other-images)

    </details>

    <details>
    <summary><a href="#15-subtitles"><b>15. Subtitles</b></a></summary>

    * [15.1 Subtitle stream URL](#151-subtitle-stream-url)
    * [15.2 Fetching subtitle text](#152-fetching-subtitle-text)
    * [15.3 Upload and delete](#153-upload-and-delete)
    * [15.4 Remote search and download](#154-remote-search-and-download)
    * [15.5 Fallback fonts](#155-fallback-fonts)

    </details>

    <details>
    <summary><a href="#16-trickplay"><b>16. Trickplay</b></a></summary>

    * [16.1 Tile URL](#161-tile-url)
    * [16.2 HLS tile playlist](#162-hls-tile-playlist)

    </details>

    <details>
    <summary><a href="#17-media-segments"><b>17. Media segments</b></a></summary>

    * [17.1 Listing segments](#171-listing-segments)

    </details>

    <details>
    <summary><a href="#18-video-streaming"><b>18. Video streaming</b></a></summary>

    * [18.1 Stream URL](#181-stream-url)
    * [18.2 Choosing between direct play and transcoding](#182-choosing-between-direct-play-and-transcoding)
    * [18.3 Parts, versions and attachments](#183-parts-versions-and-attachments)

    </details>

    <details>
    <summary><a href="#19-tv-shows"><b>19. TV shows</b></a></summary>

    * [19.1 Seasons and episodes](#191-seasons-and-episodes)
    * [19.2 Next up and upcoming](#192-next-up-and-upcoming)

    </details>

    <details>
    <summary><a href="#20-movies"><b>20. Movies</b></a></summary>

    * [20.1 Recommendations](#201-recommendations)
    * [20.2 Trailers](#202-trailers)

    </details>

    <details>
    <summary><a href="#21-live-tv"><b>21. Live TV</b></a></summary>

    * [21.1 Channels](#211-channels)
    * [21.2 Programs and guide](#212-programs-and-guide)
    * [21.3 Recordings](#213-recordings)
    * [21.4 Timers](#214-timers)

    </details>

    <details>
    <summary><a href="#22-syncplay"><b>22. SyncPlay</b></a></summary>

    * [22.1 Listing and joining groups](#221-listing-and-joining-groups)
    * [22.2 Group playback control](#222-group-playback-control)
    * [22.3 Group queue](#223-group-queue)

    </details>

    <details>
    <summary><a href="#23-channels"><b>23. Channels</b></a></summary>

    * [23.1 Listing channels](#231-listing-channels)
    * [23.2 Items, latest and features](#232-items-latest-and-features)

    </details>

    <details>
    <summary><a href="#24-display-preferences"><b>24. Display preferences</b></a></summary>

    * [24.1 Reading and writing](#241-reading-and-writing)
    * [24.2 Custom preferences](#242-custom-preferences)

    </details>

    <details>
    <summary><a href="#25-localization"><b>25. Localization</b></a></summary>

    * [25.1 Countries, cultures and ratings](#251-countries-cultures-and-ratings)

    </details>

    <details>
    <summary><a href="#26-errors-cancellation-retries-and-paging"><b>26. Errors, cancellation, retries and paging</b></a></summary>

    * [26.1 Exceptions](#261-exceptions)
    * [26.2 Classifying a failure](#262-classifying-a-failure)
    * [26.3 Cancellation](#263-cancellation)
    * [26.4 Retries](#264-retries)
    * [26.5 Paging](#265-paging)

    </details>

    <details>
    <summary><a href="#27-notifications-and-typed-events"><b>27. Notifications and typed events</b></a></summary>

    * [27.1 Connecting](#271-connecting)
    * [27.2 Typed events](#272-typed-events)
    * [27.3 Subscriptions](#273-subscriptions)

    </details>

    <details>
    <summary><a href="#28-downloads"><b>28. Downloads</b></a></summary>

    * [28.1 Downloading to a file](#281-downloading-to-a-file)

    </details>

    <details>
    <summary><a href="#29-escape-hatch"><b>29. Escape hatch</b></a></summary>

    * [29.1 Raw request](#291-raw-request)
    * [29.2 Raw bytes](#292-raw-bytes)
    * [29.3 Streamed body](#293-streamed-body)

    </details>
*   [Project background](#project-background)

---

## Features

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/package.png" width="32"></td>
<td valign="middle" width="45%"><b>Pure Dart</b><br>no native plugin and no Flutter dependency, so it runs on every Dart platform, the web included.</td>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/shield-check.png" width="32"></td>
<td valign="middle" width="45%"><b>Typed models</b><br>every answer is a typed Dart object with a <code>raw</code> map, and item kinds, fields, sort keys and filters are <a href="#43-item-kinds-sort-keys-and-filters">typed values</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/key-round.png" width="32"></td>
<td valign="middle"><b>Both sign-in flows</b><br><a href="#21-username-and-password">username and password</a>, and <a href="#22-quick-connect">Quick Connect</a> with a code approved on another device.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/wrench.png" width="32"></td>
<td valign="middle"><b>Authorization header</b><br>the <code>MediaBrowser</code> header with client, device, version and token, rebuilt when the token changes (see <a href="#12-credentials-and-the-authorization-header">1.2</a>).</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/layers.png" width="32"></td>
<td valign="middle"><b>One client</b><br>a <code>JellyfinClient</code> holds the identity, server, token and user, and every sub-API works through it.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/file-code.png" width="32"></td>
<td valign="middle"><b>Follows the OpenAPI document</b><br>routes, parameter names and casing match the contract at <a href="https://api.jellyfin.org">api.jellyfin.org</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/music.png" width="32"></td>
<td valign="middle"><b>Lyrics with timing</b><br><a href="#7-lyrics"><code>JellyfinLyrics</code></a> with line and word timing, rendered to LRC or enhanced LRC with <code>toLrc()</code>.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/audio-lines.png" width="32"></td>
<td valign="middle"><b>Audio streaming</b><br><a href="#8-audio-streaming">URL builders</a> for the server's choice between direct play and transcoding, the original file, a transcoded file and HLS.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/triangle-alert.png" width="32"></td>
<td valign="middle"><b>Typed errors</b><br>every failure is a <a href="#261-exceptions"><code>JellyfinException</code></a> with a type to branch on: auth, not found, timeout, connection, cancelled.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/terminal.png" width="32"></td>
<td valign="middle"><b>Escape hatch</b><br><a href="#29-escape-hatch"><code>request()</code>, <code>requestBytes()</code> and <code>requestStream()</code></a> for routes the sub-APIs do not cover.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/globe.png" width="32"></td>
<td valign="middle"><b>Any HTTP stack</b><br>built on <code>package:http</code>: pass a <code>CupertinoClient</code> or <code>CronetClient</code> for HTTP/2 and the system proxy, or a <code>MockClient</code> in tests.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/cpu.png" width="32"></td>
<td valign="middle"><b>Off the caller's isolate</b><br>large answers are inflated, decoded and parsed on a background isolate, so the UI keeps its frames.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/zap.png" width="32"></td>
<td valign="middle"><b>Cancellation and retries</b><br><a href="#263-cancellation"><code>withCancelToken()</code></a> makes every call of a view cancellable, and a <a href="#264-retries"><code>JellyfinRetryPolicy</code></a> resends idempotent requests after transient failures.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/download.png" width="32"></td>
<td valign="middle"><b>Streaming downloads</b><br><a href="#28-downloads"><code>downloadToFile()</code></a> writes a body to disk as it arrives, with progress, and never leaves a partial file.</td>
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

  // Sign in.
  final auth = await jellyfin.user.authenticateByName(
    username: 'me',
    password: 'hunter2',
  );
  jellyfin.setSession(token: auth.accessToken, userId: auth.user.id);

  // Find the music library and list its albums.
  final views = await jellyfin.library.userViews();
  final music = views.firstWhere((v) => v.isMusic);
  final albums = await jellyfin.items.list(
    parentId: music.id,
    includeItemTypes: const [JellyfinItemKind.musicAlbum],
    sortBy: const [JellyfinSortField.sortName],
    limit: 50,
  );

  // List the first album's tracks and build a stream URL for one.
  final tracks = await jellyfin.items.list(
    parentId: albums.items.first.id,
    includeItemTypes: const [JellyfinItemKind.audio],
  );
  final url = jellyfin.audio.universalStreamUrl(
    itemId: tracks.items.first.id,
    maxStreamingBitrate: 320000,
    audioCodec: 'aac',
    playSessionId: 'my-session-uuid',
  );
  print(url); // hand it to your audio engine

  // Release the HTTP client when the app is done with the server.
  jellyfin.close();
}
```

---

## Guide

`JellyfinClient` holds the identity of your app, the server, the token and the user. Each part of the Jellyfin API is a sub-API on it (`jellyfin.items`, `jellyfin.playlists`, `jellyfin.audio` and so on), and every call goes through the same connection. Ids, names and keys are always named parameters.

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

Only `credentials` is required. `baseUrl` can come later through
`connect()`. The other parameters:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `httpClient` | a `dart:io` or browser client | The `package:http` client to send through (see [1.4](#14-choosing-the-http-stack)) |
| `connectTimeout` | 15 s | Bounds the handshake of the default client and, with `receiveTimeout`, the wait for the response headers |
| `receiveTimeout` | 30 s | Also bounds every pause inside a response body |
| `jsonIsolateThreshold` | 50 KB | Bodies this size or larger are decoded, and parsed into models, on a background isolate |
| `retryPolicy` | `JellyfinRetryPolicy.none` | Resends idempotent requests after a transient failure (see [26.4](#264-retries)) |

With the default `dart:io` client, a gzip body is inflated as part of
that decode, so above the threshold it leaves the caller's isolate too.
The web has no isolates, and the work runs in place.

`JellyfinClient` and the sub-API classes are not `final`, so your tests
can implement or mock them. The models are `final` data classes.

#### 1.2 Credentials and the Authorization header

`JellyfinCredentials` says who the client is. Every request carries:

```
Authorization: MediaBrowser Client="MyApp", Device="iPhone", DeviceId="…uuid…", Version="1.0.0"
```

Once a session is set, the same header ends with `, Token="…"`. This is
the only authorization header the client sends, and the one Jellyfin 12
accepts by default.

`deviceId` must be a stable UUID for each installation: Jellyfin tracks
sessions and transcodes by it. Generate it once, store it
(SharedPreferences, Keychain, Android Keystore) and reuse it.

`JellyfinAuthHeader.build()` returns the header value, for a player that
sends its own requests:

```dart
final header = JellyfinAuthHeader.build(credentials, token: jellyfin.token);
```

#### 1.3 Server and session

```dart
jellyfin.connect('https://jellyfin.example.com'); // a trailing slash is dropped

jellyfin.setSession(token: savedToken, userId: savedUserId);
jellyfin.clearSession(); // drop the token and user id, keep the server
jellyfin.disconnect();   // drop the server too
```

`connect()` switches the client to another server and keeps the session:
call `clearSession()` first when the new server has other accounts.
`token`, `userId`, `baseUrl` and `isAuthenticated` are read-only getters,
so you can store the session and restore it with `setSession()`.

#### 1.4 Choosing the HTTP stack

The transport is `package:http`, so any `http.Client` works. On Apple
platforms and Android the native stacks bring HTTP/2, the system proxy
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

// Later: a client you pass in is yours to close.
httpClient.close();
```

In tests, pass a `MockClient` from `package:http/testing.dart`. A client
you pass in handles gzip itself; the native stacks do it on their own
threads.

#### 1.5 Closing the client

```dart
jellyfin.close();
```

`close()` closes the HTTP client the `JellyfinClient` created. Later
requests, through it or any `withCancelToken()` view, fail with
`JellyfinErrorType.state`. A client you passed as `httpClient` stays
open.

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

`authenticateByName()` returns a `JellyfinAuthResult` with `accessToken`,
`serverId` and the `JellyfinUser`. Wrong credentials throw a
`JellyfinException` of type `auth`.

#### 2.2 Quick Connect

Quick Connect signs in a new device without a password: the user
approves a 6-character code on a device that is already signed in.

```dart
// Is Quick Connect on for this server?
if (!await jellyfin.quickConnect.enabled()) return;

// Start the flow on the new device and show the code.
final init = await jellyfin.quickConnect.initiate();
print('Enter ${init.code} in Jellyfin, under Settings, Quick Connect');

// Poll until the user approves it.
while (!(await jellyfin.quickConnect.state(secret: init.secret)).authenticated) {
  await Future<void>.delayed(const Duration(seconds: 2));
}

// Exchange the secret for a token.
final auth = await jellyfin.user.authenticateWithQuickConnect(secret: init.secret);
jellyfin.setSession(token: auth.accessToken, userId: auth.user.id);
```

To approve a code from the device that is already signed in:

```dart
await jellyfin.quickConnect.authorize(code: 'ABC123');
```

#### 2.3 Users

```dart
final me = await jellyfin.user.currentUser();
print('${me.name} (${me.id})');

// No token needed: the users the server shows on its sign-in screen.
final users = await jellyfin.user.publicUsers();
for (final u in users) {
  print('${u.name} (primaryImageTag=${u.primaryImageTag})');
}
```

With an admin token, `user` also manages accounts: `list()`, `byId()`,
`create()`, `updateProfile()`, `updatePolicy()`, `updateConfiguration()`,
`updatePassword()` and `delete()`. `forgotPassword()` and
`forgotPasswordPin()` run the password reset.

---

### 3. System

#### 3.1 Server info

```dart
// No token needed.
final public = await jellyfin.system.publicInfo();
print('${public.serverName} ${public.version} (${public.id})');

// With a token: adds the operating system, and admin fields for an admin.
final info = await jellyfin.system.info();

// True when the server answers; never throws.
if (await jellyfin.system.ping()) {
  print('reachable');
}
```

Call `publicInfo()` before asking for credentials, to check that the URL
points at a Jellyfin server. `ping()` calls the same route and turns any
failure into `false`.

#### 3.2 Counts, endpoint and clock

```dart
final counts = await jellyfin.library.counts();
print('${counts.albumCount} albums, ${counts.songCount} tracks');

final endpoint = await jellyfin.system.endpointInfo(); // isLocal, isInNetwork
final clock = await jellyfin.system.utcTime();        // for clock-skew correction
```

These return `JellyfinItemCounts`, `JellyfinEndpointInfo` and
`JellyfinUtcTime`. Like every model, each keeps the decoded body in
`raw`.

#### 3.3 Server administration

These calls need an admin token.

```dart
final tasks = await jellyfin.scheduledTasks.list();
final devices = await jellyfin.devices.list();
final log = await jellyfin.activityLog.entries(limit: 50);

final scan = tasks.firstWhere((t) => t.key == 'RefreshLibrary');
await jellyfin.scheduledTasks.start(taskId: scan.id);
```

They return `JellyfinScheduledTask`, `JellyfinDevice` and a
`JellyfinQueryResult<JellyfinActivityLogEntry>`. The "Audio
Normalization" task fills `JellyfinItem.normalizationGain` in the
libraries that have `EnableLUFSScan` on.

The rest of the administration API answers maps:

| Sub-API | Covers |
| :--- | :--- |
| `system` | `storage()`, `logs()`, `logFile()`, `restart()`, `shutdown()` |
| `configuration` | Server configuration, named sections, branding, default metadata options |
| `libraryStructure` | Virtual folders: add, remove, rename, media paths, library options |
| `library` | `refresh()`, `mediaFolders()`, `physicalPaths()`, `deleteItem()`, the `notify…()` hooks for external managers |
| `items` | `refresh()`, `updateMetadata()`, `updateContentType()`, `metadataEditorInfo()` |
| `itemLookup` | Remote metadata search for movies, series, albums, artists and more, and `applySearchResult()` |
| `remoteImage` | Remote artwork providers, search and download |
| `plugins`, `packages` | Installed plugins, their configuration, the catalog and repositories |
| `startup` | The first-run wizard |
| `environment` | Directory browsing and path validation for the library setup |
| `branding` | Login disclaimer and custom CSS |
| `apiKey`, `backup`, `dashboard`, `clientLog` | API keys, backups, plugin configuration pages, client log upload |
| `liveTv` | Tuners, listing providers and channel mappings |

---

### 4. Library browsing

#### 4.1 Libraries

```dart
final views = await jellyfin.library.userViews();
for (final v in views) {
  print('${v.collectionType ?? '?'}: ${v.name}');
}
final music = views.firstWhere((v) => v.isMusic);
```

A view's `id` is the `parentId` that scopes the calls below to one
library. `collectionType` is one of `music`, `movies`, `tvshows`,
`musicvideos`, `photos`, `books`, `livetv`, `homevideos`, `boxsets`,
`playlists` or `folders`; `isMusic`, `isMovies`, `isTvShows` and
`isPhotos` test the common ones.

`userViews.list()` reads the same views with options: hidden libraries,
channel and plugin content, and preset views. `groupingOptions()` lists
the ways the server offers to group them.

```dart
final all = await jellyfin.userViews.list(
  includeHidden: true,
  includeExternalContent: false,
  presetViews: const ['music', 'tvshows'],
);
final options = await jellyfin.userViews.groupingOptions();
```

#### 4.2 Listing items

`items.list()` is the general browse call. It takes the `/Items`
parameters and returns a `JellyfinQueryResult<JellyfinItem>` with
`items`, `totalRecordCount` and `startIndex`:

```dart
final page = await jellyfin.items.list(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  sortBy: const [JellyfinSortField.productionYear, JellyfinSortField.sortName],
  descending: true,
  startIndex: 50, // the second page
  limit: 50,
  searchTerm: 'pink',
  filters: const [JellyfinItemFilter.isFavorite],
  genreIds: [genreId],
  fields: JellyfinItemsApi.browseFields,
);
print('${page.items.length} of ${page.totalRecordCount}');
```

Every filter that takes several values is a list: `ids`,
`excludeItemIds`, `genreIds`, `artistIds`, `albumArtistIds`,
`contributingArtistIds`, `albumIds`, `studioIds`, `personIds`, `tags`,
`officialRatings`, the name-based `genres`, `artists`, `albums` and
`studios`, and `years` (a `List<int>`). Pass the list as it is: each
value travels as its own query parameter, so a genre or tag that holds a
comma or a pipe arrives intact. Prefer the id filters to the name
filters: ids come from [`filter.facets()`](#410-filter-facets) and
survive a rename.

A few rules of the route:

- `descending` applies only together with `sortBy`.
- `parentId` scopes albums and tracks to a library, but not artists:
  with `JellyfinItemKind.musicArtist` and a library's id, `/Items`
  answers the artists of every library. List one library's artists with
  [`artists`](#47-artists).
- `enableTotalRecordCount` (on by default) makes the server count the
  whole result. Pass `false` when you page until a short page and never
  show a total; `totalRecordCount` then counts only the page.

#### 4.3 Item kinds, sort keys and filters

`includeItemTypes`, `excludeItemTypes`, `fields`, `sortBy`, `mediaTypes`
and `filters` take typed values instead of strings:

| Type | Parameter | Examples |
| :--- | :--- | :--- |
| `JellyfinItemKind` | `includeItemTypes`, `excludeItemTypes` | `audio`, `musicAlbum`, `musicArtist`, `playlist`, `movie`, `series`, `episode`, `boxSet` |
| `JellyfinItemField` | `fields` | `genres`, `people`, `mediaSources`, `overview`, `recursiveItemCount` |
| `JellyfinSortField` | `sortBy` | `sortName`, `productionYear`, `dateCreated`, `datePlayed`, `random` |
| `JellyfinMediaType` | `mediaTypes` | `audio`, `video`, `photo`, `book` |
| `JellyfinItemFilter` | `filters` | `isFavorite`, `isPlayed`, `isUnplayed`, `isResumable` |

The server ignores a value it does not know and answers a wider result,
so a typo in a string would list everything. With the typed values a
typo does not compile. Each type holds one constant per value of the
Jellyfin API document, and reads as the wire string. A value the package
does not list yet is one constructor away:

```dart
final items = await jellyfin.items.list(
  includeItemTypes: const [JellyfinItemKind('NewKind')],
);
```

#### 4.4 Fields

`fields` defaults to empty, the server's own selection. Two presets cover
the common cases:

| Preset | Fields | Use for |
| :--- | :--- | :--- |
| `JellyfinItemsApi.browseFields` | `Genres`, `DateCreated`, `ChildCount`, `SortName`, `PrimaryImageAspectRatio` | Grids and lists of albums, artists, playlists, genres |
| `JellyfinItemsApi.musicFields` | `Overview`, `Genres`, `MediaSources`, `MediaStreams`, `ProviderIds`, `PrimaryImageAspectRatio`, `SortName`, `DateCreated`, `ChildCount`, `ParentId`, `Path`, `OriginalTitle` | A queue or a track info sheet, where media sources and streams are read |

`MediaSources` and `MediaStreams` make most of a track's size, so ask
for `musicFields` only where you read them. Neither preset is a default,
because `/Items` also serves video and photo libraries.

Image tags are not fields: the server sends them on every item, so
covers work with either preset. `enableImages: false` drops `ImageTags`.

Some typed members of `JellyfinItem` need their field:

| Member | Field | Holds |
| :--- | :--- | :--- |
| `genreItems` | `genres` | Each genre's id and name (`JellyfinNameGuidPair`), the ids `genreIds` and `instantMix.fromItem()` take |
| `people` | `people` | `JellyfinItemPerson`s: name, id, role, a `type` such as `'Composer'`, image tag |
| `recursiveItemCount` | `recursiveItemCount` | Items below a folder, at any depth |
| `albumCount`, `songCount`, `artistCount`, `movieCount`, `seriesCount`, `episodeCount`, … | `itemCounts` | Counts of an artist, genre or person |

Others come without a field: `albumArtistItems` (album artists with
ids), `playlistItemId`, `normalizationGain` and `albumNormalizationGain`
(in dB, from the "Audio Normalization" task), `artworkItemId` and
`artworkVersion`. The last two give the id whose cover to show, a
track's own or its album's, and the image tag to put in a cache key:

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

#### 4.5 Counting items

`count()` takes the narrowing parameters of `list()`, without paging,
sorting and fields, and returns the total without the items:

```dart
final albumCount = await jellyfin.items.count(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  genreIds: [genreId],
);
```

#### 4.6 Single item and related items

```dart
final item = await jellyfin.items.byId(itemId: '12345');
if (item != null) {
  print('${item.name} ${item.mediaSources.firstOrNull?.bitrate}');
}

// Continue listening or watching, and recently added.
final resume = await jellyfin.items.resume(
  mediaTypes: const [JellyfinMediaType.audio],
  limit: 10,
);
final latest = await jellyfin.items.latest(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  limit: 10,
);

// Related items.
final similar = await jellyfin.library.similarAlbums(itemId: album.id, limit: 12);
final path = await jellyfin.library.ancestors(itemId: track.id);
```

`byId()` returns `null` when the server answers 404. `resume()` returns a
`JellyfinQueryResult<JellyfinItem>`, `latest()` a plain
`List<JellyfinItem>`.

`library` has `similarItems()`, `similarAlbums()`, `similarArtists()`,
`similarMovies()`, `similarShows()` and `similarTrailers()`, plus
`themeSongs()`, `themeVideos()` and `themeMedia()`. `items` has
`specialFeatures()`, `localTrailers()` and `intros()`, and
`downloadUrl()` and `fileUrl()` for the original file.

#### 4.7 Artists

`artists` lists each artist once, however many tracks credit it, and
honors `parentId`. Use it for an Artists tab:

```dart
// Artists credited on at least one album.
final albumArtists = await jellyfin.artists.albumArtists(
  parentId: musicLibraryId,
  sortBy: const [JellyfinSortField.sortName],
  limit: 100,
);

// Every artist, track artists included.
final all = await jellyfin.artists.list(
  parentId: musicLibraryId,
  searchTerm: 'beat',
  limit: 50,
);

final aphex = await jellyfin.artists.byName(name: 'Aphex Twin'); // null on 404
```

Artists are also people on Jellyfin 12: `persons.list(personTypes:
['Artist'])` answers them, without the sort and genre filters of
`artists`.

#### 4.8 Genres

Jellyfin keeps two items for each genre name: a generic `Genre` and, for
music, a `MusicGenre`, with different ids. Both ids filter
`items.list(genreIds:)`, but only the music-genre id seeds an
[instant mix](#63-instant-mix).

Scope `genres.list()` with the music library's `parentId`: those ids are
the ones an instant mix accepts. Without `parentId` it answers the
generic genres, whatever `includeItemTypes` says.

```dart
final musicGenres = await jellyfin.genres.list(
  parentId: musicLibraryId,
  sortBy: const [JellyfinSortField.sortName],
);

// Exact name lookups: the music genre, and the generic one.
final ambient = await jellyfin.musicGenres.byName(name: 'Ambient');
final action = await jellyfin.genres.byName(name: 'Action');
```

`musicGenres.byName()` is the one route that finds a music genre by its
exact name. `genres.byName()` takes no `parentId` and answers the
generic genre.

#### 4.9 People, studios and years

`persons`, `studios` and `years` list one kind of entity each, as
`JellyfinItem`s, and look one up by name or year:

```dart
final actors = await jellyfin.persons.list(
  personTypes: const ['Actor'],
  searchTerm: 'cumberbatch',
  limit: 20,
);
final one = await jellyfin.persons.byName(name: 'Benedict Cumberbatch');

final studios = await jellyfin.studios.list(parentId: movieLibraryId);
final pixar = await jellyfin.studios.byName(name: 'Pixar');

final years = await jellyfin.years.list(
  parentId: musicLibraryId,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  sortBy: const [JellyfinSortField.productionYear],
  descending: true,
);
final y1999 = await jellyfin.years.byYear(year: 1999);
```

`persons.list(appearsInItemId:)` lists the people credited on one item,
such as a movie's cast. `nameStartsWith`, `nameStartsWithOrGreater` and
`nameLessThan` drive an alphabet picker on `persons`, `studios` and
`genres`.

#### 4.10 Filter facets

Ask the server which values exist in a library, to fill filter chips:

```dart
final facets = await jellyfin.filter.facets(
  parentId: musicLibraryId,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
);
for (final g in facets.genres) {
  print('${g.id} ${g.name}');
}

final legacy = await jellyfin.filter.legacy(
  parentId: movieLibraryId,
  includeItemTypes: const [JellyfinItemKind.movie],
);
print(legacy.years);           // [1999, 2001, 2024, ...]
print(legacy.officialRatings); // ['PG-13', 'R', ...]
```

`facets()` answers genres with ids and tags. Pass the chosen ids to
`items.list(genreIds:)`. `legacy()` answers genres and tags by name, plus
the years and official ratings that `facets()` leaves out.

#### 4.11 Collections

Collections are `BoxSet` items, so `items.list(includeItemTypes:
[JellyfinItemKind.boxSet])` lists them. `collection` edits them:

```dart
final created = await jellyfin.collection.create(
  name: 'Best of 2024',
  ids: [albumA, albumB],
);
final collectionId = created['Id'] as String;

await jellyfin.collection.addItems(collectionId: collectionId, ids: [albumC]);
await jellyfin.collection.removeItems(collectionId: collectionId, ids: [albumA]);

// Every collection an item belongs to, for an "Included in" row.
final includedIn = await jellyfin.library.collections(itemId: album.id);
```

Removing an item from a collection leaves the item in the library.

---

### 5. Playlists

#### 5.1 Creating a playlist

```dart
final playlist = await jellyfin.playlists.create(
  name: 'My Mix',
  mediaType: 'Audio', // 'Audio', 'Video', 'Photo' or 'Book'
  itemIds: const ['12345', '12346'],
  isPublic: true, // private by default
);
```

#### 5.2 Listing entries

```dart
final entries = await jellyfin.playlists.items(
  playlistId: playlist.id,
  fields: JellyfinItemsApi.musicFields,
  limit: 100,
);
final same = await jellyfin.playlists.byId(playlistId: playlist.id);
```

`fields` defaults to the server's own selection. Playlists hold video as
readily as audio, so pass `musicFields` when you read media sources.

#### 5.3 Adding, removing and moving entries

```dart
await jellyfin.playlists.addItems(
  playlistId: playlist.id,
  itemIds: const ['99999', '99998'],
);

// Remove and move by entry id, read from playlists.items().
final entries = await jellyfin.playlists.items(playlistId: playlist.id);
final entryIds = [
  for (final item in entries.items)
    if (item.playlistItemId case final id?) id,
];
await jellyfin.playlists.removeItems(
  playlistId: playlist.id,
  entryIds: entryIds.take(2).toList(),
);
await jellyfin.playlists.moveItem(
  playlistId: playlist.id,
  playlistItemId: entryIds.last,
  newIndex: 0,
);
```

An entry id is a `JellyfinPlaylistEntryId`, so an item id does not fit
where an entry id belongs. It reads as a `String`; wrap a stored one with
`JellyfinPlaylistEntryId(id)`.

The server gives each entry the id of its item. With a track listed
twice, removing its entry removes every copy and moving it moves the
first: the server has no way to address one copy of a duplicate.

#### 5.4 Renaming, updating and deleting

```dart
await jellyfin.playlists.rename(playlistId: playlist.id, name: 'New name');
await jellyfin.playlists.update(playlistId: playlist.id, isPublic: false);
await jellyfin.playlists.delete(playlistId: playlist.id);
```

`update()` also takes `name` and `ids`, the whole new list of entries.

The server saves an entry change a moment after it answers. A rename sent
in that moment is lost, though the server reports success, and a delete
leaves the playlist file on disk for the next library scan. So
`rename()`, `update()` and `delete()` wait until
`JellyfinPlaylistsApi.renameSettle` (1 second) has passed since this
client last changed that playlist's entries. With no recent entry write
they are sent at once. Writes from another app or another
`JellyfinClient` are not tracked.

#### 5.5 Sharing

```dart
final access = await jellyfin.playlists.users(playlistId: playlist.id);
for (final a in access) {
  print('${a.userId} canEdit=${a.canEdit}');
}

await jellyfin.playlists.setUserAccess(
  playlistId: playlist.id,
  userId: friendId,
  canEdit: true,
);
await jellyfin.playlists.removeUserAccess(playlistId: playlist.id, userId: friendId);
```

---

### 6. Search, suggestions and instant mix

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

`hints()` returns a `JellyfinQueryResult<JellyfinSearchHint>`, a flat
list with `itemId`, `name`, `matchedTerm`, `type`, `mediaType`, run time
and a `primaryImageTag` for [`images.url()`](#141-building-an-image-url).
For search with the full item filters, use `items.list(searchTerm:)`.

#### 6.2 Suggestions

`suggestions.list()` answers a flat feed of items the server picks for
the user, of any kind:

```dart
final picks = await jellyfin.suggestions.list(
  mediaType: const [JellyfinMediaType.audio],
  type: const [JellyfinItemKind.musicAlbum, JellyfinItemKind.audio],
  limit: 30,
);
```

For movie rows grouped by reason, see [Movies](#201-recommendations).

#### 6.3 Instant mix

The server builds a list of related tracks from a seed: a song, an
album, an artist, a playlist or a music genre.

```dart
final mix = await jellyfin.instantMix.fromItem(itemId: track.id, limit: 50);
for (final item in mix.items) {
  print('${item.name} - ${item.albumArtist}');
}

final fromSong = await jellyfin.instantMix.fromSong(songId: track.id);
final fromAlbum = await jellyfin.instantMix.fromAlbum(albumId: album.id);
final fromArtist = await jellyfin.instantMix.fromArtist(artistId: artist.id);
final fromList = await jellyfin.instantMix.fromPlaylist(playlistId: playlist.id);

// A genre seeds a mix by its music-genre id.
final rock = await jellyfin.musicGenres.byName(name: 'Rock');
final fromGenre = await jellyfin.instantMix.fromItem(itemId: rock!.id);
```

Each call returns a `JellyfinQueryResult<JellyfinItem>`. Take a genre's
id from a track's `genreItems`, from `genres.list(parentId:
musicLibraryId)` or from `musicGenres.byName()` (see
[4.8](#48-genres)): a generic genre id answers an empty mix.

---

### 7. Lyrics

#### 7.1 Reading lyrics

```dart
final lyrics = await jellyfin.audio.lyrics(itemId: track.id);
if (lyrics == null) {
  // no lyrics
} else if (lyrics.hasCues) {
  print(lyrics.toLrc(enhanced: true)); // enhanced LRC, a time for each word
} else if (lyrics.isSynced) {
  print(lyrics.toLrc()); // LRC, a time for each line
} else {
  print(lyrics.toPlainText());
}
```

`jellyfin.lyrics.forItem(itemId:)` is the same call. `JellyfinLyrics`
holds the `lines`, each with `startTicks` (in 100-nanosecond units),
`start` as a `Duration`, `text` and `cues`: word-level
`JellyfinLyricCue`s with their own start and end. `metadata` holds the
file's tags (`JellyfinLyricMetadata`: artist, album, title, offset) when
the server sends them. `toLrc(enhanced: true)` writes the lines that have
cues in enhanced LRC and the others as plain LRC.

`lyrics()` returns `null` on a 404, which the server answers both for a
track without lyrics and for an id that names no item.

No route serves the original `.lrc` or `.txt` file: the lyrics route
answers the parsed lyrics as JSON. Rebuild a file with `toLrc()` or
`toPlainText()`.

#### 7.2 Uploading and deleting

```dart
final bytes = await File('track.lrc').readAsBytes();
final uploaded = await jellyfin.lyrics.upload(
  itemId: track.id,
  fileName: 'track.lrc',
  body: bytes,
);

await jellyfin.lyrics.delete(itemId: track.id);
```

The server picks the parser from the file extension, and `upload()`
returns the lyrics as it parsed them.

#### 7.3 Remote search and download

With a lyrics provider plugin on the server:

```dart
final hits = await jellyfin.lyrics.searchRemote(itemId: track.id);
for (final hit in hits) {
  print('${hit.providerName}: ${hit.id} (${hit.lyrics?.lines.length} lines)');
}

final preview = await jellyfin.lyrics.previewRemote(lyricId: hits.first.id);
final attached = await jellyfin.lyrics.downloadRemote(
  itemId: track.id,
  lyricId: hits.first.id,
);
```

Each hit is a `JellyfinRemoteLyric` with `id`, `providerName` and the
lyrics as `JellyfinLyrics` when the provider sent them. `previewRemote()`
fetches a result without attaching it; `downloadRemote()` attaches it to
the track.

---

### 8. Audio streaming

These methods build URLs and fetch nothing. Hand the URL to your audio
engine (mpv, AVPlayer, ExoPlayer). The token travels in the URL as
`ApiKey`, so segment requests need no extra headers.

#### 8.1 Universal stream URL

The server decides between direct play and transcoding from what the
client accepts:

```dart
final url = jellyfin.audio.universalStreamUrl(
  itemId: track.id,
  containers: const ['mp3', 'aac', 'flac', 'ogg', 'opus'],
  maxStreamingBitrate: 320000,
  audioCodec: 'aac',
  transcodingProtocol: 'hls', // or 'http'
  transcodingContainer: 'ts',
  playSessionId: 'my-uuid',
);
```

Other parameters: `mediaSourceId`, `audioBitRate`, `maxAudioChannels`,
`transcodingAudioChannels`, `maxAudioSampleRate`, `maxAudioBitDepth`,
`startTimeTicks`.

#### 8.2 Direct stream URL

The file as it is stored, with no transcoding:

```dart
final (url, ext) = jellyfin.audio.directStreamUrl(
  itemId: track.id,
  container: 'flac',
  playSessionId: 'my-uuid',
);
```

`isStatic` (on by default) serves the stored file. `ext` echoes
`container`, for naming a file.

#### 8.3 Transcoded file URL

A progressive transcode: one seekable file at a set bitrate, not HLS
segments. Use it to download a smaller copy:

```dart
final (url, ext) = jellyfin.audio.transcodedStreamUrl(
  itemId: track.id,
  audioCodec: 'aac',
  container: 'm4a',
  audioBitRate: 192000,
  playSessionId: 'download-${track.id}',
);
```

`audioBitRate` sets the bitrate, in bits per second. The container must
hold the codec. The server reuses a running transcode of the same item
for the same device and play session, whatever the other parameters
say, so give each download its own `playSessionId`.

---

### 9. HLS playlists

Audio and video each have a `master.m3u8`, with every bandwidth variant,
and a `main.m3u8` with one. Use the master when the player picks the
quality, the variant when you already did.

The playlist URLs carry the token as `ApiKey` and, as `DeviceId`, the
device id of the credentials. The server files the transcode under that
device and `playSessionId`, and the [playback reports](#11-playback-reporting)
reach it through the same pair.

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
  segmentContainer: 'mp4', // 'ts' or 'mp4'
  segmentLength: 6,        // seconds
  minSegments: 1,          // segments ready before the server answers
  enableAutoStreamCopy: false, // both false: always transcode
  allowAudioStreamCopy: false,
  playSessionId: 'my-uuid',
);
```

Also typed: `audioSampleRate`, `maxAudioBitDepth`, `audioChannels`,
`maxAudioChannels`, `startTimeTicks`, `breakOnNonKeyFrames` and `context`
(`Streaming` or `Static`). `params` adds any other query parameter as it
is.

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

`videoVariantUrl()` takes the same parameters. Cap a video transcode
with `videoBitRate` and `audioBitRate`: the video routes do not read
`maxStreamingBitrate`.

#### 9.3 Segments, live and stopping a transcode

The player walks the playlist, so segment URLs are rarely needed. They
are there for cache warming or debugging:

```dart
final segmentUrl = jellyfin.hls.videoSegmentUrl(
  itemId: movie.id,
  playlistId: 'main',
  segmentId: 0,
  container: 'ts',
);
```

For a live TV channel the server keeps the playlist growing. Use the live
variant:

```dart
final liveUrl = jellyfin.hls.videoLiveUrl(
  itemId: channelId,
  videoCodec: 'h264',
  audioCodec: 'aac',
);
```

`stopEncoding(playSessionId:)` stops a transcode at once. The API
document hides that route; [`playback.stopped()`](#113-stopped) is the
supported way to end a transcode.

---

### 10. Media info and playback negotiation

`/Items/{itemId}/PlaybackInfo` takes a `DeviceProfile`, what the client
can decode, and answers a `JellyfinPlaybackInfo` whose `mediaSources`
say whether each source plays directly (`supportsDirectPlay`,
`supportsDirectStream`, `supportsTranscoding`) and, when it does not,
carry a `transcodingUrl` to use as it is.

#### 10.1 Playback info

```dart
final info = await jellyfin.mediaInfo.info(itemId: track.id);
```

The `GET` form sends no device profile, so the server assumes generic
defaults. That suits audio; for video, post a profile.

#### 10.2 Posting a device profile

```dart
const profile = JellyfinDeviceProfile(
  name: 'MyApp',
  maxStreamingBitrate: 8000000,
  musicStreamingTranscodingBitrate: 320000,
  directPlayProfiles: [
    JellyfinDirectPlayProfile.audio(container: 'mp3,aac,flac'),
    JellyfinDirectPlayProfile.video(container: 'mp4,mkv,webm'),
  ],
);

final info = await jellyfin.mediaInfo.postedInfo(
  itemId: movie.id,
  deviceProfile: profile,
  maxStreamingBitrate: 8000000,
  subtitleStreamIndex: 3,
);
final source = info.mediaSources.first;
print('directPlay=${source.supportsDirectPlay} transcoding=${source.transcodingUrl}');
```

Each direct play profile names its media kind (`Audio` or `Video`), so an
audio source matches an audio profile. `transcodingProfiles`,
`codecProfiles`, `containerProfiles` and `subtitleProfiles` take the
finer rules as maps, and `extra` adds any other top-level field of the
profile.

#### 10.3 Live streams

A source with `RequiresOpening` in its `raw` map, such as a live TV
channel, needs an explicit open and close:

```dart
final opened = await jellyfin.mediaInfo.openLiveStream(
  openToken: source.raw['OpenToken'] as String,
  itemId: movie.id,
  deviceProfile: profile,
);
final liveStreamId = opened.mediaSources.first.raw['LiveStreamId'] as String;
// play, then:
await jellyfin.mediaInfo.closeLiveStream(liveStreamId: liveStreamId);
```

#### 10.4 Bitrate probe

The server sends `size` bytes; the time they take gives a starting
`maxStreamingBitrate`:

```dart
final stopwatch = Stopwatch()..start();
final size = await jellyfin.mediaInfo.bitrateTestBytesLength(size: 1000000);
stopwatch.stop();
final bitsPerSecond = (size ?? 0) * 8 * 1000 ~/ stopwatch.elapsedMilliseconds;
```

---

### 11. Playback reporting

Reports tell the server what plays: they fill "Continue listening",
play counts and the dashboard, and keep a transcode alive. Positions are
`Duration`s; the library converts them to Jellyfin's ticks (100
nanoseconds).

#### 11.1 Start

```dart
await jellyfin.playback.start(
  itemId: track.id,
  playSessionId: 'my-uuid',
  mediaSourceId: track.mediaSources.first.id,
  method: JellyfinPlayMethod.transcode, // directPlay, directStream or transcode
);
```

#### 11.2 Progress

Send it about every 10 seconds and on every change of state:

```dart
await jellyfin.playback.progress(
  itemId: track.id,
  position: const Duration(seconds: 42),
  isPaused: false,
  volumeLevel: 80,
  playSessionId: 'my-uuid',
  method: JellyfinPlayMethod.transcode,
  order: JellyfinPlaybackOrder.shuffle, // or defaultOrder
  repeat: JellyfinRepeatMode.all,       // none, all or one
);
```

#### 11.3 Stopped

```dart
await jellyfin.playback.stopped(
  itemId: track.id,
  position: const Duration(seconds: 240),
  playSessionId: 'my-uuid',
);
```

`stopped()` ends the play session and its transcode.

#### 11.4 Ping

Tells the server the transcode of a play session is still wanted:

```dart
await jellyfin.playback.ping(playSessionId: 'my-uuid');
```

A player that sends `progress()` every 10 seconds needs no ping. Ping
covers stretches with nothing to report, such as buffering before the
first `start()`.

---

### 12. Sessions and remote control

`sessions` lists the clients connected to the server, registers this
client as a cast target and sends commands to other sessions. Commands
sent to this client arrive as [notifications](#27-notifications-and-typed-events).

#### 12.1 Listing sessions

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

#### 12.2 Registering this client as a cast target

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
[playstate commands](#124-playstate-commands), which the `PlayState`
capability turns on. `postFullCapabilities()` posts the whole body as a
map.

When the user signs out, call `sessions.reportSessionEnded()` so the
server drops the session.

#### 12.3 Playing on a remote session

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

#### 12.4 Playstate commands

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

#### 12.5 General and system commands

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

#### 12.6 Messages and content

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

---

### 13. User data

User data is what the server keeps for each user and item: favorite,
played, play count, resume position and rating. Each call below returns
the new `JellyfinUserData`.

#### 13.1 Favorites

```dart
await jellyfin.userData.markFavorite(itemId: track.id);
await jellyfin.userData.unmarkFavorite(itemId: track.id);

// For a toggle:
await jellyfin.userData.setFavorite(itemId: track.id, isFavorite: true);
```

#### 13.2 Played state and ratings

```dart
await jellyfin.userData.markPlayed(itemId: track.id);
await jellyfin.userData.markUnplayed(itemId: track.id);

await jellyfin.userData.rate(itemId: track.id, likes: true);
await jellyfin.userData.clearRating(itemId: track.id);
```

#### 13.3 Reading and writing the record

```dart
final data = await jellyfin.userData.get(itemId: track.id);
print('position=${data.playbackPositionTicks} count=${data.playCount}');

// Reset the resume position, keep the rest.
await jellyfin.userData.update(
  itemId: track.id,
  userData: JellyfinUserData(
    playCount: data.playCount,
    isFavorite: data.isFavorite,
    played: data.played,
    playbackPositionTicks: 0,
  ),
);
```

Every call in this chapter acts for the session's user; pass `userId` to
act for another.

---

### 14. Images

Image URLs follow a pattern, `/Items/{id}/Images/{type}`, with a `tag`
from `JellyfinItem.imageTags` that changes when the image does. The
server resizes, so the client needs no scaling.

With `tag` as the only parameter, the server sends the stored file as it
is. Any processing parameter (sizing, `quality`, `blur`,
`percentPlayed`, `unplayedCount`, `backgroundColor`) makes it re-encode.
Without `format`, it then picks the output from the request's `Accept`
header: WebP when that lists `image/webp`, as browsers and most image
widgets do, JPEG otherwise.

#### 14.1 Building an image URL

```dart
final url = jellyfin.images.url(
  itemId: track.artworkItemId ?? track.id,
  tag: track.artworkVersion,
  maxWidth: 512,
  maxHeight: 512,
  format: JellyfinImagesApi.formatJpg,
  quality: 85,
);
```

`type` defaults to `JellyfinImagesApi.typePrimary`. The sizing
parameters:

| Parameters | Effect |
| :--- | :--- |
| `maxWidth`, `maxHeight` | Fit inside the box, aspect kept: the pair for a cover cache |
| `fillWidth`, `fillHeight` | Cover the box, aspect kept |
| `width`, `height` | Exactly those dimensions, stretched |

`format` picks the encoding (`formatJpg`, `formatPng`, `formatWebp`,
`formatGif`, `formatBmp`, `formatSvg`) and `quality` (0 to 100) applies
to the lossy ones. `percentPlayed` and `unplayedCount` draw a progress
bar and a badge into the image, and `blur` takes a radius.
`backgroundColor` fills transparency and must be a hex `RGB`, `ARGB`,
`RRGGBB` or `AARRGGBB`, with an optional `#`. Any other value throws an
`ArgumentError`, because the server would drop the sizing too and send
the full original.

#### 14.2 Fetching bytes

```dart
final Uint8List? bytes = await jellyfin.images.fetch(
  itemId: track.artworkItemId ?? track.id,
  tag: track.artworkVersion,
  maxWidth: 512,
  maxHeight: 512,
  format: JellyfinImagesApi.formatJpg,
  cancelToken: token, // drop it when the cell scrolls away
);
```

`fetch()` takes the sizing and encoding parameters of `url()` and a
`cancelToken`. It returns `null` on a 404 and throws a
`JellyfinException` on a transient failure, so "no image" and "try again
later" stay apart.

#### 14.3 Image types and other images

| Constant | Wire value | Holds |
| :--- | :--- | :--- |
| `typePrimary` | `Primary` | Album cover, movie poster, track art |
| `typeArt` | `Art` | Clear art |
| `typeBackdrop` | `Backdrop` | Backdrop |
| `typeBanner` | `Banner` | Wide banner |
| `typeLogo` | `Logo` | Title logo |
| `typeThumb` | `Thumb` | Wide thumbnail |
| `typeDisc` | `Disc` | Disc art |

Artists, genres, music genres, studios and people have images by name:

```dart
final artistUrl = jellyfin.images.artistImageUrl(
  artistName: 'Aphex Twin',
  maxWidth: 300,
  maxHeight: 300,
);
final images = await jellyfin.images.listItemImages(itemId: album.id);
```

`genreImageUrl()`, `musicGenreImageUrl()`, `studioImageUrl()` and
`personImageUrl()` work the same way. `listItemImages()` returns each
image of an item as `JellyfinImageInfo` (type, index, tag, size,
dimensions). `setItemImage()`, `deleteItemImage()` and
`reorderItemImage()` edit an item's images; `userImageUrl()`,
`uploadUserImage()` and `deleteUserImage()` the user's own picture; and
`splashscreenUrl()` the login screen's background.

---

### 15. Subtitles

Subtitles are the entries of `mediaSources[…].mediaStreams` whose `type`
is `Subtitle`. The `index` below is that stream's `index`, the same value
as `subtitleStreamIndex` in [`videos.streamUrl()`](#181-stream-url).

#### 15.1 Subtitle stream URL

```dart
final url = jellyfin.subtitles.streamUrl(
  itemId: movie.id,
  mediaSourceId: mediaSourceId,
  index: 3,
  format: JellyfinSubtitlesApi.formatVtt,
);

// A slice, for seeking through transcoded subtitles.
final slice = jellyfin.subtitles.streamWithTicksUrl(
  itemId: movie.id,
  mediaSourceId: mediaSourceId,
  index: 3,
  startPositionTicks: 6000000000, // 10 minutes
  endPositionTicks: 6600000000,   // 11 minutes
);

// Subtitles delivered over HLS, with subtitleMethod: 'Hls' on the video URL.
final playlistUrl = jellyfin.subtitles.playlistUrl(
  itemId: movie.id,
  mediaSourceId: mediaSourceId,
  index: 3,
  segmentLength: 10,
);
```

`format` defaults to `vtt`. The constants are `formatSrt`, `formatVtt`,
`formatAss`, `formatSsa` and `formatSub`.

#### 15.2 Fetching subtitle text

For a player that draws subtitles itself:

```dart
final body = await jellyfin.subtitles.fetch(
  itemId: movie.id,
  mediaSourceId: mediaSourceId,
  index: 3,
  format: JellyfinSubtitlesApi.formatSrt,
);
if (body == null) {
  // 404: the subtitle stream is gone
}
```

`fetchFromPosition(startPosition:)` fetches from a position on. The text
is decoded by its byte order mark, then the declared charset, then UTF-8
with a Latin-1 fallback.

#### 15.3 Upload and delete

These calls need an admin token.

```dart
await jellyfin.subtitles.upload(
  itemId: movie.id,
  language: 'eng',
  format: 'srt',
  data: base64Subtitle, // the file, base64-encoded
  isForced: true,       // isHearingImpaired is the other flag
);

await jellyfin.subtitles.delete(itemId: movie.id, index: 3);
```

#### 15.4 Remote search and download

With a subtitle provider plugin on the server, such as OpenSubtitles:

```dart
final hits = await jellyfin.subtitles.searchRemote(
  itemId: movie.id,
  language: 'eng',
);
for (final h in hits) {
  print('${h['ProviderName']} - ${h['Name']} (${h['Format']})');
}

await jellyfin.subtitles.downloadRemote(
  itemId: movie.id,
  subtitleId: hits.first['Id'] as String,
);
```

`getRemote(id:)` fetches a result without attaching it.

#### 15.5 Fallback fonts

For `.ass` and `.ssa` subtitles drawn with libass, the server hosts
fallback fonts:

```dart
final fonts = await jellyfin.subtitles.fallbackFonts();
final fontUrl = jellyfin.subtitles.fallbackFontUrl(
  name: fonts.first['Name'] as String,
);
```

---

### 16. Trickplay

Trickplay images are the thumbnails shown while scrubbing. Each video
item lists its trickplay widths, and each width's `Interval`, in
`JellyfinItem.raw['Trickplay']`. Pick a width the server generated, then
pick the tile from the position.

#### 16.1 Tile URL

```dart
final url = jellyfin.trickplay.tileUrl(
  itemId: movie.id,
  width: 320,
  index: tileIndex, // from the position and the width's Interval
);
```

#### 16.2 HLS tile playlist

For a player that loads the tiles from a playlist:

```dart
final playlistUrl = jellyfin.trickplay.hlsPlaylistUrl(
  itemId: movie.id,
  mediaSourceId: mediaSourceId,
  width: 320,
);
```

---

### 17. Media segments

Media segments mark time ranges of an item (intro, recap, outro,
commercial, preview). Plugins such as Intro Skipper create them, and a
player uses them to show a skip button.

#### 17.1 Listing segments

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

`JellyfinMediaSegmentType` has `unknown`, `commercial`, `preview`,
`recap`, `outro` and `intro`. `start` and `end` are `Duration`s.

---

### 18. Video streaming

Like [`audio`](#8-audio-streaming), `videos` builds URLs and fetches
nothing; the token travels as `ApiKey`.

#### 18.1 Stream URL

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

Cap a transcode with `videoBitRate` and `audioBitRate`. `isStatic: true`
serves the original file with no remuxing. `params` replays a transcode
the server chose, from the query string of a `transcodingUrl`.

#### 18.2 Choosing between direct play and transcoding

Ask the server first, with a [device profile](#102-posting-a-device-profile):

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
} else if (source.transcodingUrl case final path?) {
  play('${jellyfin.baseUrl}$path'); // the server built it: use it as it is
}
```

#### 18.3 Parts, versions and attachments

```dart
// A movie split across files (CD1, CD2).
final parts = await jellyfin.videos.additionalParts(itemId: movie.id);
for (final p in parts) {
  print('${p['Name']} (${p['Id']})');
}

// An attachment of a source, such as a font in an MKV.
final fontUrl = jellyfin.videos.attachmentUrl(
  videoId: movie.id,
  mediaSourceId: movie.mediaSources.first.id,
  index: 0,
);
```

With an admin token, `mergeVersions(ids:)` groups items as versions of
one movie, and `deleteAlternateSources()` splits them again.

---

### 19. TV shows

These calls return a `JellyfinQueryResult<JellyfinItem>`, like
`items.list()`.

#### 19.1 Seasons and episodes

```dart
final seasons = await jellyfin.tvShows.seasons(
  seriesId: seriesId,
  isSpecialSeason: false,
);
for (final s in seasons.items) {
  print('${s.indexNumber} ${s.name}');
}

final episodes = await jellyfin.tvShows.episodes(
  seriesId: seriesId,
  season: 2,
  fields: const [JellyfinItemField.overview, JellyfinItemField.primaryImageAspectRatio],
  sortBy: JellyfinSortField.premiereDate,
);
```

`seasonId` scopes the episodes by the season's item id instead of its
number. `episodes()` takes a single `sortBy` key and no sort order.

#### 19.2 Next up and upcoming

```dart
final nextUp = await jellyfin.tvShows.nextUp(
  limit: 12,
  enableResumable: true,
  enableRewatching: false,
);
final upcoming = await jellyfin.tvShows.upcoming(limit: 20);
```

`nextUp(nextUpDateCutoff:)` keeps the series last watched on or after a
date (an ISO 8601 string). `upcoming()` lists the episodes whose premiere
date is in the future.

---

### 20. Movies

#### 20.1 Recommendations

The server groups recommended movies in rows by reason, such as "Because
you watched":

```dart
final rows = await jellyfin.movies.recommendations(
  parentId: movieLibraryId,
  categoryLimit: 6,
  itemLimit: 12,
);
for (final row in rows) {
  print('${row.recommendationType} ${row.baselineItemName}: ${row.items.length} items');
}
```

Each `JellyfinMovieRecommendation` has `categoryId`, `recommendationType`
(such as `SimilarToRecentlyPlayed`), `baselineItemName` and its `items`.

#### 20.2 Trailers

Trailers are items of kind `Trailer`:

```dart
final trailers = await jellyfin.items.list(
  includeItemTypes: const [JellyfinItemKind.trailer],
  sortBy: const [JellyfinSortField.dateCreated],
  descending: true,
  limit: 20,
);
```

---

### 21. Live TV

#### 21.1 Channels

```dart
final channels = await jellyfin.liveTv.channels(
  type: 'TV', // or 'Radio'
  sortBy: const [JellyfinSortField.defaultOrder],
  limit: 50,
);
for (final ch in channels.items) {
  print('${ch.indexNumber} ${ch.name}');
}

final channel = await jellyfin.liveTv.channel(channelId: channelId);
// channel?.raw['CurrentProgram'] holds what is on now.
```

The channels route has no search: filter the answer by name.

#### 21.2 Programs and guide

```dart
final now = DateTime.now().toUtc();
final guide = await jellyfin.liveTv.programs(
  channelIds: const ['ch1', 'ch2', 'ch3'],
  minStartDate: now.toIso8601String(),
  maxStartDate: now.add(const Duration(hours: 6)).toIso8601String(),
);

final recommended = await jellyfin.liveTv.recommendedPrograms(
  isAiring: true,
  isMovie: true,
  limit: 20,
);
```

#### 21.3 Recordings

```dart
final recordings = await jellyfin.liveTv.recordings(isInProgress: false, limit: 100);
final detail = await jellyfin.liveTv.recording(recordingId: recordingId);
await jellyfin.liveTv.deleteRecording(recordingId: recordingId);

final streamUrl = jellyfin.liveTv.liveRecordingStreamUrl(recordingId: recordingId);
```

#### 21.4 Timers

A timer records one airing, a series timer every airing of a series:

```dart
final scheduled = await jellyfin.liveTv.timers(isActive: true);
await jellyfin.liveTv.createTimer(
  body: {
    'ProgramId': 'pgm-1234',
    'PrePaddingSeconds': 60,
    'PostPaddingSeconds': 300,
  },
);
await jellyfin.liveTv.deleteTimer(timerId: timerId);

final rules = await jellyfin.liveTv.seriesTimers();
await jellyfin.liveTv.createSeriesTimer(
  body: {
    'ProgramId': 'pgm-1234',
    'RecordAnyTime': false,
    'RecordNewOnly': true,
  },
);
```

Tuners, listing providers and channel mappings are on `liveTv` too, for
an admin token.

---

### 22. SyncPlay

SyncPlay plays the same queue on several clients at once. One client
creates a group, the others join, and pause, seek and track changes
reach every member. Each member calls `ready()` once it has buffered, so
the server resumes the group together.

#### 22.1 Listing and joining groups

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

#### 22.2 Group playback control

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

#### 22.3 Group queue

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

---

### 23. Channels

Channels are content sources that plugins provide, such as podcasts or
online radio; for TV channels, see [Live TV](#21-live-tv). Each channel
holds a tree of items, browsed like a library.

#### 23.1 Listing channels

```dart
final channels = await jellyfin.channels.list(supportsLatestItems: true);
```

#### 23.2 Items, latest and features

```dart
final episodes = await jellyfin.channels.items(
  channelId: channelId,
  sortBy: const [JellyfinSortField.dateCreated],
  descending: true,
  limit: 50,
);

final latest = await jellyfin.channels.latest(channelIds: [channelA, channelB], limit: 20);

final features = await jellyfin.channels.features(channelId: channelId);
print(features['SupportsContentDownloading']);
final allFeatures = await jellyfin.channels.allFeatures();
```

`items(folderId:)` opens a folder of the channel. `allFeatures()`
answers the features of every channel in one call.

---

### 24. Display preferences

Display preferences are UI state the server stores for each user and
client: view type, sort order, scroll direction, and a free `customPrefs`
map. They follow the user across devices.

`displayPreferencesId` names the document, such as `usersettings` or a
library's id; `client` keeps one app's documents apart from another's.

#### 24.1 Reading and writing

```dart
final prefs = await jellyfin.displayPreferences.get(
  displayPreferencesId: 'usersettings',
  client: 'my_app',
);
print('${prefs.viewType} sorted by ${prefs.sortBy}');

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

#### 24.2 Custom preferences

`customPrefs` is a `Map<String, String>` for your app's own state; the
server stores it without reading it:

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

### 25. Localization

#### 25.1 Countries, cultures and ratings

The server's lists for pickers. Read them instead of hard-coding values
the server may not accept:

```dart
final countries = await jellyfin.localization.countries();
final cultures = await jellyfin.localization.cultures();
final options = await jellyfin.localization.options();

final ratings = await jellyfin.localization.parentalRatings();
for (final r in ratings) {
  print('${r['Value']}: ${r['Name']}');
}
```

Each entry is a map. Countries carry `Name`, `DisplayName` and
`TwoLetterISORegionName`; cultures the two- and three-letter ISO codes
and display names. A rating's `Value` is what the server stores, its
`Name` the label, such as `PG-13`. `options()` lists the metadata
languages the server offers.

---

### 26. Errors, cancellation, retries and paging

#### 26.1 Exceptions

Every call throws a `JellyfinException` on failure:

```dart
try {
  await jellyfin.items.list(parentId: musicLibraryId);
} on JellyfinException catch (e) {
  print('${e.type} ${e.statusCode} ${e.message}');
}
```

`JellyfinErrorType` is one of `connection`, `timeout`, `auth`,
`notFound`, `badRequest`, `serverError`, `parse`, `state`, `cancelled`
and `unknown`. The exception also carries `statusCode`, `path`, `cause`,
`stackTrace` and `retryAfter`, the server's `Retry-After` on a `429` or
`503`.

Invalid arguments are programming errors and throw `ArgumentError`
instead, such as a malformed `backgroundColor` in `images.url()`.

#### 26.2 Classifying a failure

```dart
try {
  await jellyfin.items.list(parentId: musicLibraryId);
} on JellyfinException catch (e) {
  if (e.isCancelled) {
    // the caller cancelled: not a failure
  } else if (e.isTransient) {
    scheduleRetry(); // network failure, 5xx or 429
  } else if (e.isAuthError) {
    await signInAgain(); // 401 or 403: the token was rejected
  } else if (e.isNotFound) {
    showError('Gone from the server');
  } else {
    showError(e.message);
  }
}
```

| Getter | True for |
| :--- | :--- |
| `isNetworkFailure` | No answer at all: the connection failed or timed out |
| `isTransient` | May pass later: a network failure, a 5xx or a `429` |
| `isNotFound` | The server answered `404` |
| `isCancelled` | The request was cancelled through a cancel token |
| `isAuthError` | `401` or `403` |

The library never fetches a new token on its own. `isAuthError` is the
signal to run `authenticateByName()` or Quick Connect again.

#### 26.3 Cancellation

`withCancelToken()` returns a view of the client whose every sub-API
call is cancelled by one `JellyfinCancelToken`. The view shares the
connection pool, the server and the session, and costs nothing to
create, so make one for each page, filter or search term:

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

A cancelled call throws a `JellyfinException` of type `cancelled`. A
token cancels once; make a new one for the next page. `request()`,
`requestBytes()`, `requestStream()`, `downloadToFile()` and
`images.fetch()` also take a `cancelToken` directly. The notifications
socket is not a request, and a token does not close it.

#### 26.4 Retries

Retries are off by default. Pass a `JellyfinRetryPolicy` to resend
idempotent requests after a transient failure:

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

Only `GET` and `HEAD` are resent, and only after no answer at all, a
`502`, `503`, `504` or `429`. A `500` is not retried. The wait grows
exponentially with full jitter, a `Retry-After` header (in seconds) is
honored up to `maxDelay`, and a cancel token also cancels the wait.
Opening a stream is retried too; a body already flowing is not replayed.

#### 26.5 Paging

`JellyfinPaging.items()` and `JellyfinPaging.pages()` walk any paged call
as a stream, one request per page, nothing fetched ahead:

```dart
final tracks = JellyfinPaging.items(
  (start, size) async => (await jellyfin.items.list(
    parentId: music.id,
    includeItemTypes: const [JellyfinItemKind.audio],
    sortBy: const [JellyfinSortField.sortName],
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

Paging stops at the first page shorter than `pageSize`, or after `limit`
items when you pass one. Cancelling the subscription stops it before the
next request; pair it with a [cancel token](#263-cancellation) to drop
the request in flight too.

---

### 27. Notifications and typed events

The server pushes changes over a WebSocket: user data, library changes,
sessions, scheduled tasks and remote-control commands for this client.

#### 27.1 Connecting

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

#### 27.2 Typed events

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

#### 27.3 Subscriptions

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

---

### 28. Downloads

#### 28.1 Downloading to a file

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
[transcoded file URL](#83-transcoded-file-url).

---

### 29. Escape hatch

For a route the sub-APIs do not cover, call it directly. These calls use
the same HTTP client, headers, retry policy and `JellyfinException`
translation as the sub-APIs.

#### 29.1 Raw request

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

#### 29.2 Raw bytes

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
the body ([29.3](#293-streamed-body)) or write it to disk
([28](#28-downloads)).

#### 29.3 Streamed body

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

---

## Project background

I wrote the typed models, the sub-APIs and the transport with Claude Code.

Jellyfin is a trademark of the Jellyfin project. dart_jellyfin is not affiliated with it.

---

*Developed by Alessandro Di Ronza*
