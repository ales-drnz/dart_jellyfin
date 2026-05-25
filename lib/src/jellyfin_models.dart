// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Plain immutable DTOs for the Jellyfin API.
///
/// Modelled directly on the OpenAPI spec at
/// <https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json> but
/// hand-rolled so the package stays codegen-free. Fields are added on
/// demand — [JellyfinItem.raw] keeps the full server payload around for
/// anything not yet lifted onto a typed property.
library;

// ---------------------------------------------------------------------------
// QueryResult — the standard `{Items, TotalRecordCount, StartIndex}` envelope
// ---------------------------------------------------------------------------

/// Paged `{Items, TotalRecordCount, StartIndex}` envelope returned by most
/// Jellyfin list endpoints.
class JellyfinQueryResult<T> {
  /// Parsed page of items.
  final List<T> items;

  /// Total matches across all pages on the server (not the size of [items]).
  final int totalRecordCount;

  /// Offset of this page within the full result set, when the server reports it.
  final int? startIndex;

  /// Builds an envelope from already-parsed components.
  const JellyfinQueryResult({
    required this.items,
    required this.totalRecordCount,
    this.startIndex,
  });

  /// Decodes the envelope, mapping each entry under [itemsKey] through [parser].
  ///
  /// [itemsKey] defaults to `'Items'`; pass a different key for endpoints that
  /// nest the list elsewhere (e.g. `'SearchHints'`).
  factory JellyfinQueryResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser, {
    String itemsKey = 'Items',
  }) {
    final raw = json[itemsKey];
    return JellyfinQueryResult<T>(
      items: [
        if (raw is List)
          for (final e in raw)
            if (e is Map<String, dynamic>) parser(e),
      ],
      totalRecordCount: _int(json['TotalRecordCount']) ??
          (raw is List ? raw.length : 0),
      startIndex: _int(json['StartIndex']),
    );
  }
}

// ---------------------------------------------------------------------------
// System info
// ---------------------------------------------------------------------------

/// Subset of `/System/Info` describing the remote server build.
class JellyfinSystemInfo {
  /// Stable server-side id.
  final String? id;

  /// Operator-configured display name.
  final String? serverName;

  /// Server build version (e.g. `'10.9.11'`).
  final String? version;

  /// Product brand string (typically `'Jellyfin Server'`).
  final String? productName;

  /// Host operating system identifier.
  final String? operatingSystem;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a system-info DTO from already-parsed components.
  const JellyfinSystemInfo({
    required this.raw,
    this.id,
    this.serverName,
    this.version,
    this.productName,
    this.operatingSystem,
  });

  /// Decodes the flat `/System/Info` payload.
  factory JellyfinSystemInfo.fromJson(Map<String, dynamic> json) =>
      JellyfinSystemInfo(
        id: _str(json['Id']),
        serverName: _str(json['ServerName']),
        version: _str(json['Version']),
        productName: _str(json['ProductName']),
        operatingSystem: _str(json['OperatingSystem']),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Users & authentication
// ---------------------------------------------------------------------------

/// One Jellyfin user account.
class JellyfinUser {
  /// Stable server-side user id (GUID).
  final String id;

  /// Display name shown in the login screen and headers.
  final String name;

  /// Id of the server this user belongs to.
  final String? serverId;

  /// Image tag for the user's avatar; combine with `/Users/{id}/Images/Primary`.
  final String? primaryImageTag;

  /// `true` when any password (incl. easy pin) is set.
  final bool hasPassword;

  /// `true` when a full password is configured.
  final bool hasConfiguredPassword;

  /// `true` when a numeric easy-password is configured.
  final bool hasConfiguredEasyPassword;

  /// Last successful login timestamp, in UTC.
  final DateTime? lastLoginDate;

  /// Last activity timestamp, in UTC.
  final DateTime? lastActivityDate;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a user DTO from already-parsed components.
  const JellyfinUser({
    required this.id,
    required this.name,
    required this.hasPassword,
    required this.hasConfiguredPassword,
    required this.hasConfiguredEasyPassword,
    required this.raw,
    this.serverId,
    this.primaryImageTag,
    this.lastLoginDate,
    this.lastActivityDate,
  });

  /// Decodes a `/Users/{id}` (or `/Users/Me`) payload.
  factory JellyfinUser.fromJson(Map<String, dynamic> json) => JellyfinUser(
        id: _str(json['Id']) ?? '',
        name: _str(json['Name']) ?? '',
        serverId: _str(json['ServerId']),
        primaryImageTag: _str(json['PrimaryImageTag']),
        hasPassword: json['HasPassword'] == true,
        hasConfiguredPassword: json['HasConfiguredPassword'] == true,
        hasConfiguredEasyPassword:
            json['HasConfiguredEasyPassword'] == true,
        lastLoginDate: _dt(json['LastLoginDate']),
        lastActivityDate: _dt(json['LastActivityDate']),
        raw: json,
      );
}

/// Result of `POST /Users/AuthenticateByName` (and Quick Connect).
class JellyfinAuthResult {
  /// Authenticated user record.
  final JellyfinUser user;

  /// Bearer token to set in the `X-Emby-Token` / `Authorization` header.
  final String accessToken;

  /// Id of the server that issued the token.
  final String serverId;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds an auth result from already-parsed components.
  const JellyfinAuthResult({
    required this.user,
    required this.accessToken,
    required this.serverId,
    required this.raw,
  });

  /// Decodes the envelope `{User, AccessToken, ServerId}`. A missing `User`
  /// is tolerated and replaced with a blank [JellyfinUser].
  factory JellyfinAuthResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['User'];
    return JellyfinAuthResult(
      user: userJson is Map<String, dynamic>
          ? JellyfinUser.fromJson(userJson)
          : const JellyfinUser(
              id: '',
              name: '',
              hasPassword: false,
              hasConfiguredPassword: false,
              hasConfiguredEasyPassword: false,
              raw: <String, dynamic>{},
            ),
      accessToken: _str(json['AccessToken']) ?? '',
      serverId: _str(json['ServerId']) ?? '',
      raw: json,
    );
  }
}

/// Result of `POST /QuickConnect/Initiate` and `GET /QuickConnect/Connect`.
class JellyfinQuickConnectState {
  /// `true` once the user has approved the pairing on another device.
  final bool authenticated;

