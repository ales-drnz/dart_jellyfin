Browse the libraries: items, kinds, fields and filters, artists, genres, people, facets, collections and plugin channels.

## Library browsing

### Libraries

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

### Listing items

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
filters: ids come from `filter.facets()` (see Filter facets below) and
survive a rename.

A few rules of the route:

- `descending` applies only together with `sortBy`.
- `parentId` scopes albums and tracks to a library, but not artists:
  with `JellyfinItemKind.musicArtist` and a library's id, `/Items`
  answers the artists of every library. List one library's artists with
  `artists` (see Artists below).
- `enableTotalRecordCount` (on by default) makes the server count the
  whole result. Pass `false` when you page until a short page and never
  show a total; `totalRecordCount` then counts only the page.

### Item kinds, sort keys and filters

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

### Fields

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

### Counting items

`count()` takes the narrowing parameters of `list()`, without paging,
sorting and fields, and returns the total without the items:

```dart
final albumCount = await jellyfin.items.count(
  parentId: music.id,
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  genreIds: [genreId],
);
```

### Single item and related items

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

### Artists

Jellyfin 12 stores music artists as people, and marks the `/Artists`
routes obsolete. `artists` asks `/Persons`, as Jellyfin Web does for its
Artists and Album Artists tabs. Each artist comes once, by name, and
`parentId` scopes the list to a library:

```dart
// Artists credited on at least one album: the Artists tab.
final albumArtists = await jellyfin.artists.albumArtists(
  parentId: musicLibraryId,
  nameStartsWith: 'A',
  limit: 100,
);

// Artists credited on a track.
final trackArtists = await jellyfin.artists.list(
  parentId: musicLibraryId,
  searchTerm: 'beat',
  limit: 50,
);

final aphex = await jellyfin.artists.byName(name: 'Aphex Twin'); // null on 404

// The artist's albums: a person id filters like an artist id.
final albums = await jellyfin.items.list(
  includeItemTypes: const [JellyfinItemKind.musicAlbum],
  albumArtistIds: [aphex!.id],
);
```

The answers are `Person` items. Their ids filter `items.list()`, but seed
an empty instant mix, and carry no MusicBrainz id. For those, use the
`MusicArtist` item: a track's `artistItems` and `albumArtistItems`, or
`items.list(includeItemTypes: [JellyfinItemKind.musicArtist])`, which
also sorts:

```dart
final musicArtists = await jellyfin.items.list(
  includeItemTypes: const [JellyfinItemKind.musicArtist],
  sortBy: const [JellyfinSortField.sortName],
  limit: 100,
);
final mix = await jellyfin.instantMix.fromArtist(
  artistId: musicArtists.items.first.id,
);
```

### Genres

Jellyfin keeps two items for each genre name: a generic `Genre` and, for
music, a `MusicGenre`, with different ids. Both ids filter
`items.list(genreIds:)`, but only the music-genre id seeds an
instant mix. See the [Search and lyrics](https://pub.dev/documentation/dart_jellyfin/latest/topics/Search%20and%20lyrics-topic.html) topic.

Scope `genres.list()` with the music library's `parentId`: those ids are
the ones an instant mix accepts. Without `parentId` it answers the
generic genres, whatever `includeItemTypes` says.

```dart
final musicGenres = await jellyfin.genres.list(
  parentId: musicLibraryId,
  sortBy: const [JellyfinSortField.sortName],
);

// Exact name lookups: the music genre, and the generic one.
final ambient = await jellyfin.genres.musicGenre(
  name: 'Ambient',
  parentId: musicLibraryId,
);
final action = await jellyfin.genres.byName(name: 'Action');
```

`genres.musicGenre()` finds a music genre by its exact name, ignoring
case, in a music library; it replaces `/MusicGenres/{name}`, which
Jellyfin 12 marks obsolete. `genres.byName()` takes no `parentId` and
answers the generic genre.

### People, studios and years

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

### Filter facets

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

### Collections

Collections are `BoxSet` items, so `items.list(includeItemTypes:
[JellyfinItemKind.boxSet])` lists them. `collection` edits them:

```dart
final created = await jellyfin.collection.create(
  name: 'Best of 2024',
  ids: [albumA, albumB],
);
final collectionId = created.id;

await jellyfin.collection.addItems(collectionId: collectionId, ids: [albumC]);
await jellyfin.collection.removeItems(collectionId: collectionId, ids: [albumA]);

// Every collection an item belongs to, for an "Included in" row.
final includedIn = await jellyfin.library.collections(itemId: album.id);
```

Removing an item from a collection leaves the item in the library.

## Channels

Channels are content sources that plugins provide, such as podcasts or
online radio; for TV channels, see the [TV, movies and live TV](https://pub.dev/documentation/dart_jellyfin/latest/topics/TV,%20movies%20and%20live%20TV-topic.html) topic. Each channel
holds a tree of items, browsed like a library.

### Listing channels

```dart
final channels = await jellyfin.channels.list(supportsLatestItems: true);
```

### Items, latest and features

```dart
final episodes = await jellyfin.channels.items(
  channelId: channelId,
  sortBy: const [JellyfinSortField.dateCreated],
  descending: true,
  limit: 50,
);

final latest = await jellyfin.channels.latest(channelIds: [channelA, channelB], limit: 20);

final features = await jellyfin.channels.features(channelId: channelId);
print(features.supportsContentDownloading);
final allFeatures = await jellyfin.channels.allFeatures();
```

`items(folderId:)` opens a folder of the channel. `allFeatures()`
answers the features of every channel in one call.
