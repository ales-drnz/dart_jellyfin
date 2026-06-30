// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dio/dio.dart';

import 'api/jellyfin_activity_log_api.dart';
import 'api/jellyfin_api_key_api.dart';
import 'api/jellyfin_artists_api.dart';
import 'api/jellyfin_audio_api.dart';
import 'api/jellyfin_backup_api.dart';
import 'api/jellyfin_branding_api.dart';
import 'api/jellyfin_channels_api.dart';
import 'api/jellyfin_client_log_api.dart';
import 'api/jellyfin_collection_api.dart';
import 'api/jellyfin_configuration_api.dart';
import 'api/jellyfin_dashboard_api.dart';
import 'api/jellyfin_devices_api.dart';
import 'api/jellyfin_display_preferences_api.dart';
import 'api/jellyfin_environment_api.dart';
import 'api/jellyfin_filter_api.dart';
import 'api/jellyfin_genres_api.dart';
import 'api/jellyfin_hls_api.dart';
import 'api/jellyfin_images_api.dart';
import 'api/jellyfin_instant_mix_api.dart';
import 'api/jellyfin_item_lookup_api.dart';
import 'api/jellyfin_items_api.dart';
import 'api/jellyfin_library_api.dart';
import 'api/jellyfin_library_structure_api.dart';
import 'api/jellyfin_live_tv_api.dart';
import 'api/jellyfin_localization_api.dart';
import 'api/jellyfin_lyrics_api.dart';
import 'api/jellyfin_media_info_api.dart';
import 'api/jellyfin_media_segments_api.dart';
import 'api/jellyfin_movies_api.dart';
import 'api/jellyfin_music_genres_api.dart';
import 'api/jellyfin_notifications_api.dart';
import 'api/jellyfin_packages_api.dart';
import 'api/jellyfin_persons_api.dart';
import 'api/jellyfin_playback_api.dart';
import 'api/jellyfin_playlists_api.dart';
import 'api/jellyfin_plugins_api.dart';
import 'api/jellyfin_quick_connect_api.dart';
import 'api/jellyfin_remote_image_api.dart';
import 'api/jellyfin_scheduled_tasks_api.dart';
import 'api/jellyfin_search_api.dart';
import 'api/jellyfin_sessions_api.dart';
import 'api/jellyfin_startup_api.dart';
import 'api/jellyfin_studios_api.dart';
import 'api/jellyfin_subtitles_api.dart';
import 'api/jellyfin_suggestions_api.dart';
import 'api/jellyfin_sync_play_api.dart';
import 'api/jellyfin_system_api.dart';
import 'api/jellyfin_tmdb_api.dart';
import 'api/jellyfin_trailers_api.dart';
import 'api/jellyfin_trickplay_api.dart';
import 'api/jellyfin_tv_shows_api.dart';
import 'api/jellyfin_user_api.dart';
import 'api/jellyfin_user_data_api.dart';
import 'api/jellyfin_user_views_api.dart';
import 'api/jellyfin_videos_api.dart';
import 'api/jellyfin_years_api.dart';
import 'jellyfin_connection.dart';
import 'jellyfin_credentials.dart';

/// Stateful façade over the Jellyfin API.
///
/// One [JellyfinClient] = one identity (Authorization header) + one
/// active server. After authenticating, the same client serves every
/// endpoint through topic-named sub-APIs.
class JellyfinClient {
  final JellyfinConnection _http;

  /// `/System` operations — info, ping, restart, shutdown.
  late final JellyfinSystemApi system;

  /// `/Users` operations — login, list, manage.
  late final JellyfinUserApi user;

  /// `/QuickConnect` operations — passwordless device pairing.
  late final JellyfinQuickConnectApi quickConnect;

  /// `/Library` operations — top-level library browsing and refresh.
  late final JellyfinLibraryApi library;

  /// `/Items` operations — query, fetch, and mutate library items.
  late final JellyfinItemsApi items;

  /// `/Playlists` operations — create, edit, and play playlists.
  late final JellyfinPlaylistsApi playlists;