  /// Opaque secret used to poll `/QuickConnect/Connect`.
  final String secret;

  /// Short human-readable code displayed to the user for approval.
  final String code;

  /// Initiating device id, as supplied by this client.
  final String? deviceId;

  /// Initiating device display name.
  final String? deviceName;

  /// Initiating application name.
  final String? appName;

  /// Initiating application version.
  final String? appVersion;

  /// Timestamp when the pairing request was created, in UTC.
  final DateTime? dateAdded;

  /// Builds a quick-connect state from already-parsed components.
  const JellyfinQuickConnectState({
    required this.authenticated,
    required this.secret,
    required this.code,
    this.deviceId,
    this.deviceName,
    this.appName,
    this.appVersion,
    this.dateAdded,
  });

  /// Decodes a flat quick-connect state payload.
  factory JellyfinQuickConnectState.fromJson(Map<String, dynamic> json) =>
      JellyfinQuickConnectState(
        authenticated: json['Authenticated'] == true,
        secret: _str(json['Secret']) ?? '',
        code: _str(json['Code']) ?? '',
        deviceId: _str(json['DeviceId']),
        deviceName: _str(json['DeviceName']),
        appName: _str(json['AppName']),
        appVersion: _str(json['AppVersion']),
        dateAdded: _dt(json['DateAdded']),
      );
}

// ---------------------------------------------------------------------------
// User views (library collections)
// ---------------------------------------------------------------------------

/// Jellyfin's "library" abstraction — what `/UserViews` returns.
///
/// `collectionType` is what tells you the library kind:
/// `'movies' | 'tvshows' | 'music' | 'musicvideos' | 'photos' | 'books' |
///  'livetv' | 'homevideos' | 'boxsets' | 'playlists' | 'folders' | null`.
class JellyfinView {
  /// Stable server-side library id.
  final String id;

  /// Library display name.
  final String name;

  /// Library kind (`'music'`, `'movies'`, …); see class doc for full set.
  final String? collectionType;

  /// Image tag for the library's `Primary` poster.
  final String? primaryImageTag;

  /// Id of the server this library lives on.
  final String? serverId;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a view from already-parsed components.
  const JellyfinView({
    required this.id,
    required this.name,
    required this.raw,
    this.collectionType,
    this.primaryImageTag,
    this.serverId,
  });

  /// Decodes a `/UserViews` entry, flattening `ImageTags.Primary` for convenience.
  factory JellyfinView.fromJson(Map<String, dynamic> json) {
    final tags = json['ImageTags'];
    return JellyfinView(
      id: _str(json['Id']) ?? '',
      name: _str(json['Name']) ?? '',
      collectionType: _str(json['CollectionType']),
      primaryImageTag: tags is Map ? _str(tags['Primary']) : null,
      serverId: _str(json['ServerId']),
      raw: json,
    );
  }

  /// `true` when this view holds music.
  bool get isMusic => collectionType == 'music';

  /// `true` when this view holds movies.
  bool get isMovies => collectionType == 'movies';

  /// `true` when this view holds TV shows.
  bool get isTvShows => collectionType == 'tvshows';

  /// `true` when this view holds photos.
  bool get isPhotos => collectionType == 'photos';
}

// ---------------------------------------------------------------------------
// Items (BaseItemDto subset)
// ---------------------------------------------------------------------------

/// Item kinds we recognise (a subset of the OpenAPI `BaseItemKind` enum).
/// Strings match the wire values used in `Type` and `IncludeItemTypes`.
abstract final class JellyfinItemKind {
  /// A single audio track.
  static const audio = 'Audio';

  /// An audiobook track or container.
  static const audioBook = 'AudioBook';

  /// A music album.
  static const musicAlbum = 'MusicAlbum';

  /// A music artist.
  static const musicArtist = 'MusicArtist';

  /// A music genre.
  static const musicGenre = 'MusicGenre';

  /// A music video.
  static const musicVideo = 'MusicVideo';

  /// A user-created playlist.
  static const playlist = 'Playlist';

  /// A movie.
  static const movie = 'Movie';

  /// A TV series.
  static const series = 'Series';

  /// A TV season.
  static const season = 'Season';

  /// A single TV episode.
  static const episode = 'Episode';

  /// A photo.
  static const photo = 'Photo';

  /// A photo album.
  static const photoAlbum = 'PhotoAlbum';

  /// A generic folder.
  static const folder = 'Folder';

  /// A top-level library folder.
  static const collectionFolder = 'CollectionFolder';

  /// A per-user view (library facade).
  static const userView = 'UserView';

  /// A generic (non-music) genre.
  static const genre = 'Genre';

