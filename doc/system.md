Read the server's info, counts and clock, run its administration, and read its lists for pickers.

## System

### Server info

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

### Counts, endpoint and clock

```dart
final counts = await jellyfin.library.counts();
print('${counts.albumCount} albums, ${counts.songCount} tracks');

final endpoint = await jellyfin.system.endpointInfo(); // isLocal, isInNetwork
final clock = await jellyfin.system.utcTime();        // for clock-skew correction
```

These return `JellyfinItemCounts`, `JellyfinEndpointInfo` and
`JellyfinUtcTime`. Like every model, each keeps the decoded body in
`raw`.

### Server administration

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

## Localization

### Countries, cultures and ratings

The server's lists for pickers. Read them instead of hard-coding values
the server may not accept:

```dart
final countries = await jellyfin.localization.countries();
final cultures = await jellyfin.localization.cultures();
final options = await jellyfin.localization.options();

final ratings = await jellyfin.localization.parentalRatings();
for (final r in ratings) {
  print('${r.value}: ${r.name}');
}
```

Each entry is a typed model with its `raw` map. A `JellyfinCountry` has
`name`, `displayName` and the ISO region codes; a `JellyfinCulture` the
two- and three-letter ISO codes and display names. A rating's `value` is
what the server stores, its `name` the label, such as `PG-13`.
`options()` lists the metadata languages the server offers.
