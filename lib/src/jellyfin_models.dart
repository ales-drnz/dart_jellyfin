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

class JellyfinQueryResult<T> {
  final List<T> items;
  final int totalRecordCount;
  final int? startIndex;

  const JellyfinQueryResult({
    required this.items,
    required this.totalRecordCount,
    this.startIndex,
  });

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

class JellyfinSystemInfo {
  final String? id;
  final String? serverName;
  final String? version;
  final String? productName;
  final String? operatingSystem;
  final Map<String, dynamic> raw;

  const JellyfinSystemInfo({
    required this.raw,
    this.id,
    this.serverName,
    this.version,
    this.productName,
    this.operatingSystem,
  });

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

class JellyfinUser {
  final String id;
  final String name;
  final String? serverId;
  final String? primaryImageTag;
  final bool hasPassword;
  final bool hasConfiguredPassword;
  final bool hasConfiguredEasyPassword;
  final DateTime? lastLoginDate;
  final DateTime? lastActivityDate;
  final Map<String, dynamic> raw;

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
  final JellyfinUser user;
  final String accessToken;
  final String serverId;
  final Map<String, dynamic> raw;

  const JellyfinAuthResult({
    required this.user,
    required this.accessToken,
    required this.serverId,
    required this.raw,
  });

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
  final bool authenticated;
  final String secret;
  final String code;
  final String? deviceId;
  final String? deviceName;
  final String? appName;
  final String? appVersion;
  final DateTime? dateAdded;

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
  final String id;
  final String name;
  final String? collectionType;
  final String? primaryImageTag;
  final String? serverId;
  final Map<String, dynamic> raw;

  const JellyfinView({
    required this.id,
    required this.name,
    required this.raw,
    this.collectionType,
    this.primaryImageTag,
    this.serverId,
  });

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

  bool get isMusic => collectionType == 'music';
  bool get isMovies => collectionType == 'movies';
  bool get isTvShows => collectionType == 'tvshows';
  bool get isPhotos => collectionType == 'photos';
}

// ---------------------------------------------------------------------------
// Items (BaseItemDto subset)
// ---------------------------------------------------------------------------

/// Item kinds we recognise (a subset of the OpenAPI `BaseItemKind` enum).
/// Strings match the wire values used in `Type` and `IncludeItemTypes`.
abstract final class JellyfinItemKind {
  static const audio = 'Audio';
  static const audioBook = 'AudioBook';
  static const musicAlbum = 'MusicAlbum';
  static const musicArtist = 'MusicArtist';
  static const musicGenre = 'MusicGenre';
  static const musicVideo = 'MusicVideo';
  static const playlist = 'Playlist';
  static const movie = 'Movie';
  static const series = 'Series';
  static const season = 'Season';
  static const episode = 'Episode';
  static const photo = 'Photo';
  static const photoAlbum = 'PhotoAlbum';
  static const folder = 'Folder';
  static const collectionFolder = 'CollectionFolder';
  static const userView = 'UserView';
  static const genre = 'Genre';
  static const person = 'Person';
  static const studio = 'Studio';
  static const book = 'Book';
}

/// Subset of `BaseItemDto`. Hand-rolled — the full DTO has 153 fields,
/// here we lift only what music apps use today. Anything else lives in
/// [JellyfinItem.raw].
class JellyfinItem {
  final String id;
  final String name;
  final String? type;
  final String? mediaType;
  final String? collectionType;
  final String? sortName;
  final String? originalTitle;
  final String? overview;

  // Hierarchy
  final String? parentId;
  final String? seriesId;
  final String? seriesName;
  final String? seasonId;
  final String? seasonName;
  final String? albumId;
  final String? album;
  final String? albumArtist;
  final List<String> albumArtists;
  final List<String> artists;
  final List<JellyfinArtistRef> artistItems;

  // Index / ordering
  final int? indexNumber;
  final int? parentIndexNumber;
  final int? productionYear;
  final DateTime? premiereDate;
  final DateTime? dateCreated;

