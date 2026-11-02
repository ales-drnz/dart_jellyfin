Search the server, read its suggestions and instant mixes, and read, upload and find lyrics.

## Search, suggestions and instant mix

### Search hints

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
and a `primaryImageTag` for `images.url()`, in the [User data and images](https://pub.dev/documentation/dart_jellyfin/latest/topics/User%20data%20and%20images-topic.html) topic.
For search with the full item filters, use `items.list(searchTerm:)`.

### Suggestions

`suggestions.list()` answers a flat feed of items the server picks for
the user, of any kind:

```dart
final picks = await jellyfin.suggestions.list(
  mediaType: const [JellyfinMediaType.audio],
  type: const [JellyfinItemKind.musicAlbum, JellyfinItemKind.audio],
  limit: 30,
);
```

For movie rows grouped by reason, see the [TV, movies and live TV](https://pub.dev/documentation/dart_jellyfin/latest/topics/TV,%20movies%20and%20live%20TV-topic.html) topic.

### Instant mix

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
the [Library](https://pub.dev/documentation/dart_jellyfin/latest/topics/Library-topic.html) topic): a generic genre id answers an empty mix.

## Lyrics

### Reading lyrics

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

### Uploading and deleting

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

### Remote search and download

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