  /// `/Search` operations — global hint search.
  late final JellyfinSearchApi search;

  /// `/Audio` streaming endpoints.
  late final JellyfinAudioApi audio;

  /// `/Videos` streaming endpoints.
  late final JellyfinVideosApi videos;

  /// HLS adaptive-streaming endpoints.
  late final JellyfinHlsApi hls;

  /// `/MediaInfo` operations — playback info, bitrate testing.
  late final JellyfinMediaInfoApi mediaInfo;

  /// `/Trickplay` operations — scrubbing thumbnails.
  late final JellyfinTrickplayApi trickplay;

  /// `/Subtitles` operations — fetch and configure subtitle tracks.
  late final JellyfinSubtitlesApi subtitles;

  /// `/Images` operations — poster, backdrop, and chapter artwork.
  late final JellyfinImagesApi images;

  /// Playback reporting — start, progress, stopped events.
  late final JellyfinPlaybackApi playback;

  /// `/Sessions` operations — list and control active sessions.
  late final JellyfinSessionsApi sessions;

  /// `/UserData` operations — favourites, play state, ratings.
  late final JellyfinUserDataApi userData;

  /// `/InstantMix` operations — generate on-the-fly mixes.
  late final JellyfinInstantMixApi instantMix;

  /// `/LiveTv` operations — channels, recordings, EPG.
  late final JellyfinLiveTvApi liveTv;

  /// `/SyncPlay` operations — group playback coordination.
  late final JellyfinSyncPlayApi syncPlay;

  /// `/Shows` operations — TV-show specific browsing helpers.
  late final JellyfinTvShowsApi tvShows;

  /// `/Movies` operations — movie-specific browsing helpers.
  late final JellyfinMoviesApi movies;

  /// `/Suggestions` operations — recommendations for a user.
  late final JellyfinSuggestionsApi suggestions;

  /// `/MediaSegments` operations — intro/credit markers.
  late final JellyfinMediaSegmentsApi mediaSegments;

  /// `/Items/Filters` operations — facet/filter queries.
  late final JellyfinFilterApi filter;

  /// `/Artists` operations — list and fetch music artists.
  late final JellyfinArtistsApi artists;

  /// `/DisplayPreferences` operations — per-user UI state.
  late final JellyfinDisplayPreferencesApi displayPreferences;

  /// `/Lyrics` operations — fetch and upload synchronized lyrics.
  late final JellyfinLyricsApi lyrics;

  /// `/Channels` operations — virtual channels (plugins).
  late final JellyfinChannelsApi channels;

  /// `/Collections` operations — manage user-defined collections.
  late final JellyfinCollectionApi collection;

  /// `/UserViews` operations — per-user library shortcuts.
  late final JellyfinUserViewsApi userViews;

  /// `/Persons` operations — list and fetch people.
  late final JellyfinPersonsApi persons;

  /// `/Studios` operations — list and fetch studios.
  late final JellyfinStudiosApi studios;

  /// `/Genres` operations — list and fetch genres.
  late final JellyfinGenresApi genres;

  /// `/MusicGenres` operations — list and fetch music genres.
  late final JellyfinMusicGenresApi musicGenres;

  /// `/Years` operations — list and fetch year groupings.
  late final JellyfinYearsApi years;

  /// `/Localization` operations — cultures, countries, options.
  late final JellyfinLocalizationApi localization;

  /// `/Items/RemoteSearch` operations — metadata provider lookup.
  late final JellyfinItemLookupApi itemLookup;

  /// `/Library/VirtualFolders` operations — manage library roots.
  late final JellyfinLibraryStructureApi libraryStructure;

  /// `/Plugins` operations — list, configure, uninstall plugins.
  late final JellyfinPluginsApi plugins;

  /// `/Packages` operations — repository catalog and install.
  late final JellyfinPackagesApi packages;

  /// `/ScheduledTasks` operations — server background jobs.
  late final JellyfinScheduledTasksApi scheduledTasks;

  /// `/System/Configuration` operations — server settings.
  late final JellyfinConfigurationApi configuration;

