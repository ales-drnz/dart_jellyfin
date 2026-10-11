// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../jellyfin_models.dart';

// ---------------------------------------------------------------------------
// Items (BaseItemDto subset)
// ---------------------------------------------------------------------------

/// A playlist entry's id ([JellyfinItem.playlistItemId]): what
/// `playlists.removeItems` and `playlists.moveItem` take.
///
/// A type of its own so that an item id cannot be passed where an entry
/// id is meant. On Jellyfin 12.2 the two have the same value, but the API
/// keeps them apart and older servers did not. It is the wire string, so
/// it reads and compares as one; build one from a stored string with
/// `JellyfinPlaylistEntryId(id)`.
extension type const JellyfinPlaylistEntryId(String value) implements String {}

/// Subset of `BaseItemDto`. Hand-rolled — the full DTO has 153 fields,
/// here we lift only what music apps use today. Anything else lives in
/// [JellyfinItem.raw].
final class JellyfinItem {
  /// Stable server-side item id.
  final String id;

  /// Display name.
  final String name;

  /// `BaseItemKind` string; see [JellyfinItemKind] for the recognised values.
  final String? type;

  /// `'Audio' | 'Video' | 'Photo' | 'Book' | 'Unknown'`.
  final String? mediaType;

  /// Library kind for collection-folder items; otherwise null.
  final String? collectionType;

  /// Server-computed sort key (often differs from [name] for "The …" handling).
  final String? sortName;

  /// Original-language title, when known.
  final String? originalTitle;

  /// Plot or description blurb.
  final String? overview;

  /// Parent folder/album/season id.
  final String? parentId;

  /// Id of the owning series, for episodes.
  final String? seriesId;

  /// Owning series name, for episodes.
  final String? seriesName;

  /// Id of the owning season, for episodes.
  final String? seasonId;

  /// Owning season name, for episodes.
  final String? seasonName;

  /// Id of the owning album, for tracks.
  final String? albumId;

  /// Album title, for tracks.
  final String? album;

  /// Primary album artist string, for tracks.
  final String? albumArtist;

  /// All album-artist names, for tracks with multiple credits.
  final List<String> albumArtists;

  /// All track-level artist names.
  final List<String> artists;

  /// Artist references with ids, when the server returns them.
  final List<JellyfinArtistRef> artistItems;

  /// Album artists with their ids (`AlbumArtists`), the id form of
  /// [albumArtists] — what a "go to artist" link needs.
  final List<JellyfinArtistRef> albumArtistItems;

  /// Genres with their ids (`GenreItems`, sent with the `Genres` field):
  /// the ids `items.list(genreIds:)` and `instantMix.fromItem` take, so a
  /// genre chip needs no lookup by name.
  final List<JellyfinNameGuidPair> genreItems;

  /// The entry id inside a playlist (`PlaylistItemId`), present only on
  /// items read from `playlists.items`; pass it to
  /// `playlists.removeItems(entryIds:)` / `playlists.moveItem`.
  ///
  /// On Jellyfin 12.2 it is the *item* id (verified): two copies of one
  /// track share it, removing it removes every copy, and moving it moves
  /// the first. The server offers no way to address one copy of a
  /// duplicate.
  final JellyfinPlaylistEntryId? playlistItemId;

  /// Track number / episode number / generic index within the parent.
  final int? indexNumber;

  /// Disc number / season number / generic parent index.
  final int? parentIndexNumber;

  /// Release year.
  final int? productionYear;

  /// Original release date, in UTC.
  final DateTime? premiereDate;

  /// When the item was first ingested by the server, in UTC.
  final DateTime? dateCreated;

  /// `RunTimeTicks`, where 1 ms = 10_000 ticks.
  final int? runTimeTicks;

  /// File container (e.g. `'mp4'`, `'flac'`).
  final String? container;

  /// Available media sources (file variants the server can serve).
  final List<JellyfinMediaSource> mediaSources;