  /// A person (actor, director, …).
  static const person = 'Person';

  /// A studio.
  static const studio = 'Studio';

  /// A book.
  static const book = 'Book';
}

/// Subset of `BaseItemDto`. Hand-rolled — the full DTO has 153 fields,
/// here we lift only what music apps use today. Anything else lives in
/// [JellyfinItem.raw].
class JellyfinItem {
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

  /// Per-user state (play count, favorite, resume position, …).
  final JellyfinUserData? userData;

  /// Video/photo width in pixels.
  final int? width;

  /// Video/photo height in pixels.
  final int? height;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds an item from already-parsed components.
  const JellyfinItem({
    required this.id,
    required this.name,
    required this.albumArtists,
    required this.artists,
    required this.artistItems,
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
    this.albumPrimaryImageTag,
    this.primaryImageAspectRatio,
    this.userData,
    this.width,
    this.height,
  });

  /// Decodes a `BaseItemDto` payload, lifting the subset of fields used by music
  /// apps and stashing the rest in [raw].
  factory JellyfinItem.fromJson(Map<String, dynamic> json) {
    return JellyfinItem(
      id: _str(json['Id']) ?? '',
      name: _str(json['Name']) ?? '',
      type: _str(json['Type']),
      mediaType: _str(json['MediaType']),
      collectionType: _str(json['CollectionType']),
      sortName: _str(json['SortName']),
      originalTitle: _str(json['OriginalTitle']),
      overview: _str(json['Overview']),
      parentId: _str(json['ParentId']),
      seriesId: _str(json['SeriesId']),
      seriesName: _str(json['SeriesName']),
      seasonId: _str(json['SeasonId']),
      seasonName: _str(json['SeasonName']),
      albumId: _str(json['AlbumId']),
      album: _str(json['Album']),
      albumArtist: _str(json['AlbumArtist']),
      albumArtists: _stringList(json['AlbumArtists'], 'Name'),
      artists: _strList(json['Artists']),
      artistItems: [
        if (json['ArtistItems'] is List)
          for (final a in json['ArtistItems'] as List)
            if (a is Map<String, dynamic>) JellyfinArtistRef.fromJson(a),
      ],
      indexNumber: _int(json['IndexNumber']),
      parentIndexNumber: _int(json['ParentIndexNumber']),
      productionYear: _int(json['ProductionYear']),
      premiereDate: _dt(json['PremiereDate']),
      dateCreated: _dt(json['DateCreated']),
      runTimeTicks: _int(json['RunTimeTicks']),
      container: _str(json['Container']),
      mediaSources: [
        if (json['MediaSources'] is List)
          for (final m in json['MediaSources'] as List)
            if (m is Map<String, dynamic>) JellyfinMediaSource.fromJson(m),
      ],
      mediaStreams: [
        if (json['MediaStreams'] is List)
          for (final s in json['MediaStreams'] as List)
            if (s is Map<String, dynamic>) JellyfinMediaStream.fromJson(s),
      ],
      isFolder: json['IsFolder'] == true,
      childCount: _int(json['ChildCount']),
      hasLyrics: json['HasLyrics'] == true,
      genres: _strList(json['Genres']),
      tags: _strList(json['Tags']),
      imageTags: _stringMap(json['ImageTags']),
      backdropImageTags: _strList(json['BackdropImageTags']),
      albumPrimaryImageTag: _str(json['AlbumPrimaryImageTag']),
      imageBlurHashes: _flattenBlurHashes(json['ImageBlurHashes']),
      primaryImageAspectRatio: _double(json['PrimaryImageAspectRatio']),
      userData: json['UserData'] is Map<String, dynamic>
          ? JellyfinUserData.fromJson(json['UserData'] as Map<String, dynamic>)
          : null,
      width: _int(json['Width']),
      height: _int(json['Height']),
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
}

/// Lightweight artist reference (`{Id, Name}`) used inside [JellyfinItem.artistItems].
class JellyfinArtistRef {
  /// Artist id.
  final String id;

  /// Artist display name.
  final String name;

  /// Builds an artist reference from already-parsed components.
  const JellyfinArtistRef({required this.id, required this.name});

  /// Decodes a `{Id, Name}` artist reference.
  factory JellyfinArtistRef.fromJson(Map<String, dynamic> json) => JellyfinArtistRef(
        id: _str(json['Id']) ?? '',
        name: _str(json['Name']) ?? '',
      );
}

/// One playable variant of a [JellyfinItem] (`MediaSourceInfo`).
class JellyfinMediaSource {
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
  final Map<String, dynamic> raw;

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
  factory JellyfinMediaSource.fromJson(Map<String, dynamic> json) =>
      JellyfinMediaSource(
        id: _str(json['Id']) ?? '',
        path: _str(json['Path']),
        container: _str(json['Container']),
        bitrate: _int(json['Bitrate']),
        size: _int(json['Size']),
        runTimeTicks: _int(json['RunTimeTicks']),
        supportsDirectPlay: json['SupportsDirectPlay'] == true,
        supportsDirectStream: json['SupportsDirectStream'] == true,
        supportsTranscoding: json['SupportsTranscoding'] == true,
        transcodingUrl: _str(json['TranscodingUrl']),
        transcodingSubProtocol: _str(json['TranscodingSubProtocol']),
        transcodingContainer: _str(json['TranscodingContainer']),
        mediaStreams: [
          if (json['MediaStreams'] is List)
            for (final s in json['MediaStreams'] as List)
              if (s is Map<String, dynamic>) JellyfinMediaStream.fromJson(s),
        ],
        raw: json,
      );
}

/// One audio/video/subtitle/lyrics stream inside a [JellyfinMediaSource].
class JellyfinMediaStream {
  /// Zero-based stream index within the source.
  final int? index;

  /// `Audio | Video | Subtitle | Lyrics | EmbeddedImage`.
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
  final Map<String, dynamic> raw;

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
  factory JellyfinMediaStream.fromJson(Map<String, dynamic> json) =>
      JellyfinMediaStream(
        index: _int(json['Index']),
        type: _str(json['Type']),
        codec: _str(json['Codec']),
        language: _str(json['Language']),
        channels: _int(json['Channels']),
        sampleRate: _int(json['SampleRate']),
        bitRate: _int(json['BitRate']),
        bitDepth: _int(json['BitDepth']),
        title: _str(json['Title']),
        isDefault: json['IsDefault'] == true,
        raw: json,
      );

  /// `true` when this stream carries audio.
  bool get isAudio => type == 'Audio';

  /// `true` when this stream carries video.
  bool get isVideo => type == 'Video';

  /// `true` when this stream carries subtitles.
  bool get isSubtitle => type == 'Subtitle';

  /// `true` when this stream carries lyrics.
  bool get isLyrics => type == 'Lyrics';
}

/// Per-user state attached to a [JellyfinItem] (`UserItemDataDto`).
class JellyfinUserData {
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
  factory JellyfinUserData.fromJson(Map<String, dynamic> json) =>
      JellyfinUserData(
        playbackPositionTicks: _int(json['PlaybackPositionTicks']),
        playCount: _int(json['PlayCount']) ?? 0,
        isFavorite: json['IsFavorite'] == true,
        likes: json['Likes'] is bool ? json['Likes'] as bool : null,
        lastPlayedDate: _dt(json['LastPlayedDate']),
        played: json['Played'] == true,
        key: _str(json['Key']),
      );
}

// ---------------------------------------------------------------------------
// Lyrics
// ---------------------------------------------------------------------------

/// One synced line in a Jellyfin lyrics payload — `Start` is in 100-ns
/// ticks (so divide by 10000 for milliseconds, or by 10_000_000 for
/// seconds).
class JellyfinLyricLine {
  /// Start time in 100-ns ticks; `null` for unsynced lines.
  final int? startTicks;

  /// Line text.
  final String text;

  /// Builds a lyric line from already-parsed components.
  const JellyfinLyricLine({required this.text, this.startTicks});

  /// Decodes a `{Start, Text}` lyrics entry.
  factory JellyfinLyricLine.fromJson(Map<String, dynamic> json) =>
      JellyfinLyricLine(
        startTicks: _int(json['Start']),
        text: _str(json['Text']) ?? '',
      );

  /// Convert to a single LRC line `[mm:ss.xx]text`, or just `text` if no
  /// timestamp is present.
  String toLrcLine() {
    final ticks = startTicks;
    if (ticks == null) return text;
    final ms = (ticks / 10000).round();
    final totalSec = ms ~/ 1000;
    final cs = (ms - totalSec * 1000) ~/ 10;
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    final c = cs.toString().padLeft(2, '0');
    return '[$m:$s.$c]$text';
  }
}

/// Payload of `GET /Audio/{id}/Lyrics`.
class JellyfinLyrics {
  /// Parsed lyric lines, in display order.
  final List<JellyfinLyricLine> lines;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a lyrics payload from already-parsed components.
  const JellyfinLyrics({required this.lines, required this.raw});

  /// Decodes `{Lyrics: [...]}`. Tolerates missing or non-list `Lyrics`.
  factory JellyfinLyrics.fromJson(Map<String, dynamic> json) {
    final ly = json['Lyrics'];
    return JellyfinLyrics(
      lines: [
        if (ly is List)
          for (final l in ly)
            if (l is Map<String, dynamic>) JellyfinLyricLine.fromJson(l),
      ],
      raw: json,
    );
  }

  /// `true` when at least one line carries a timestamp.
  bool get isSynced => lines.any((l) => l.startTicks != null);

  /// Render as an LRC document, suitable for any synced-lyrics player.
  String toLrc() => lines.map((l) => l.toLrcLine()).join('\n');

  /// Render as plain text (one line per entry, timestamps dropped).
  String toPlainText() => lines.map((l) => l.text).join('\n');
}

// ---------------------------------------------------------------------------
// Search hints
// ---------------------------------------------------------------------------

/// One match from `/Search/Hints` — a lightweight pointer into the library.
class JellyfinSearchHint {
  /// Id of the matched item.
  final String itemId;

  /// Display name of the matched item.
  final String? name;

  /// Substring of the query that triggered the match, when reported.
  final String? matchedTerm;

  /// `BaseItemKind` of the matched item.
  final String? type;

  /// `MediaType` of the matched item.
  final String? mediaType;

  /// Album-artist string, for audio hits.
  final String? albumArtist;

  /// All artist names, for audio hits.
  final List<String> artists;

  /// Duration in ticks (10_000 per millisecond).
  final int? runTimeTicks;

  /// Track/episode number within the parent, when applicable.
  final int? indexNumber;

  /// Release year, when applicable.
  final int? productionYear;

  /// Image tag for the `Primary` image.
  final String? primaryImageTag;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a search hint from already-parsed components.
  const JellyfinSearchHint({
    required this.itemId,
    required this.artists,
    required this.raw,
    this.name,
    this.matchedTerm,
    this.type,
    this.mediaType,
    this.albumArtist,
    this.runTimeTicks,
    this.indexNumber,
    this.productionYear,
    this.primaryImageTag,
  });

  /// Decodes a search-hint entry; accepts both `Id` and legacy `ItemId` keys.
  factory JellyfinSearchHint.fromJson(Map<String, dynamic> json) =>
      JellyfinSearchHint(
        itemId: _str(json['Id']) ?? _str(json['ItemId']) ?? '',
        name: _str(json['Name']),
        matchedTerm: _str(json['MatchedTerm']),
        type: _str(json['Type']),
        mediaType: _str(json['MediaType']),
        albumArtist: _str(json['AlbumArtist']),
        artists: _strList(json['Artists']),
        runTimeTicks: _int(json['RunTimeTicks']),
        indexNumber: _int(json['IndexNumber']),
        productionYear: _int(json['ProductionYear']),
        primaryImageTag: _str(json['PrimaryImageTag']),
        raw: json,
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _str(Object? v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

int? _int(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _double(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v)?.toUtc();
  return null;
}

List<String> _strList(Object? v) {
  if (v is! List) return const [];
  return [for (final e in v) if (e is String) e];
}

List<String> _stringList(Object? v, String fieldName) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is Map<String, dynamic> && e[fieldName] is String) e[fieldName] as String,
  ];
}

Map<String, String> _stringMap(Object? v) {
  if (v is! Map) return const {};
  final out = <String, String>{};
  v.forEach((k, val) {
    if (k is String && val is String) out[k] = val;
  });
  return out;
}

// ---------------------------------------------------------------------------
// Sessions (now playing / remote control)
// ---------------------------------------------------------------------------

/// One entry from `GET /Sessions`. The server reports every active
/// client (Jellyfin Web, Jellyfin Mobile, Jellyfin Media Player, …)
/// along with what it's currently playing.
///
/// Use [JellyfinSessionsApi.play] etc. with [JellyfinSession.id] to
/// cast or remote-control a target.
class JellyfinSession {
  /// Stable session id; pass to `/Sessions/{id}/...` endpoints.
  final String id;

  /// Id of the user this session is signed in as.
  final String? userId;

  /// Display name of the signed-in user.
  final String? userName;

  /// Client application name (`'Jellyfin Web'`, `'Finova'`, …).
  final String? client;

  /// Client-supplied device id.
  final String? deviceId;

  /// Client-supplied device display name.
  final String? deviceName;

  /// Client application version.
  final String? applicationVersion;

  /// Client's reported remote IP/host.
  final String? remoteEndPoint;

  /// Last activity timestamp from the client, in UTC.
  final DateTime? lastActivityDate;

  /// Last playback check-in timestamp, in UTC.
  final DateTime? lastPlaybackCheckIn;

  /// `true` when the server still considers the session live.
  final bool isActive;

  /// `true` when the client accepts play/pause/seek commands.
  final bool supportsMediaControl;

  /// `true` when the client accepts arbitrary remote-control commands.
  final bool supportsRemoteControl;

  /// `MediaType` strings the client can play (`'Audio'`, `'Video'`, …).
  final List<String> playableMediaTypes;

  /// `GeneralCommandType` names the client advertises support for.
  final List<String> supportedCommands;

  /// `NowPlayingItem` parsed as a [JellyfinItem]. Null when the session
  /// isn't playing anything.
  final JellyfinItem? nowPlayingItem;

  /// `PlayState` — `PositionTicks`, `IsPaused`, `IsMuted`, `VolumeLevel`,
  /// `AudioStreamIndex`, `SubtitleStreamIndex`, `PlayMethod`,
  /// `RepeatMode`, `PlaybackOrder`.
  final Map<String, dynamic>? playState;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a session from already-parsed components.
  const JellyfinSession({
    required this.id,
    required this.isActive,
    required this.supportsMediaControl,
    required this.supportsRemoteControl,
    required this.playableMediaTypes,
    required this.supportedCommands,
    required this.raw,
    this.userId,
    this.userName,
    this.client,
    this.deviceId,
    this.deviceName,
    this.applicationVersion,
    this.remoteEndPoint,
    this.lastActivityDate,
    this.lastPlaybackCheckIn,
    this.nowPlayingItem,
    this.playState,
  });

  /// Decodes a `/Sessions` entry, recursing into `NowPlayingItem` when present.
  factory JellyfinSession.fromJson(Map<String, dynamic> json) {
    final npi = json['NowPlayingItem'];
    return JellyfinSession(
      id: _str(json['Id']) ?? '',
      userId: _str(json['UserId']),
      userName: _str(json['UserName']),
      client: _str(json['Client']),
      deviceId: _str(json['DeviceId']),
      deviceName: _str(json['DeviceName']),
      applicationVersion: _str(json['ApplicationVersion']),
      remoteEndPoint: _str(json['RemoteEndPoint']),
      lastActivityDate: _dt(json['LastActivityDate']),
      lastPlaybackCheckIn: _dt(json['LastPlaybackCheckIn']),
      isActive: json['IsActive'] == true,
      supportsMediaControl: json['SupportsMediaControl'] == true,
      supportsRemoteControl: json['SupportsRemoteControl'] == true,
      playableMediaTypes: _strList(json['PlayableMediaTypes']),
      supportedCommands: _strList(json['SupportedCommands']),
      nowPlayingItem: npi is Map<String, dynamic>
          ? JellyfinItem.fromJson(npi)
          : null,
      playState: json['PlayState'] is Map<String, dynamic>
          ? json['PlayState'] as Map<String, dynamic>
          : null,
      raw: json,
    );
  }

  /// `true` when this session is actively playing media.
  bool get isPlaying => nowPlayingItem != null;
}

// ---------------------------------------------------------------------------
// Playback info / device profile
// ---------------------------------------------------------------------------

/// Result of `GET/POST /Items/{itemId}/PlaybackInfo`.
///
/// `mediaSources` carries the server's decision for each source: which
/// of [JellyfinMediaSource.supportsDirectPlay],
/// [JellyfinMediaSource.supportsDirectStream], or
/// [JellyfinMediaSource.supportsTranscoding] is `true`, plus a
/// [JellyfinMediaSource.transcodingUrl] when transcoding is required.
class JellyfinPlaybackInfo {
  /// Media sources annotated with the server's per-source playback decision.
  final List<JellyfinMediaSource> mediaSources;

  /// Token to thread through `/Playing/...` reporting and stop calls.
  final String? playSessionId;

  /// Server-reported failure code, when playback can't be started.
  final String? errorCode;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a playback-info DTO from already-parsed components.
  const JellyfinPlaybackInfo({
    required this.mediaSources,
    required this.raw,
    this.playSessionId,
    this.errorCode,
  });

  /// Decodes the `PlaybackInfoResponse` envelope.
  factory JellyfinPlaybackInfo.fromJson(Map<String, dynamic> json) =>
      JellyfinPlaybackInfo(
        mediaSources: [
          if (json['MediaSources'] is List)
            for (final m in json['MediaSources'] as List)
              if (m is Map<String, dynamic>) JellyfinMediaSource.fromJson(m),
        ],
        playSessionId: _str(json['PlaySessionId']),
        errorCode: _str(json['ErrorCode']),
        raw: json,
      );
}

/// Subset of `DeviceProfile` from the OpenAPI spec — enough to tell
/// the server "I can decode these containers, codecs, and bitrates,
/// transcode anything else".
///
/// The full DTO has ~30 sub-types (CodecProfile, ContainerProfile,
/// DirectPlayProfile, TranscodingProfile, …). For ergonomic
/// hand-rolled use we expose the high-level knobs plus an `extra`
/// escape hatch — fields you set there are merged into the JSON body
/// verbatim.
class JellyfinDeviceProfile {
  /// Human-readable name (`'Finova'`, etc).
  final String? name;

  /// Hard upper limit on streamed bitrate. Applies to both transcoded
  /// and direct-played sources.
  final int? maxStreamingBitrate;

  /// Hard upper limit on a static (download) bitrate.
  final int? maxStaticBitrate;

  /// Music-only bitrate ceiling.
  final int? musicStreamingTranscodingBitrate;

  /// Containers the client can direct-play (e.g. `['mp4', 'mkv',
  /// 'webm', 'mp3', 'aac', 'flac']`). The server skips transcoding if
  /// the source matches one of these AND the codecs inside are also
  /// supported.
  final List<String> directPlayProfiles;

  /// Containers + codecs the server should re-mux into when direct
  /// play isn't possible but transcoding would be wasteful.
  final List<Map<String, dynamic>> transcodingProfiles;

  /// Codec-level constraints (e.g. "h264 up to profile high@4.0").
  final List<Map<String, dynamic>> codecProfiles;

  /// Container-level constraints.
  final List<Map<String, dynamic>> containerProfiles;

  /// Subtitle profiles (formats the player understands and which
  /// methods — Embed/Encode/External — it prefers).
  final List<Map<String, dynamic>> subtitleProfiles;

  /// Anything else not promoted to a typed field. Merged verbatim
  /// into the outgoing JSON.
  final Map<String, dynamic> extra;

  /// Builds a device profile from already-parsed components.
  const JellyfinDeviceProfile({
    this.name,
    this.maxStreamingBitrate,
    this.maxStaticBitrate,
    this.musicStreamingTranscodingBitrate,
    this.directPlayProfiles = const [],
    this.transcodingProfiles = const [],
    this.codecProfiles = const [],
    this.containerProfiles = const [],
    this.subtitleProfiles = const [],
    this.extra = const {},
  });

  /// JSON body accepted by `/Items/{id}/PlaybackInfo` and friends. Empty
  /// fields are omitted; [extra] is merged in at the top level.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'Name': name,
      if (maxStreamingBitrate != null)
        'MaxStreamingBitrate': maxStreamingBitrate,
      if (maxStaticBitrate != null) 'MaxStaticBitrate': maxStaticBitrate,
      if (musicStreamingTranscodingBitrate != null)
        'MusicStreamingTranscodingBitrate':
            musicStreamingTranscodingBitrate,
      if (directPlayProfiles.isNotEmpty)
        'DirectPlayProfiles': [
          for (final container in directPlayProfiles)
            {'Container': container, 'Type': 'Video'},
        ],
      if (transcodingProfiles.isNotEmpty)
        'TranscodingProfiles': transcodingProfiles,
      if (codecProfiles.isNotEmpty) 'CodecProfiles': codecProfiles,
      if (containerProfiles.isNotEmpty)
        'ContainerProfiles': containerProfiles,
      if (subtitleProfiles.isNotEmpty)
        'SubtitleProfiles': subtitleProfiles,
      ...extra,
    };
  }
}

// ---------------------------------------------------------------------------
// Display preferences (`/DisplayPreferences/{id}`)
// ---------------------------------------------------------------------------

/// Per-client UI state stored on the server: view type, sort, scroll
/// direction, sidebar visibility, plus a free-form `customPrefs` map.
class JellyfinDisplayPreferences {
  /// Display-preferences id; usually the view/library id.
  final String? id;

