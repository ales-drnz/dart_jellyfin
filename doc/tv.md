Browse seasons, episodes and movie recommendations, and watch and record live TV.

## TV shows

These calls return a `JellyfinQueryResult<JellyfinItem>`, like
`items.list()`.

### Seasons and episodes

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

### Next up and upcoming

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

## Movies

### Recommendations

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

### Trailers

Trailers are items of kind `Trailer`:

```dart
final trailers = await jellyfin.items.list(
  includeItemTypes: const [JellyfinItemKind.trailer],
  sortBy: const [JellyfinSortField.dateCreated],
  descending: true,
  limit: 20,
);
```

## Live TV

### Channels

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

### Programs and guide

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

### Recordings

```dart
final recordings = await jellyfin.liveTv.recordings(isInProgress: false, limit: 100);
final detail = await jellyfin.liveTv.recording(recordingId: recordingId);
await jellyfin.liveTv.deleteRecording(recordingId: recordingId);

final streamUrl = jellyfin.liveTv.liveRecordingStreamUrl(recordingId: recordingId);
```

### Timers

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