  /// Top-level media streams (audio/video/subtitle/lyrics).
  final List<JellyfinMediaStream> mediaStreams;

  /// `true` when this item is a folder (album, series, season, library, …).
  final bool isFolder;

  /// Child count for folder-like items.
  final int? childCount;

  /// Items below this one at any depth (`RecursiveItemCount`), sent when
  /// `fields` has `RecursiveItemCount`: an album's or an artist's tracks.
  /// 12.2 omitted it, rather than sending 0, for an artist with no tracks
  /// of its own.
  final int? recursiveItemCount;

  /// Albums (`AlbumCount`) — with [songCount] and the other counts below,
  /// sent on artists, genres and other grouping items when `fields` has
  /// `ItemCounts`. The server sends them flat on the item; there is no
  /// `ItemCounts` object in the answer (verified on 12.2).
  final int? albumCount;

  /// Tracks (`SongCount`); see [albumCount].
  final int? songCount;

  /// Artists (`ArtistCount`); see [albumCount].
  final int? artistCount;

  /// Music videos (`MusicVideoCount`); see [albumCount].
  final int? musicVideoCount;

  /// Movies (`MovieCount`); see [albumCount].
  final int? movieCount;

  /// Series (`SeriesCount`); see [albumCount].
  final int? seriesCount;

  /// Episodes (`EpisodeCount`); see [albumCount].
  final int? episodeCount;

  /// Trailers (`TrailerCount`); see [albumCount].
  final int? trailerCount;

  /// Live TV programs (`ProgramCount`); see [albumCount].
  final int? programCount;

  /// Credited people (`People`), sent when `fields` has `People`: cast
  /// and crew on video, and on music the artists, album artists and
  /// composers, each with its [JellyfinItemPerson.type].
  final List<JellyfinItemPerson> people;

  /// `true` when the server has lyrics for this audio item.
  final bool hasLyrics;

  /// Genre names.
  final List<String> genres;

  /// User-applied tags.
  final List<String> tags;

  /// Map of image kind (`'Primary'`, `'Backdrop'`, …) to image tag for cache busting.
  final Map<String, String> imageTags;

  /// Image tags for each available backdrop, in display order.
  final List<String> backdropImageTags;

  /// Image tag for the owning album's primary art, for tracks.
  final String? albumPrimaryImageTag;

  /// Map of image kind to blurhash for low-quality previews.
  final Map<String, String> imageBlurHashes;

  /// Aspect ratio of the primary image (width/height).
  final double? primaryImageAspectRatio;

  /// Gain in dB that brings this track to the server's loudness target
  /// (`NormalizationGain`), from Jellyfin's own analysis of the file.
  ///
  /// Jellyfin keeps the measured loudness (LUFS) to itself — no DTO in the
  /// 12.x API carries it, nor any loudness field on `MediaSourceInfo` or
  /// `MediaStream` — and exposes only this gain. It survives a transcode
  /// that drops the file's ReplayGain tags.
  ///
  /// Null unless the library has `EnableLUFSScan` on (a library option,
  /// off by default) and the server's "Audio Normalization" scheduled task
  /// has since run on the item.
  final double? normalizationGain;

  /// Album-level gain in dB (`AlbumNormalizationGain`), inherited from the
  /// album's analysis; see [normalizationGain].
  final double? albumNormalizationGain;

  /// Per-user state (play count, favorite, resume position, …).
  final JellyfinUserData? userData;

  /// Video/photo width in pixels.
  final int? width;

