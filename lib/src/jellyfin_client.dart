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
import 'api/jellyfin_item_lookup_api.dart';
import 'api/jellyfin_library_structure_api.dart';
import 'api/jellyfin_localization_api.dart';
import 'api/jellyfin_lyrics_api.dart';
import 'api/jellyfin_music_genres_api.dart';
import 'api/jellyfin_notifications_api.dart';
import 'api/jellyfin_packages_api.dart';
import 'api/jellyfin_persons_api.dart';
import 'api/jellyfin_plugins_api.dart';
import 'api/jellyfin_remote_image_api.dart';
import 'api/jellyfin_scheduled_tasks_api.dart';
import 'api/jellyfin_startup_api.dart';
import 'api/jellyfin_studios_api.dart';
import 'api/jellyfin_tmdb_api.dart';
import 'api/jellyfin_trailers_api.dart';
import 'api/jellyfin_years_api.dart';
import 'api/jellyfin_hls_api.dart';
import 'api/jellyfin_images_api.dart';
import 'api/jellyfin_instant_mix_api.dart';
import 'api/jellyfin_items_api.dart';
import 'api/jellyfin_live_tv_api.dart';
import 'api/jellyfin_library_api.dart';
import 'api/jellyfin_media_info_api.dart';
import 'api/jellyfin_media_segments_api.dart';
import 'api/jellyfin_movies_api.dart';
import 'api/jellyfin_playlists_api.dart';
import 'api/jellyfin_playback_api.dart';
import 'api/jellyfin_quick_connect_api.dart';
import 'api/jellyfin_search_api.dart';
import 'api/jellyfin_sessions_api.dart';
import 'api/jellyfin_subtitles_api.dart';
import 'api/jellyfin_suggestions_api.dart';
import 'api/jellyfin_sync_play_api.dart';
import 'api/jellyfin_system_api.dart';
import 'api/jellyfin_user_views_api.dart';
import 'api/jellyfin_trickplay_api.dart';
import 'api/jellyfin_tv_shows_api.dart';
import 'api/jellyfin_user_api.dart';
import 'api/jellyfin_user_data_api.dart';
import 'api/jellyfin_videos_api.dart';
import 'jellyfin_connection.dart';
import 'jellyfin_credentials.dart';

/// Stateful façade over the Jellyfin API.
///
/// One [JellyfinClient] = one identity (Authorization header) + one
/// active server. After authenticating, the same client serves every
/// endpoint through topic-named sub-APIs.
class JellyfinClient {
  final JellyfinConnection _http;

  late final JellyfinSystemApi system;
  late final JellyfinUserApi user;
  late final JellyfinQuickConnectApi quickConnect;
  late final JellyfinLibraryApi library;
  late final JellyfinItemsApi items;
  late final JellyfinPlaylistsApi playlists;
  late final JellyfinSearchApi search;
  late final JellyfinAudioApi audio;
  late final JellyfinVideosApi videos;
  late final JellyfinHlsApi hls;
  late final JellyfinMediaInfoApi mediaInfo;
  late final JellyfinTrickplayApi trickplay;
  late final JellyfinSubtitlesApi subtitles;
  late final JellyfinImagesApi images;
  late final JellyfinPlaybackApi playback;
  late final JellyfinSessionsApi sessions;
  late final JellyfinUserDataApi userData;
  late final JellyfinInstantMixApi instantMix;
  late final JellyfinLiveTvApi liveTv;
  late final JellyfinSyncPlayApi syncPlay;
  late final JellyfinTvShowsApi tvShows;
  late final JellyfinMoviesApi movies;
  late final JellyfinSuggestionsApi suggestions;
  late final JellyfinMediaSegmentsApi mediaSegments;
  late final JellyfinFilterApi filter;
  late final JellyfinArtistsApi artists;
  late final JellyfinDisplayPreferencesApi displayPreferences;
  late final JellyfinLyricsApi lyrics;
  late final JellyfinChannelsApi channels;
  late final JellyfinCollectionApi collection;
  late final JellyfinUserViewsApi userViews;
  late final JellyfinPersonsApi persons;
  late final JellyfinStudiosApi studios;
  late final JellyfinGenresApi genres;
  late final JellyfinMusicGenresApi musicGenres;
  late final JellyfinYearsApi years;
  late final JellyfinLocalizationApi localization;
  late final JellyfinItemLookupApi itemLookup;
  late final JellyfinLibraryStructureApi libraryStructure;
  late final JellyfinPluginsApi plugins;
  late final JellyfinPackagesApi packages;
  late final JellyfinScheduledTasksApi scheduledTasks;
  late final JellyfinConfigurationApi configuration;
  late final JellyfinEnvironmentApi environment;
  late final JellyfinStartupApi startup;
  late final JellyfinBrandingApi branding;
  late final JellyfinApiKeyApi apiKey;
  late final JellyfinBackupApi backup;
  late final JellyfinDashboardApi dashboard;
  late final JellyfinActivityLogApi activityLog;
  late final JellyfinClientLogApi clientLog;
  late final JellyfinTmdbApi tmdb;
  late final JellyfinRemoteImageApi remoteImage;
  late final JellyfinDevicesApi devices;
  late final JellyfinTrailersApi trailers;
  late final JellyfinNotificationsApi notifications;

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

  JellyfinCredentials get credentials => _http.credentials;
  String? get baseUrl => _http.baseUrl;
  String? get token => _http.token;
  String? get userId => _http.userId;
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
  }) =>
      _http.request<T>(
        path,
        method: method,
        queryParameters: queryParameters,
        data: data,
        extraHeaders: extraHeaders,
        absoluteUrl: absoluteUrl,
        responseType: responseType,
      );

  /// Convenience for byte-stream GETs (artwork, downloads).
  Future<Response<List<int>>> requestBytes(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool absoluteUrl = true,
  }) =>
      _http.requestBytes(
        url,
        queryParameters: queryParameters,
        absoluteUrl: absoluteUrl,
      );

  // ─── Lightweight method aliases ────────────────────────────────────

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
  Future<Response<List<int>>> fetchBytes(String url) =>
      requestBytes(url, absoluteUrl: true);
}
