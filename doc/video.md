Build video stream URLs, and work with subtitles, trickplay thumbnails and media segments.

## Video streaming

Like `audio` (see the [Audio streaming and HLS](https://pub.dev/documentation/dart_jellyfin/latest/topics/Audio%20streaming%20and%20HLS-topic.html) topic), `videos` builds URLs and fetches
nothing; the token travels as `ApiKey`.

### Stream URL

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

### Choosing between direct play and transcoding

Ask the server first, with a device profile (see the [Playback negotiation and reporting](https://pub.dev/documentation/dart_jellyfin/latest/topics/Playback%20negotiation%20and%20reporting-topic.html) topic):

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

### Parts, versions and attachments

```dart
// A movie split across files (CD1, CD2).
final parts = await jellyfin.videos.additionalParts(itemId: movie.id);
for (final p in parts.items) {
  print('${p.name} (${p.id})');
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

## Subtitles

Subtitles are the entries of `mediaSources[…].mediaStreams` whose `type`
is `Subtitle`. The `index` below is that stream's `index`, the same value
as `subtitleStreamIndex` in `videos.streamUrl()` (see Stream URL above).

### Subtitle stream URL

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

### Fetching subtitle text

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

### Upload and delete

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

### Remote search and download

With a subtitle provider plugin on the server, such as OpenSubtitles:

```dart
final hits = await jellyfin.subtitles.searchRemote(
  itemId: movie.id,
  language: 'eng',
);
for (final h in hits) {
  print('${h.providerName} - ${h.name} (${h.format})');
}

await jellyfin.subtitles.downloadRemote(
  itemId: movie.id,
  subtitleId: hits.first.id,
);
```

`getRemote(id:)` fetches a result's text without attaching it.

### Fallback fonts

For `.ass` and `.ssa` subtitles drawn with libass, the server hosts
fallback fonts:

```dart
final fonts = await jellyfin.subtitles.fallbackFonts();
final fontUrl = jellyfin.subtitles.fallbackFontUrl(
  name: fonts.first.name,
);
```

## Trickplay

Trickplay images are the thumbnails shown while scrubbing. Each video
item lists the widths the server generated in `JellyfinItem.trickplay`,
keyed by media source id, then by width. `items.byId()` sends it; a list
sends it when `fields` has `JellyfinItemField.trickplay`. Each
`JellyfinTrickplayInfo` finds the tile for a position.

### Tile URL

```dart
final info = movie.trickplay[movie.mediaSources.first.id]?[320];
if (info != null) {
  final url = jellyfin.trickplay.tileUrl(
    itemId: movie.id,
    width: info.width,
    index: info.tileIndexAt(position),
  );
  // The thumbnail within the tile: info.thumbnailAt(position) modulo
  // info.thumbnailsPerTile, laid out tileWidth by tileHeight.
}
```

### HLS tile playlist

For a player that loads the tiles from a playlist:

```dart
final playlistUrl = jellyfin.trickplay.hlsPlaylistUrl(
  itemId: movie.id,
  mediaSourceId: mediaSourceId,
  width: 320,
);
```

## Media segments

Media segments mark time ranges of an item (intro, recap, outro,
commercial, preview). Plugins such as Intro Skipper create them, and a
player uses them to show a skip button.

### Listing segments

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