  // Duration / media
  /// `RunTimeTicks`, where 1 ms = 10_000 ticks.
  final int? runTimeTicks;
  final String? container;
  final List<JellyfinMediaSource> mediaSources;
  final List<JellyfinMediaStream> mediaStreams;
  final bool isFolder;
  final int? childCount;
  final bool hasLyrics;

  // Genres / tags
  final List<String> genres;
  final List<String> tags;

  // Images
  final Map<String, String> imageTags;
  final List<String> backdropImageTags;
  final String? albumPrimaryImageTag;
  final Map<String, String> imageBlurHashes;
  final double? primaryImageAspectRatio;

  // Per-user data
  final JellyfinUserData? userData;

  // Sound / video specs
  final int? width;
  final int? height;

  // Raw
  final Map<String, dynamic> raw;

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

  bool get isFavorite => userData?.isFavorite ?? false;
  bool get isAudio => mediaType == 'Audio' || type == JellyfinItemKind.audio;
}

class JellyfinArtistRef {
  final String id;
  final String name;
  const JellyfinArtistRef({required this.id, required this.name});
  factory JellyfinArtistRef.fromJson(Map<String, dynamic> json) => JellyfinArtistRef(
        id: _str(json['Id']) ?? '',
        name: _str(json['Name']) ?? '',
      );
}

class JellyfinMediaSource {
  final String id;
  final String? path;
  final String? container;
  final int? bitrate;
  final int? size;
  final int? runTimeTicks;
  final bool supportsDirectPlay;
  final bool supportsDirectStream;
  final bool supportsTranscoding;
  final String? transcodingUrl;
  final String? transcodingSubProtocol;
  final String? transcodingContainer;
  final List<JellyfinMediaStream> mediaStreams;
  final Map<String, dynamic> raw;

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

class JellyfinMediaStream {
  final int? index;
  final String? type; // Audio | Video | Subtitle | Lyrics | EmbeddedImage
  final String? codec;
  final String? language;
  final int? channels;
  final int? sampleRate;
  final int? bitRate;
  final int? bitDepth;
  final String? title;
  final bool isDefault;
  final Map<String, dynamic> raw;

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

  bool get isAudio => type == 'Audio';
  bool get isVideo => type == 'Video';
  bool get isSubtitle => type == 'Subtitle';
  bool get isLyrics => type == 'Lyrics';
}

class JellyfinUserData {
  final int? playbackPositionTicks;
  final int playCount;
  final bool isFavorite;
  final bool? likes;
  final DateTime? lastPlayedDate;
  final bool played;
  final String? key;

  const JellyfinUserData({
    required this.playCount,
    required this.isFavorite,
    required this.played,
    this.playbackPositionTicks,
    this.likes,
    this.lastPlayedDate,
    this.key,
  });

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
  final int? startTicks;
  final String text;

  const JellyfinLyricLine({required this.text, this.startTicks});

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
  final List<JellyfinLyricLine> lines;
  final Map<String, dynamic> raw;

  const JellyfinLyrics({required this.lines, required this.raw});

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

  bool get isSynced => lines.any((l) => l.startTicks != null);

  /// Render as an LRC document, suitable for any synced-lyrics player.
  String toLrc() => lines.map((l) => l.toLrcLine()).join('\n');

  /// Render as plain text (one line per entry, timestamps dropped).
  String toPlainText() => lines.map((l) => l.text).join('\n');
}

// ---------------------------------------------------------------------------
// Search hints
// ---------------------------------------------------------------------------

class JellyfinSearchHint {
  final String itemId;
  final String? name;
  final String? matchedTerm;
  final String? type;
  final String? mediaType;
  final String? albumArtist;
  final List<String> artists;
  final int? runTimeTicks;
  final int? indexNumber;
  final int? productionYear;
  final String? primaryImageTag;
  final Map<String, dynamic> raw;

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
  final String id;
  final String? userId;
  final String? userName;
  final String? client;
  final String? deviceId;
  final String? deviceName;
  final String? applicationVersion;
  final String? remoteEndPoint;
  final DateTime? lastActivityDate;
  final DateTime? lastPlaybackCheckIn;
  final bool isActive;
  final bool supportsMediaControl;
  final bool supportsRemoteControl;
  final List<String> playableMediaTypes;
  final List<String> supportedCommands;