  /// Client identifier that owns these preferences.
  final String? client;

  /// View layout (`'Poster'`, `'List'`, …).
  final String? viewType;

  /// Sort key (`'SortName'`, `'DateCreated'`, …).
  final String? sortBy;

  /// `'Ascending'` or `'Descending'`.
  final String? sortOrder;

  /// Indexing key for grouped views.
  final String? indexBy;

  /// `'Horizontal'` or `'Vertical'`.
  final String? scrollDirection;

  /// Whether the client should reuse the saved indexing across sessions.
  final bool? rememberIndexing;

  /// Whether the client should reuse the saved sort across sessions.
  final bool? rememberSorting;

  /// Whether to draw the item backdrop behind the view.
  final bool? showBackdrop;

  /// Whether to show the sidebar in this view.
  final bool? showSidebar;

  /// Primary-image render height in pixels.
  final int? primaryImageHeight;

  /// Primary-image render width in pixels.
  final int? primaryImageWidth;

  /// Free-form per-client key/value preferences.
  final Map<String, String> customPrefs;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a display-preferences DTO from already-parsed components.
  const JellyfinDisplayPreferences({
    this.id,
    this.client,
    this.viewType,
    this.sortBy,
    this.sortOrder,
    this.indexBy,
    this.scrollDirection,
    this.rememberIndexing,
    this.rememberSorting,
    this.showBackdrop,
    this.showSidebar,
    this.primaryImageHeight,
    this.primaryImageWidth,
    this.customPrefs = const {},
    this.raw = const {},
  });

