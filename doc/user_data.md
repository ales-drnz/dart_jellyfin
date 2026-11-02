Mark favorites, played state and ratings, build and fetch images, and store display preferences.

## User data

User data is what the server keeps for each user and item: favorite,
played, play count, resume position and rating. Each call below returns
the new `JellyfinUserData`.

### Favorites

```dart
await jellyfin.userData.markFavorite(itemId: track.id);
await jellyfin.userData.unmarkFavorite(itemId: track.id);

// For a toggle:
await jellyfin.userData.setFavorite(itemId: track.id, isFavorite: true);
```

### Played state and ratings

```dart
await jellyfin.userData.markPlayed(itemId: track.id);
await jellyfin.userData.markUnplayed(itemId: track.id);

await jellyfin.userData.rate(itemId: track.id, likes: true);
await jellyfin.userData.clearRating(itemId: track.id);
```

### Reading and writing the record

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

Every user data call acts for the session's user; pass `userId` to
act for another.

## Images

Image URLs follow a pattern, `/Items/{id}/Images/{type}`, with a `tag`
from `JellyfinItem.imageTags` that changes when the image does. The
server resizes, so the client needs no scaling.

With `tag` as the only parameter, the server sends the stored file as it
is. Any processing parameter (sizing, `quality`, `blur`,
`percentPlayed`, `unplayedCount`, `backgroundColor`) makes it re-encode.
Without `format`, it then picks the output from the request's `Accept`
header: WebP when that lists `image/webp`, as browsers and most image
widgets do, JPEG otherwise.

### Building an image URL

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

### Fetching bytes

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

### Image types and other images

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

## Display preferences

Display preferences are UI state the server stores for each user and
client: view type, sort order, scroll direction, and a free `customPrefs`
map. They follow the user across devices.

`displayPreferencesId` names the document, such as `usersettings` or a
library's id; `client` keeps one app's documents apart from another's.

### Reading and writing

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

### Custom preferences

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