  /// `/Environment` operations — filesystem and network probe.
  late final JellyfinEnvironmentApi environment;

  /// `/Startup` operations — first-run wizard endpoints.
  late final JellyfinStartupApi startup;

  /// `/Branding` operations — login splash, custom CSS.
  late final JellyfinBrandingApi branding;

  /// `/Auth/Keys` operations — long-lived API key management.
  late final JellyfinApiKeyApi apiKey;

  /// `/Backup` operations — server backup and restore.
  late final JellyfinBackupApi backup;

  /// `/Dashboard` operations — admin dashboard data.
  late final JellyfinDashboardApi dashboard;

  /// `/System/ActivityLog` operations — audit log entries.
  late final JellyfinActivityLogApi activityLog;

  /// `/ClientLog` operations — client-side log submission.
  late final JellyfinClientLogApi clientLog;

  /// TMDB integration endpoints.
  late final JellyfinTmdbApi tmdb;

  /// `/RemoteImages` operations — fetch images from metadata providers.
  late final JellyfinRemoteImageApi remoteImage;

  /// `/Devices` operations — list and manage registered devices.
  late final JellyfinDevicesApi devices;

  /// `/Trailers` operations — list trailer items.
  late final JellyfinTrailersApi trailers;

  /// `/Notifications` operations — server notification feed.
  late final JellyfinNotificationsApi notifications;