  /// Decodes a `/DisplayPreferences/{id}` payload.
  factory JellyfinDisplayPreferences.fromJson(Map<String, dynamic> json) {
    final cp = json['CustomPrefs'];
    return JellyfinDisplayPreferences(
      id: _str(json['Id']),
      client: _str(json['Client']),
      viewType: _str(json['ViewType']),
      sortBy: _str(json['SortBy']),
      sortOrder: _str(json['SortOrder']),
      indexBy: _str(json['IndexBy']),
      scrollDirection: _str(json['ScrollDirection']),
      rememberIndexing: json['RememberIndexing'] is bool
          ? json['RememberIndexing'] as bool
          : null,
      rememberSorting: json['RememberSorting'] is bool
          ? json['RememberSorting'] as bool
          : null,
      showBackdrop:
          json['ShowBackdrop'] is bool ? json['ShowBackdrop'] as bool : null,
      showSidebar:
          json['ShowSidebar'] is bool ? json['ShowSidebar'] as bool : null,
      primaryImageHeight: _int(json['PrimaryImageHeight']),
      primaryImageWidth: _int(json['PrimaryImageWidth']),
      customPrefs: cp is Map ? _stringMap(cp) : const {},
      raw: json,
    );
  }

  /// JSON shape accepted by `POST /DisplayPreferences/{id}`.
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'Id': id,
        if (client != null) 'Client': client,
        if (viewType != null) 'ViewType': viewType,
        if (sortBy != null) 'SortBy': sortBy,
        if (sortOrder != null) 'SortOrder': sortOrder,
        if (indexBy != null) 'IndexBy': indexBy,
        if (scrollDirection != null) 'ScrollDirection': scrollDirection,
        if (rememberIndexing != null) 'RememberIndexing': rememberIndexing,
        if (rememberSorting != null) 'RememberSorting': rememberSorting,
        if (showBackdrop != null) 'ShowBackdrop': showBackdrop,
        if (showSidebar != null) 'ShowSidebar': showSidebar,
        if (primaryImageHeight != null)
          'PrimaryImageHeight': primaryImageHeight,
        if (primaryImageWidth != null)
          'PrimaryImageWidth': primaryImageWidth,
        if (customPrefs.isNotEmpty) 'CustomPrefs': customPrefs,
      };
}

