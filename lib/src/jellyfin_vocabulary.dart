// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The words Jellyfin's list endpoints take — item kinds, fields, sort
/// keys, media types and filters — as types instead of strings.
///
/// Jellyfin ignores a value it does not know and answers with a *wider*
/// result: `includeItemTypes=MusicAlbum` narrows to albums, a misspelt
/// `includeItemTypes=MusicAlbums` lists everything. Typed lists make the
/// misspelling a compile error. Each type is an extension type over the
/// wire string, so a value this package does not list yet (a newer
/// server's) is still one constructor away: `JellyfinItemKind('NewKind')`.
///
/// The constants are the enums of the Jellyfin 12.2 API document.
library;

/// An item kind (`BaseItemKind`), as sent in `includeItemTypes` and `excludeItemTypes`.
extension type const JellyfinItemKind(String wire) implements String {
  /// `AggregateFolder`.
  static const aggregateFolder = JellyfinItemKind('AggregateFolder');

  /// `Audio`.
  static const audio = JellyfinItemKind('Audio');

  /// `AudioBook`.
  static const audioBook = JellyfinItemKind('AudioBook');

  /// `BasePluginFolder`.
  static const basePluginFolder = JellyfinItemKind('BasePluginFolder');

  /// `Book`.
  static const book = JellyfinItemKind('Book');

  /// `BoxSet`.
  static const boxSet = JellyfinItemKind('BoxSet');

  /// `Channel`.
  static const channel = JellyfinItemKind('Channel');

  /// `ChannelFolderItem`.
  static const channelFolderItem = JellyfinItemKind('ChannelFolderItem');

  /// `CollectionFolder`.
  static const collectionFolder = JellyfinItemKind('CollectionFolder');

  /// `Episode`.
  static const episode = JellyfinItemKind('Episode');

  /// `Folder`.
  static const folder = JellyfinItemKind('Folder');

  /// `Genre`.
  static const genre = JellyfinItemKind('Genre');

  /// `ManualPlaylistsFolder`.
  static const manualPlaylistsFolder =
      JellyfinItemKind('ManualPlaylistsFolder');

  /// `Movie`.
  static const movie = JellyfinItemKind('Movie');

  /// `LiveTvChannel`.
  static const liveTvChannel = JellyfinItemKind('LiveTvChannel');

  /// `LiveTvProgram`.
  static const liveTvProgram = JellyfinItemKind('LiveTvProgram');

  /// `MusicAlbum`.
  static const musicAlbum = JellyfinItemKind('MusicAlbum');

  /// `MusicArtist`.
  static const musicArtist = JellyfinItemKind('MusicArtist');

  /// `MusicGenre`.
  static const musicGenre = JellyfinItemKind('MusicGenre');

  /// `MusicVideo`.
  static const musicVideo = JellyfinItemKind('MusicVideo');

  /// `Person`.
  static const person = JellyfinItemKind('Person');

  /// `Photo`.
  static const photo = JellyfinItemKind('Photo');

  /// `PhotoAlbum`.
  static const photoAlbum = JellyfinItemKind('PhotoAlbum');

  /// `Playlist`.
  static const playlist = JellyfinItemKind('Playlist');

  /// `PlaylistsFolder`.
  static const playlistsFolder = JellyfinItemKind('PlaylistsFolder');

  /// `Program`.
  static const program = JellyfinItemKind('Program');

  /// `Recording`.
  static const recording = JellyfinItemKind('Recording');

  /// `Season`.
  static const season = JellyfinItemKind('Season');

  /// `Series`.
  static const series = JellyfinItemKind('Series');

  /// `Studio`.
  static const studio = JellyfinItemKind('Studio');

  /// `Trailer`.
  static const trailer = JellyfinItemKind('Trailer');

  /// `TvChannel`.
  static const tvChannel = JellyfinItemKind('TvChannel');

  /// `TvProgram`.
  static const tvProgram = JellyfinItemKind('TvProgram');

  /// `UserRootFolder`.
  static const userRootFolder = JellyfinItemKind('UserRootFolder');

  /// `UserView`.
  static const userView = JellyfinItemKind('UserView');

  /// `Video`.
  static const video = JellyfinItemKind('Video');

  /// `Year`.
  static const year = JellyfinItemKind('Year');
}

/// A field to include in the answer (`ItemFields`), as sent in `fields`.
extension type const JellyfinItemField(String wire) implements String {
  /// `AirTime`.
  static const airTime = JellyfinItemField('AirTime');

  /// `CanDelete`.
  static const canDelete = JellyfinItemField('CanDelete');