  /// Video/photo height in pixels.
  final int? height;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds an item from already-parsed components.
  const JellyfinItem({
    required this.id,
    required this.name,
    required this.albumArtists,
    required this.artists,
    required this.artistItems,
    this.albumArtistItems = const [],
    this.genreItems = const [],
    this.people = const [],
    this.playlistItemId,
    required this.mediaSources,
    required this.mediaStreams,
    required this.isFolder,
    required this.hasLyrics,
    required this.genres,
    required this.tags,
    required this.imageTags,
    required this.backdropImageTags,
    required this.imageBlurHashes,
    required this.raw,
    this.type,
    this.mediaType,
    this.collectionType,
    this.sortName,
    this.originalTitle,
    this.overview,
    this.parentId,
    this.seriesId,
    this.seriesName,
    this.seasonId,
    this.seasonName,
    this.albumId,
    this.album,
    this.albumArtist,
    this.indexNumber,
    this.parentIndexNumber,
    this.productionYear,
    this.premiereDate,
    this.dateCreated,
    this.runTimeTicks,
    this.container,
    this.childCount,
    this.recursiveItemCount,
    this.albumCount,
    this.songCount,
    this.artistCount,
    this.musicVideoCount,
    this.movieCount,
    this.seriesCount,
    this.episodeCount,
    this.trailerCount,
    this.programCount,
    this.albumPrimaryImageTag,
    this.primaryImageAspectRatio,
    this.normalizationGain,
    this.albumNormalizationGain,
    this.userData,
    this.width,
    this.height,
  });

  /// Decodes a `BaseItemDto` payload, lifting the subset of fields used by music
  /// apps and stashing the rest in [raw].
  factory JellyfinItem.fromJson(Map<String, Object?> json) {
    return JellyfinItem(
      id: asString(json['Id']) ?? '',
      name: asString(json['Name']) ?? '',
      type: asString(json['Type']),
      mediaType: asString(json['MediaType']),
      collectionType: asString(json['CollectionType']),
      sortName: asString(json['SortName']),
      originalTitle: asString(json['OriginalTitle']),
      overview: asString(json['Overview']),
      parentId: asString(json['ParentId']),
      seriesId: asString(json['SeriesId']),
      seriesName: asString(json['SeriesName']),
      seasonId: asString(json['SeasonId']),
      seasonName: asString(json['SeasonName']),
      albumId: asString(json['AlbumId']),
      album: asString(json['Album']),
      albumArtist: asString(json['AlbumArtist']),
      albumArtists: fieldStrings(json['AlbumArtists'], 'Name'),
      artists: asStringList(json['Artists']),
      artistItems:
          asObjectList(json['ArtistItems'], JellyfinArtistRef.fromJson),
      albumArtistItems:
          asObjectList(json['AlbumArtists'], JellyfinArtistRef.fromJson),
      genreItems:
          asObjectList(json['GenreItems'], JellyfinNameGuidPair.fromJson),
      playlistItemId: switch (asString(json['PlaylistItemId'])) {
        final String id => JellyfinPlaylistEntryId(id),
        null => null,
      },
      indexNumber: asInt(json['IndexNumber']),
      parentIndexNumber: asInt(json['ParentIndexNumber']),
      productionYear: asInt(json['ProductionYear']),
      premiereDate: asUtcDateTime(json['PremiereDate']),
      dateCreated: asUtcDateTime(json['DateCreated']),
      runTimeTicks: asInt(json['RunTimeTicks']),
      container: asString(json['Container']),
      mediaSources:
          asObjectList(json['MediaSources'], JellyfinMediaSource.fromJson),
      mediaStreams:
          asObjectList(json['MediaStreams'], JellyfinMediaStream.fromJson),
      isFolder: json['IsFolder'] == true,
      childCount: asInt(json['ChildCount']),
      recursiveItemCount: asInt(json['RecursiveItemCount']),
      albumCount: asInt(json['AlbumCount']),
      songCount: asInt(json['SongCount']),
      artistCount: asInt(json['ArtistCount']),
      musicVideoCount: asInt(json['MusicVideoCount']),
      movieCount: asInt(json['MovieCount']),
      seriesCount: asInt(json['SeriesCount']),
      episodeCount: asInt(json['EpisodeCount']),
      trailerCount: asInt(json['TrailerCount']),
      programCount: asInt(json['ProgramCount']),
      people: asObjectList(json['People'], JellyfinItemPerson.fromJson),
      hasLyrics: json['HasLyrics'] == true,
      genres: asStringList(json['Genres']),
      tags: asStringList(json['Tags']),
      imageTags: asStringMap(json['ImageTags']),
      backdropImageTags: asStringList(json['BackdropImageTags']),
      albumPrimaryImageTag: asString(json['AlbumPrimaryImageTag']),
      imageBlurHashes: _flattenBlurHashes(json['ImageBlurHashes']),
      primaryImageAspectRatio: asDouble(json['PrimaryImageAspectRatio']),
      normalizationGain: asDouble(json['NormalizationGain']),
      albumNormalizationGain: asDouble(json['AlbumNormalizationGain']),
      userData: json['UserData'] is Map<String, Object?>
          ? JellyfinUserData.fromJson(json['UserData'] as Map<String, Object?>)
          : null,
      width: asInt(json['Width']),
      height: asInt(json['Height']),
      raw: json,
    );
  }