// ---------------------------------------------------------------------------
// Query filters (`/Items/Filters` and `/Items/Filters2`)
// ---------------------------------------------------------------------------

/// `{Name, Id}` pair used in faceted filter responses.
class JellyfinNameGuidPair {
  /// Display name.
  final String? name;

  /// Stable server-side id.
  final String? id;

  /// Builds a name/id pair from already-parsed components.
  const JellyfinNameGuidPair({this.name, this.id});

  /// Decodes a `{Name, Id}` entry.
  factory JellyfinNameGuidPair.fromJson(Map<String, dynamic> json) =>
      JellyfinNameGuidPair(
        name: _str(json['Name']),
        id: _str(json['Id']),
      );
}

/// Modern facet response from `/Items/Filters2` — genres carry ids so
/// the client can filter back through `items.list(genreIds: …)`.
class JellyfinQueryFilters {
  /// Genres available in the queried scope, each with a filterable id.
  final List<JellyfinNameGuidPair> genres;

  /// Tag strings available in the queried scope.
  final List<String> tags;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a filters facet from already-parsed components.
  const JellyfinQueryFilters({
    this.genres = const [],
    this.tags = const [],
    this.raw = const {},
  });

  /// Decodes a `/Items/Filters2` response.
  factory JellyfinQueryFilters.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['Genres'];
    return JellyfinQueryFilters(
      genres: [
        if (rawGenres is List)
          for (final e in rawGenres)
            if (e is Map<String, dynamic>) JellyfinNameGuidPair.fromJson(e),
      ],
      tags: _strList(json['Tags']),
      raw: json,
    );
  }
}