  /// `CanDownload`.
  static const canDownload = JellyfinItemField('CanDownload');

  /// `ChannelInfo`.
  static const channelInfo = JellyfinItemField('ChannelInfo');

  /// `Chapters`.
  static const chapters = JellyfinItemField('Chapters');

  /// `Trickplay`.
  static const trickplay = JellyfinItemField('Trickplay');

  /// `ChildCount`.
  static const childCount = JellyfinItemField('ChildCount');

  /// `CumulativeRunTimeTicks`.
  static const cumulativeRunTimeTicks =
      JellyfinItemField('CumulativeRunTimeTicks');

  /// `CustomRating`.
  static const customRating = JellyfinItemField('CustomRating');

  /// `DateCreated`.
  static const dateCreated = JellyfinItemField('DateCreated');

  /// `DateLastMediaAdded`.
  static const dateLastMediaAdded = JellyfinItemField('DateLastMediaAdded');

  /// `DisplayPreferencesId`.
  static const displayPreferencesId = JellyfinItemField('DisplayPreferencesId');

  /// `Etag`.
  static const etag = JellyfinItemField('Etag');

  /// `ExternalUrls`.
  static const externalUrls = JellyfinItemField('ExternalUrls');

  /// `Genres`.
  static const genres = JellyfinItemField('Genres');

  /// `ItemCounts`.
  static const itemCounts = JellyfinItemField('ItemCounts');

  /// `MediaSourceCount`.
  static const mediaSourceCount = JellyfinItemField('MediaSourceCount');

  /// `MediaSources`.
  static const mediaSources = JellyfinItemField('MediaSources');

  /// `OriginalTitle`.
  static const originalTitle = JellyfinItemField('OriginalTitle');

  /// `Overview`.
  static const overview = JellyfinItemField('Overview');

  /// `ParentId`.
  static const parentId = JellyfinItemField('ParentId');

  /// `Path`.
  static const path = JellyfinItemField('Path');

  /// `People`.
  static const people = JellyfinItemField('People');

  /// `PlayAccess`.
  static const playAccess = JellyfinItemField('PlayAccess');

  /// `ProductionLocations`.
  static const productionLocations = JellyfinItemField('ProductionLocations');

  /// `ProviderIds`.
  static const providerIds = JellyfinItemField('ProviderIds');

  /// `PrimaryImageAspectRatio`.
  static const primaryImageAspectRatio =
      JellyfinItemField('PrimaryImageAspectRatio');

  /// `RecursiveItemCount`.
  static const recursiveItemCount = JellyfinItemField('RecursiveItemCount');

  /// `Settings`.
  static const settings = JellyfinItemField('Settings');

  /// `SeriesStudio`.
  static const seriesStudio = JellyfinItemField('SeriesStudio');

  /// `SortName`.
  static const sortName = JellyfinItemField('SortName');

  /// `SpecialEpisodeNumbers`.
  static const specialEpisodeNumbers =
      JellyfinItemField('SpecialEpisodeNumbers');

  /// `Studios`.
  static const studios = JellyfinItemField('Studios');

  /// `Taglines`.
  static const taglines = JellyfinItemField('Taglines');

  /// `Tags`.
  static const tags = JellyfinItemField('Tags');

  /// `RemoteTrailers`.
  static const remoteTrailers = JellyfinItemField('RemoteTrailers');

  /// `MediaStreams`.
  static const mediaStreams = JellyfinItemField('MediaStreams');

  /// `SeasonUserData`.
  static const seasonUserData = JellyfinItemField('SeasonUserData');

  /// `DateLastRefreshed`.
  static const dateLastRefreshed = JellyfinItemField('DateLastRefreshed');

  /// `DateLastSaved`.
  static const dateLastSaved = JellyfinItemField('DateLastSaved');

  /// `RefreshState`.
  static const refreshState = JellyfinItemField('RefreshState');

  /// `ChannelImage`.
  static const channelImage = JellyfinItemField('ChannelImage');

  /// `EnableMediaSourceDisplay`.
  static const enableMediaSourceDisplay =
      JellyfinItemField('EnableMediaSourceDisplay');

  /// `Width`.
  static const width = JellyfinItemField('Width');

  /// `Height`.
  static const height = JellyfinItemField('Height');

  /// `ExtraIds`.
  static const extraIds = JellyfinItemField('ExtraIds');

  /// `LocalTrailerCount`.
  static const localTrailerCount = JellyfinItemField('LocalTrailerCount');

  /// `IsHD`.
  static const isHD = JellyfinItemField('IsHD');

  /// `SpecialFeatureCount`.
  static const specialFeatureCount = JellyfinItemField('SpecialFeatureCount');
}