  /// Duration in milliseconds, computed from [runTimeTicks].
  int? get durationMs =>
      runTimeTicks == null ? null : (runTimeTicks! / 10000).round();

  /// Shorthand for `userData?.isFavorite ?? false`.
  bool get isFavorite => userData?.isFavorite ?? false;

  /// `true` when this item plays as audio.
  bool get isAudio => mediaType == 'Audio' || type == JellyfinItemKind.audio;

  /// Tag of the item's own primary image (`ImageTags.Primary`), or `null`.
  String? get primaryImageTag => imageTags['Primary'];

  /// The id whose primary image is this item's cover: the item itself when
  /// it has one, else its album (a track without art of its own), else
  /// `null`.
  String? get artworkItemId => primaryImageTag != null
      ? id
      : albumPrimaryImageTag != null
          ? albumId
          : null;

  /// Version of the cover named by [artworkItemId]: the image tag Jellyfin
  /// recomputes whenever the picture changes. Put it in an artwork cache
  /// key — and pass it as `tag` to [JellyfinImagesApi.url] — so a cover
  /// replaced on the server is fetched again. Needs no `fields`: the
  /// server sends `ImageTags` and, on tracks, `AlbumPrimaryImageTag`
  /// unasked (verified on 12.0). With `enableImages: false` it leaves out
  /// `ImageTags` but still sends `AlbumPrimaryImageTag` (12.2), so a
  /// track's version stays and an album's is null.
  String? get artworkVersion => primaryImageTag ?? albumPrimaryImageTag;
}

/// Lightweight artist reference (`{Id, Name}`) used inside [JellyfinItem.artistItems].
final class JellyfinArtistRef {
  /// Artist id.
  final String id;

  /// Artist display name.
  final String name;

  /// Builds an artist reference from already-parsed components.
  const JellyfinArtistRef({required this.id, required this.name});

  /// Decodes a `{Id, Name}` artist reference.
  factory JellyfinArtistRef.fromJson(Map<String, Object?> json) =>
      JellyfinArtistRef(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']) ?? '',
      );
}

/// A person credited on a [JellyfinItem] (`BaseItemPerson`), from
/// [JellyfinItem.people].
final class JellyfinItemPerson {
  /// Person id — an artist's id for music credits.
  final String id;

  /// Display name.
  final String name;

  /// The part played, for actors; empty or null otherwise.
  final String? role;

  /// The credit's `PersonKind`: `'Actor'`, `'Director'`, `'Composer'`,
  /// `'Artist'`, `'AlbumArtist'`, `'Lyricist'`, … (the server's default
  /// is `'Unknown'`).
  final String? type;

  /// Tag of the person's primary image, or null when there is none.
  final String? primaryImageTag;

  /// Builds a person credit from already-parsed components.
  const JellyfinItemPerson({
    required this.id,
    required this.name,
    this.role,
    this.type,
    this.primaryImageTag,
  });