/// Legacy facet response from `/Items/Filters` — flat string arrays.
class JellyfinQueryFiltersLegacy {
  /// Genre names available in the queried scope.
  final List<String> genres;

  /// Tag strings available in the queried scope.
  final List<String> tags;

  /// Distinct official ratings (`'PG-13'`, `'TV-MA'`, …) in scope.
  final List<String> officialRatings;

  /// Distinct release years in scope.
  final List<int> years;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a legacy filters facet from already-parsed components.
  const JellyfinQueryFiltersLegacy({
    this.genres = const [],
    this.tags = const [],
    this.officialRatings = const [],
    this.years = const [],
    this.raw = const {},
  });

  /// Decodes a `/Items/Filters` response.
  factory JellyfinQueryFiltersLegacy.fromJson(Map<String, dynamic> json) {
    final rawYears = json['Years'];
    return JellyfinQueryFiltersLegacy(
      genres: _strList(json['Genres']),
      tags: _strList(json['Tags']),
      officialRatings: _strList(json['OfficialRatings']),
      years: [
        if (rawYears is List)
          for (final e in rawYears)
            if (_int(e) != null) _int(e)!,
      ],
      raw: json,
    );
  }
}

// ---------------------------------------------------------------------------
// Media segments (`/MediaSegments/{itemId}`) — skip intro/outro/recap
// ---------------------------------------------------------------------------