  /// Creates a client bound to [credentials] and (optionally) a server URL.
  JellyfinClient({
    required JellyfinCredentials credentials,
    String? baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _http = JellyfinConnection(
          credentials: credentials,
          baseUrl: baseUrl,
          dio: dio,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        ) {
    system = JellyfinSystemApi(_http);
    user = JellyfinUserApi(_http);
    quickConnect = JellyfinQuickConnectApi(_http);
    library = JellyfinLibraryApi(_http);
    items = JellyfinItemsApi(_http);
    playlists = JellyfinPlaylistsApi(_http);
    search = JellyfinSearchApi(_http);
    audio = JellyfinAudioApi(_http);
    videos = JellyfinVideosApi(_http);
    hls = JellyfinHlsApi(_http);
    mediaInfo = JellyfinMediaInfoApi(_http);
    trickplay = JellyfinTrickplayApi(_http);
    subtitles = JellyfinSubtitlesApi(_http);
    images = JellyfinImagesApi(_http);
    playback = JellyfinPlaybackApi(_http);
    sessions = JellyfinSessionsApi(_http);
    userData = JellyfinUserDataApi(_http);
    instantMix = JellyfinInstantMixApi(_http);
    liveTv = JellyfinLiveTvApi(_http);
    syncPlay = JellyfinSyncPlayApi(_http);
    tvShows = JellyfinTvShowsApi(_http);
    movies = JellyfinMoviesApi(_http);
    suggestions = JellyfinSuggestionsApi(_http);
    mediaSegments = JellyfinMediaSegmentsApi(_http);
    filter = JellyfinFilterApi(_http);
    artists = JellyfinArtistsApi(_http);
    displayPreferences = JellyfinDisplayPreferencesApi(_http);
    lyrics = JellyfinLyricsApi(_http);
    channels = JellyfinChannelsApi(_http);
    collection = JellyfinCollectionApi(_http);
    userViews = JellyfinUserViewsApi(_http);
    persons = JellyfinPersonsApi(_http);
    studios = JellyfinStudiosApi(_http);
    genres = JellyfinGenresApi(_http);
    musicGenres = JellyfinMusicGenresApi(_http);
    years = JellyfinYearsApi(_http);
    localization = JellyfinLocalizationApi(_http);
    itemLookup = JellyfinItemLookupApi(_http);
    libraryStructure = JellyfinLibraryStructureApi(_http);
    plugins = JellyfinPluginsApi(_http);
    packages = JellyfinPackagesApi(_http);
    scheduledTasks = JellyfinScheduledTasksApi(_http);
    configuration = JellyfinConfigurationApi(_http);
    environment = JellyfinEnvironmentApi(_http);
    startup = JellyfinStartupApi(_http);
    branding = JellyfinBrandingApi(_http);
    apiKey = JellyfinApiKeyApi(_http);
    backup = JellyfinBackupApi(_http);
    dashboard = JellyfinDashboardApi(_http);
    activityLog = JellyfinActivityLogApi(_http);
    clientLog = JellyfinClientLogApi(_http);
    tmdb = JellyfinTmdbApi(_http);
    remoteImage = JellyfinRemoteImageApi(_http);
    devices = JellyfinDevicesApi(_http);
    notifications = JellyfinNotificationsApi(_http);
    trailers = JellyfinTrailersApi(_http);
  }

  /// Client identity sent on every request.
  JellyfinCredentials get credentials => _http.credentials;

  /// Active server root URL, or `null` before [connect] is called.
  String? get baseUrl => _http.baseUrl;

  /// Active access token, or `null` if no session is established.
  String? get token => _http.token;

  /// Authenticated user id, or `null` if no session is established.
  String? get userId => _http.userId;

  /// `true` when a base URL, token, and user id are all set.
  bool get isAuthenticated => _http.isAuthenticated;

  /// Point the client at a Jellyfin server (overrides the constructor
  /// `baseUrl` if any).
  void connect(String url) {
    _http.baseUrl = url;
  }

  /// Set the active session — the access token and user id returned by
  /// [JellyfinUserApi.authenticateByName] or
  /// [JellyfinUserApi.authenticateWithQuickConnect].
  void setSession({required String token, required String userId}) {
    _http.token = token;
    _http.userId = userId;
  }

  /// Clear the active token + user id.
  void clearSession() {
    _http.token = null;
    _http.userId = null;
  }

  /// Drop base URL, token, and user id.
  void disconnect() {
    clearSession();
    _http.baseUrl = null;
  }

  /// Escape hatch: issue an arbitrary request through the same Dio
  /// instance + headers as the sub-APIs.
  ///
  /// Use this for endpoints not yet covered by the typed sub-APIs.
  /// Throws [JellyfinException] on failure (same as every other call).
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? extraHeaders,
    bool absoluteUrl = false,
    ResponseType? responseType,
    CancelToken? cancelToken,
  }) =>
      _http.request<T>(
        path,
        method: method,
        queryParameters: queryParameters,
        data: data,
        extraHeaders: extraHeaders,
        absoluteUrl: absoluteUrl,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  /// Convenience for byte-stream GETs (artwork, downloads).
  ///
  /// Pass a [cancelToken] to abort an in-flight download — useful for large
  /// artwork or media transfers the caller may need to cancel.
  Future<Response<List<int>>> requestBytes(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool absoluteUrl = true,
    CancelToken? cancelToken,
  }) =>
      _http.requestBytes(
        url,
        queryParameters: queryParameters,
        absoluteUrl: absoluteUrl,
        cancelToken: cancelToken,
      );

  // ─── Lightweight method aliases ────────────────────────────────────

  /// Shorthand for a `GET` [request].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
  }) =>
      request<T>(
        path,
        queryParameters: queryParameters,
        extraHeaders: extraHeaders,
      );

  /// Shorthand for a `POST` [request].
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
  }) =>
      request<T>(
        path,
        method: 'POST',
        data: data,
        queryParameters: queryParameters,
        extraHeaders: extraHeaders,
      );

  /// Shorthand for a `DELETE` [request].
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? extraHeaders,
  }) =>
      request<T>(
        path,
        method: 'DELETE',
        queryParameters: queryParameters,
        extraHeaders: extraHeaders,
      );

  /// Alias for [requestBytes] — kept so the calling code can read like
  /// the original Dio-based wrapper it replaced.
  ///
  /// Redundant: `requestBytes` already defaults to `absoluteUrl: true` and
  /// additionally supports `queryParameters` and relative paths. Prefer
  /// [requestBytes] directly; this alias is retained for one deprecation
  /// cycle and will be removed in a future release.
  @Deprecated(
    'Use requestBytes; this alias will be removed in a future release.',
  )
  Future<Response<List<int>>> fetchBytes(String url) => requestBytes(url);
}