  /// Decodes a `{Name, Id, Role, Type, PrimaryImageTag}` entry.
  factory JellyfinItemPerson.fromJson(Map<String, Object?> json) =>
      JellyfinItemPerson(
        id: asString(json['Id']) ?? '',
        name: asString(json['Name']) ?? '',
        role: asString(json['Role']),
        type: asString(json['Type']),
        primaryImageTag: asString(json['PrimaryImageTag']),
      );
}

/// One playable variant of a [JellyfinItem] (`MediaSourceInfo`).
final class JellyfinMediaSource {
  /// Media source id; pass back to `/PlaybackInfo` and reporting endpoints.
  final String id;

  /// Server-local file path, when exposed by the server.
  final String? path;

  /// File container (e.g. `'mp4'`, `'mkv'`, `'flac'`).
  final String? container;

  /// Overall bitrate in bits per second.
  final int? bitrate;

  /// File size in bytes.
  final int? size;

  /// Duration in ticks (10_000 per millisecond).
  final int? runTimeTicks;

  /// `true` when the client may stream the file as-is.
  final bool supportsDirectPlay;

  /// `true` when the server can re-mux without re-encoding.
  final bool supportsDirectStream;

  /// `true` when the server is willing to transcode this source.
  final bool supportsTranscoding;

  /// Relative URL (HLS/DASH) for the transcoded stream, when applicable.
  final String? transcodingUrl;

  /// Transport protocol of the transcoded stream (`'hls'`, `'http'`, …).
  final String? transcodingSubProtocol;

  /// Container the transcoded stream is wrapped in.
  final String? transcodingContainer;

  /// Per-source media streams (audio/video/subtitle).
  final List<JellyfinMediaStream> mediaStreams;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a media source from already-parsed components.
  const JellyfinMediaSource({
    required this.id,
    required this.supportsDirectPlay,
    required this.supportsDirectStream,
    required this.supportsTranscoding,
    required this.mediaStreams,
    required this.raw,
    this.path,
    this.container,
    this.bitrate,
    this.size,
    this.runTimeTicks,
    this.transcodingUrl,
    this.transcodingSubProtocol,
    this.transcodingContainer,
  });

  /// Decodes a `MediaSourceInfo` payload.
  factory JellyfinMediaSource.fromJson(Map<String, Object?> json) =>
      JellyfinMediaSource(
        id: asString(json['Id']) ?? '',
        path: asString(json['Path']),
        container: asString(json['Container']),
        bitrate: asInt(json['Bitrate']),
        size: asInt(json['Size']),
        runTimeTicks: asInt(json['RunTimeTicks']),
        supportsDirectPlay: json['SupportsDirectPlay'] == true,
        supportsDirectStream: json['SupportsDirectStream'] == true,
        supportsTranscoding: json['SupportsTranscoding'] == true,
        transcodingUrl: asString(json['TranscodingUrl']),
        transcodingSubProtocol: asString(json['TranscodingSubProtocol']),
        transcodingContainer: asString(json['TranscodingContainer']),
        mediaStreams:
            asObjectList(json['MediaStreams'], JellyfinMediaStream.fromJson),
        raw: json,
      );
}

/// One audio/video/subtitle/lyrics stream inside a [JellyfinMediaSource].
final class JellyfinMediaStream {
  /// Zero-based stream index within the source.
  final int? index;

  /// `Audio | Video | Subtitle | EmbeddedImage | Data | Lyric`.
  final String? type;

  /// Codec name (`'h264'`, `'flac'`, `'opus'`, …).
  final String? codec;

  /// BCP-47 / ISO 639 language tag.
  final String? language;

  /// Channel count, for audio streams.
  final int? channels;

  /// Sample rate in Hz, for audio streams.
  final int? sampleRate;

  /// Stream bitrate in bits per second.
  final int? bitRate;

  /// Bit depth, for audio/video streams.
  final int? bitDepth;