/// One annotated time range on a media item: an intro, a recap, an
/// outro, a commercial, a preview, or an unknown segment. Times are
/// expressed in Jellyfin ticks (10,000 per millisecond).
class JellyfinMediaSegment {
  /// Stable server-side segment id.
  final String? id;

  /// Id of the item this segment belongs to.
  final String? itemId;
  /// `Unknown`, `Commercial`, `Preview`, `Recap`, `Outro`, `Intro`.
  final String? type;

  /// Segment start in ticks (10_000 per millisecond).
  final int? startTicks;

  /// Segment end in ticks (10_000 per millisecond).
  final int? endTicks;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a media segment from already-parsed components.
  const JellyfinMediaSegment({
    this.id,
    this.itemId,
    this.type,
    this.startTicks,
    this.endTicks,
    this.raw = const {},
  });

  /// Segment start as a [Duration], or `null` when [startTicks] is absent.
  Duration? get start =>
      startTicks == null ? null : Duration(microseconds: startTicks! ~/ 10);

  /// Segment end as a [Duration], or `null` when [endTicks] is absent.
  Duration? get end =>
      endTicks == null ? null : Duration(microseconds: endTicks! ~/ 10);

  /// Decodes a `/MediaSegments/{itemId}` entry.
  factory JellyfinMediaSegment.fromJson(Map<String, dynamic> json) =>
      JellyfinMediaSegment(
        id: _str(json['Id']),
        itemId: _str(json['ItemId']),
        type: _str(json['Type']),
        startTicks: _int(json['StartTicks']),
        endTicks: _int(json['EndTicks']),
        raw: json,
      );
}

/// Canonical [JellyfinMediaSegment.type] values.
class JellyfinMediaSegmentType {
  /// Unclassified segment.
  static const unknown = 'Unknown';

  /// Commercial break.
  static const commercial = 'Commercial';

  /// "Next on…" or upcoming-content preview.
  static const preview = 'Preview';

  /// Recap of previous episodes.
  static const recap = 'Recap';

  /// Closing/outro sequence.
  static const outro = 'Outro';

  /// Opening/intro sequence.
  static const intro = 'Intro';
}

// ---------------------------------------------------------------------------
// Movie recommendations (`/Movies/Recommendations`)
// ---------------------------------------------------------------------------

/// One recommendation bucket from `/Movies/Recommendations`.
class JellyfinMovieRecommendation {
  /// Bucket id (e.g. the seed item or person id).
  final String? categoryId;

  /// Name of the seed item used to build this bucket.
  final String? baselineItemName;

  /// `'SimilarToRecentlyPlayed' | 'SimilarToLikedItem' | 'HasDirectorFromRecentlyPlayed' | 'HasActorFromRecentlyPlayed' | 'HasLikedDirector' | 'HasLikedActor'`.
  final String? recommendationType;

  /// Recommended items in this bucket.
  final List<JellyfinItem> items;

  /// Untouched response body for fields not lifted above.
  final Map<String, dynamic> raw;

  /// Builds a recommendation bucket from already-parsed components.
  const JellyfinMovieRecommendation({
    this.categoryId,
    this.baselineItemName,
    this.recommendationType,
    this.items = const [],
    this.raw = const {},
  });

  /// Decodes a recommendation entry, recursing into each `Items` element.
  factory JellyfinMovieRecommendation.fromJson(Map<String, dynamic> json) {
    final rawItems = json['Items'];
    return JellyfinMovieRecommendation(
      categoryId: _str(json['CategoryId']),
      baselineItemName: _str(json['BaselineItemName']),
      recommendationType: _str(json['RecommendationType']),
      items: [
        if (rawItems is List)
          for (final e in rawItems)
            if (e is Map<String, dynamic>) JellyfinItem.fromJson(e),
      ],
      raw: json,
    );
  }
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
