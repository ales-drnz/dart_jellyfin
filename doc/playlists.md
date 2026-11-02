Create playlists, add, remove and move their entries, and share them with other users.

## Creating a playlist

```dart
final playlist = await jellyfin.playlists.create(
  name: 'My Mix',
  mediaType: 'Audio', // 'Audio', 'Video', 'Photo' or 'Book'
  itemIds: const ['12345', '12346'],
  isPublic: true, // private by default
);
```

## Listing entries

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

## Adding, removing and moving entries

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

## Renaming, updating and deleting

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

## Sharing

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