  /// Server-side stream title.
  final String? title;

  /// `true` when the server marks this stream as the default for its type.
  final bool isDefault;

  /// Untouched response body for fields not lifted above.
  final Map<String, Object?> raw;

  /// Builds a media stream from already-parsed components.
  const JellyfinMediaStream({
    required this.raw,
    this.index,
    this.type,
    this.codec,
    this.language,
    this.channels,
    this.sampleRate,
    this.bitRate,
    this.bitDepth,
    this.title,
    this.isDefault = false,
  });

  /// Decodes a `MediaStream` payload.
  factory JellyfinMediaStream.fromJson(Map<String, Object?> json) =>
      JellyfinMediaStream(
        index: asInt(json['Index']),
        type: asString(json['Type']),
        codec: asString(json['Codec']),
        language: asString(json['Language']),
        channels: asInt(json['Channels']),
        sampleRate: asInt(json['SampleRate']),
        bitRate: asInt(json['BitRate']),
        bitDepth: asInt(json['BitDepth']),
        title: asString(json['Title']),
        isDefault: json['IsDefault'] == true,
        raw: json,
      );

  /// `true` when this stream carries audio.
  bool get isAudio => type == 'Audio';

  /// `true` when this stream carries video.
  bool get isVideo => type == 'Video';

  /// `true` when this stream carries subtitles.
  bool get isSubtitle => type == 'Subtitle';

  /// `true` when this stream carries lyrics (spec enum value `'Lyric'`).
  bool get isLyrics => type == 'Lyric';

  /// `true` when this stream is an embedded image (cover art).
  bool get isEmbeddedImage => type == 'EmbeddedImage';

  /// `true` when this stream carries auxiliary data.
  bool get isData => type == 'Data';
}

/// Per-user state attached to a [JellyfinItem] (`UserItemDataDto`).
final class JellyfinUserData {
  /// Resume position in ticks (10_000 per millisecond).
  final int? playbackPositionTicks;

  /// Number of completed plays.
  final int playCount;

  /// `true` when the user has favourited this item.
  final bool isFavorite;

  /// Tri-state thumb rating: `true` like, `false` dislike, `null` unrated.
  final bool? likes;

  /// Last time the user played this item, in UTC.
  final DateTime? lastPlayedDate;

  /// `true` when the user has marked this item as fully played.
  final bool played;

  /// Server-side key used by scrobbling integrations.
  final String? key;

  /// Builds a user-data record from already-parsed components.
  const JellyfinUserData({
    required this.playCount,
    required this.isFavorite,
    required this.played,
    this.playbackPositionTicks,
    this.likes,
    this.lastPlayedDate,
    this.key,
  });

  /// Decodes a `UserItemDataDto` payload.
  factory JellyfinUserData.fromJson(Map<String, Object?> json) =>
      JellyfinUserData(
        playbackPositionTicks: asInt(json['PlaybackPositionTicks']),
        playCount: asInt(json['PlayCount']) ?? 0,
        isFavorite: json['IsFavorite'] == true,
        likes: json['Likes'] is bool ? json['Likes'] as bool : null,
        lastPlayedDate: asUtcDateTime(json['LastPlayedDate']),
        played: json['Played'] == true,
        key: asString(json['Key']),
      );
}

/// `ImageBlurHashes` shape from server: `{ "Primary": { "<tag>": "<hash>" } }`.
/// We flatten to `{ "Primary": "<hash>" }` (first entry per type) since the
/// tag is already exposed in `ImageTags`.
Map<String, String> _flattenBlurHashes(Object? v) {
  if (v is! Map) return const {};
  final out = <String, String>{};
  v.forEach((typeKey, byTag) {
    if (typeKey is! String || byTag is! Map) return;
    for (final entry in byTag.entries) {
      if (entry.value is String) {
        out[typeKey] = entry.value as String;
        break;
      }
    }
  });
  return out;
}