/// A sort key (`ItemSortBy`), as sent in `sortBy`.
extension type const JellyfinSortField(String wire) implements String {
  /// `Default`.
  static const defaultOrder = JellyfinSortField('Default');

  /// `AiredEpisodeOrder`.
  static const airedEpisodeOrder = JellyfinSortField('AiredEpisodeOrder');

  /// `Album`.
  static const album = JellyfinSortField('Album');

  /// `AlbumArtist`.
  static const albumArtist = JellyfinSortField('AlbumArtist');

  /// `Artist`.
  static const artist = JellyfinSortField('Artist');

  /// `DateCreated`.
  static const dateCreated = JellyfinSortField('DateCreated');

  /// `OfficialRating`.
  static const officialRating = JellyfinSortField('OfficialRating');

  /// `DatePlayed`.
  static const datePlayed = JellyfinSortField('DatePlayed');

  /// `PremiereDate`.
  static const premiereDate = JellyfinSortField('PremiereDate');

  /// `StartDate`.
  static const startDate = JellyfinSortField('StartDate');

  /// `SortName`.
  static const sortName = JellyfinSortField('SortName');

  /// `Name`.
  static const name = JellyfinSortField('Name');

  /// `Random`.
  static const random = JellyfinSortField('Random');

  /// `Runtime`.
  static const runtime = JellyfinSortField('Runtime');

  /// `CommunityRating`.
  static const communityRating = JellyfinSortField('CommunityRating');

  /// `ProductionYear`.
  static const productionYear = JellyfinSortField('ProductionYear');

  /// `PlayCount`.
  static const playCount = JellyfinSortField('PlayCount');

  /// `CriticRating`.
  static const criticRating = JellyfinSortField('CriticRating');

  /// `IsFolder`.
  static const isFolder = JellyfinSortField('IsFolder');

  /// `IsUnplayed`.
  static const isUnplayed = JellyfinSortField('IsUnplayed');

  /// `IsPlayed`.
  static const isPlayed = JellyfinSortField('IsPlayed');

  /// `SeriesSortName`.
  static const seriesSortName = JellyfinSortField('SeriesSortName');

  /// `VideoBitRate`.
  static const videoBitRate = JellyfinSortField('VideoBitRate');

  /// `AirTime`.
  static const airTime = JellyfinSortField('AirTime');

  /// `Studio`.
  static const studio = JellyfinSortField('Studio');

  /// `IsFavoriteOrLiked`.
  static const isFavoriteOrLiked = JellyfinSortField('IsFavoriteOrLiked');

  /// `DateLastContentAdded`.
  static const dateLastContentAdded = JellyfinSortField('DateLastContentAdded');

  /// `SeriesDatePlayed`.
  static const seriesDatePlayed = JellyfinSortField('SeriesDatePlayed');

  /// `ParentIndexNumber`.
  static const parentIndexNumber = JellyfinSortField('ParentIndexNumber');

  /// `IndexNumber`.
  static const indexNumber = JellyfinSortField('IndexNumber');
}

/// A media type (`MediaType`), as sent in `mediaTypes`.
extension type const JellyfinMediaType(String wire) implements String {
  /// `Unknown`.
  static const unknown = JellyfinMediaType('Unknown');

  /// `Video`.
  static const video = JellyfinMediaType('Video');

  /// `Audio`.
  static const audio = JellyfinMediaType('Audio');

  /// `Photo`.
  static const photo = JellyfinMediaType('Photo');

  /// `Book`.
  static const book = JellyfinMediaType('Book');
}

/// A filter (`ItemFilter`), as sent in `filters`.
extension type const JellyfinItemFilter(String wire) implements String {
  /// `IsFolder`.
  static const isFolder = JellyfinItemFilter('IsFolder');

  /// `IsNotFolder`.
  static const isNotFolder = JellyfinItemFilter('IsNotFolder');

  /// `IsUnplayed`.
  static const isUnplayed = JellyfinItemFilter('IsUnplayed');

  /// `IsPlayed`.
  static const isPlayed = JellyfinItemFilter('IsPlayed');

  /// `IsFavorite`.
  static const isFavorite = JellyfinItemFilter('IsFavorite');

  /// `IsResumable`.
  static const isResumable = JellyfinItemFilter('IsResumable');

  /// `Likes`.
  static const likes = JellyfinItemFilter('Likes');

  /// `Dislikes`.
  static const dislikes = JellyfinItemFilter('Dislikes');

  /// `IsFavoriteOrLikes`.
  static const isFavoriteOrLikes = JellyfinItemFilter('IsFavoriteOrLikes');
}