  /// `NowPlayingItem` parsed as a [JellyfinItem]. Null when the session
  /// isn't playing anything.
  final JellyfinItem? nowPlayingItem;

  /// `PlayState` — `PositionTicks`, `IsPaused`, `IsMuted`, `VolumeLevel`,
  /// `AudioStreamIndex`, `SubtitleStreamIndex`, `PlayMethod`,
  /// `RepeatMode`, `PlaybackOrder`.
  final Map<String, dynamic>? playState;

  final Map<String, dynamic> raw;

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
  final List<JellyfinMediaSource> mediaSources;
  final String? playSessionId;
  final String? errorCode;
  final Map<String, dynamic> raw;

  const JellyfinPlaybackInfo({
    required this.mediaSources,
    required this.raw,
    this.playSessionId,
    this.errorCode,
  });

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
  final String? id;
  final String? client;
  final String? viewType;
  final String? sortBy;
  final String? sortOrder;
  final String? indexBy;
  final String? scrollDirection;
  final bool? rememberIndexing;
  final bool? rememberSorting;
  final bool? showBackdrop;
  final bool? showSidebar;
  final int? primaryImageHeight;
  final int? primaryImageWidth;
  final Map<String, String> customPrefs;
  final Map<String, dynamic> raw;

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
  final String? name;
  final String? id;

  const JellyfinNameGuidPair({this.name, this.id});

  factory JellyfinNameGuidPair.fromJson(Map<String, dynamic> json) =>
      JellyfinNameGuidPair(
        name: _str(json['Name']),
        id: _str(json['Id']),
      );
}

/// Modern facet response from `/Items/Filters2` — genres carry ids so
/// the client can filter back through `items.list(genreIds: …)`.
class JellyfinQueryFilters {
  final List<JellyfinNameGuidPair> genres;
  final List<String> tags;
  final Map<String, dynamic> raw;

  const JellyfinQueryFilters({
    this.genres = const [],
    this.tags = const [],
    this.raw = const {},
  });

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
  final List<String> genres;
  final List<String> tags;
  final List<String> officialRatings;
  final List<int> years;
  final Map<String, dynamic> raw;

  const JellyfinQueryFiltersLegacy({
    this.genres = const [],
    this.tags = const [],
    this.officialRatings = const [],
    this.years = const [],
    this.raw = const {},
  });

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
  final String? id;
  final String? itemId;
  /// `Unknown`, `Commercial`, `Preview`, `Recap`, `Outro`, `Intro`.
  final String? type;
  final int? startTicks;
  final int? endTicks;
  final Map<String, dynamic> raw;

  const JellyfinMediaSegment({
    this.id,
    this.itemId,
    this.type,
    this.startTicks,
    this.endTicks,
    this.raw = const {},
  });

  Duration? get start =>
      startTicks == null ? null : Duration(microseconds: startTicks! ~/ 10);
  Duration? get end =>
      endTicks == null ? null : Duration(microseconds: endTicks! ~/ 10);

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
  static const unknown = 'Unknown';
  static const commercial = 'Commercial';
  static const preview = 'Preview';
  static const recap = 'Recap';
  static const outro = 'Outro';
  static const intro = 'Intro';
}

// ---------------------------------------------------------------------------
// Movie recommendations (`/Movies/Recommendations`)
// ---------------------------------------------------------------------------

class JellyfinMovieRecommendation {
  final String? categoryId;
  final String? baselineItemName;
  final String? recommendationType;
  final List<JellyfinItem> items;
  final Map<String, dynamic> raw;

  const JellyfinMovieRecommendation({
    this.categoryId,
    this.baselineItemName,
    this.recommendationType,
    this.items = const [],
    this.raw = const {},
  });

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
