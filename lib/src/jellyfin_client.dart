// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
import 'api/jellyfin_trickplay_api.dart';
import 'api/jellyfin_tv_shows_api.dart';
import 'api/jellyfin_user_api.dart';
import 'api/jellyfin_user_data_api.dart';
import 'api/jellyfin_user_views_api.dart';
import 'api/jellyfin_videos_api.dart';
import 'api/jellyfin_years_api.dart';
import 'jellyfin_connection.dart';
import 'jellyfin_credentials.dart';
import 'jellyfin_error_type.dart';
import 'jellyfin_exception.dart';
import 'transport/jellyfin_cancel_token.dart';
import 'transport/jellyfin_response.dart';
import 'transport/jellyfin_retry_policy.dart';

/// Stateful façade over the Jellyfin API.
///
/// One [JellyfinClient] = one identity (Authorization header) + one
/// active server. After authenticating, the same client serves every
/// endpoint through topic-named sub-APIs.
///
/// The client and its sub-API classes are deliberately not `final`, so an
/// app's tests can stand in for them (`class FakeClient implements
/// JellyfinClient`, or a mocking library). The models are `final`: they are
/// data, built by the library.
///
/// {@category Client and sign-in}
/// {@category Raw requests}
class JellyfinClient {
  final JellyfinConnection _http;

  /// The client this one is a [withCancelToken] view of, or `null`.
  final JellyfinClient? _parent;

  /// `/System` operations — info, ping, restart, shutdown.
  late final JellyfinSystemApi system = JellyfinSystemApi(_http);

  /// `/Users` operations — login, list, manage.
  late final JellyfinUserApi user = JellyfinUserApi(_http);

  /// `/QuickConnect` operations — passwordless device pairing.
  late final JellyfinQuickConnectApi quickConnect = JellyfinQuickConnectApi(
    _http,
  );

  /// `/Library` operations — top-level library browsing and refresh.
  late final JellyfinLibraryApi library = JellyfinLibraryApi(_http);

  /// `/Items` operations — query, fetch, and mutate library items.
  late final JellyfinItemsApi items = JellyfinItemsApi(_http);

  /// `/Playlists` operations — create, edit, and play playlists.
  late final JellyfinPlaylistsApi playlists = switch (_parent) {
    null => JellyfinPlaylistsApi(_http),
    final parent => JellyfinPlaylistsApi.sharing(_http, parent.playlists),
  };

  /// `/Search` operations — global hint search.
  late final JellyfinSearchApi search = JellyfinSearchApi(_http);

  /// `/Audio` streaming endpoints.
  late final JellyfinAudioApi audio = JellyfinAudioApi(_http);

  /// `/Videos` streaming endpoints.
  late final JellyfinVideosApi videos = JellyfinVideosApi(_http);

  /// HLS adaptive-streaming endpoints.
  late final JellyfinHlsApi hls = JellyfinHlsApi(_http);

  /// `/MediaInfo` operations — playback info, bitrate testing.
  late final JellyfinMediaInfoApi mediaInfo = JellyfinMediaInfoApi(_http);

  /// `/Trickplay` operations — scrubbing thumbnails.
  late final JellyfinTrickplayApi trickplay = JellyfinTrickplayApi(_http);

  /// `/Subtitles` operations — fetch and configure subtitle tracks.
  late final JellyfinSubtitlesApi subtitles = JellyfinSubtitlesApi(_http);

  /// `/Images` operations — poster, backdrop, and chapter artwork.
  late final JellyfinImagesApi images = JellyfinImagesApi(_http);

  /// Playback reporting — start, progress, stopped events.
  late final JellyfinPlaybackApi playback = JellyfinPlaybackApi(_http);

  /// `/Sessions` operations — list and control active sessions.
  late final JellyfinSessionsApi sessions = JellyfinSessionsApi(_http);

  /// `/UserData` operations — favourites, play state, ratings.
  late final JellyfinUserDataApi userData = JellyfinUserDataApi(_http);

  /// `/InstantMix` operations — generate on-the-fly mixes.
  late final JellyfinInstantMixApi instantMix = JellyfinInstantMixApi(_http);

  /// `/LiveTv` operations — channels, recordings, EPG.
  late final JellyfinLiveTvApi liveTv = JellyfinLiveTvApi(_http);

  /// `/SyncPlay` operations — group playback coordination.
  late final JellyfinSyncPlayApi syncPlay = JellyfinSyncPlayApi(_http);

  /// `/Shows` operations — TV-show specific browsing helpers.
  late final JellyfinTvShowsApi tvShows = JellyfinTvShowsApi(_http);

  /// `/Movies` operations — movie-specific browsing helpers.
  late final JellyfinMoviesApi movies = JellyfinMoviesApi(_http);

  /// `/Suggestions` operations — recommendations for a user.
  late final JellyfinSuggestionsApi suggestions = JellyfinSuggestionsApi(_http);

  /// `/MediaSegments` operations — intro/credit markers.
  late final JellyfinMediaSegmentsApi mediaSegments = JellyfinMediaSegmentsApi(
    _http,
  );

  /// `/Items/Filters` operations — facet/filter queries.
  late final JellyfinFilterApi filter = JellyfinFilterApi(_http);

  /// `/Artists` operations — list and fetch music artists.
  late final JellyfinArtistsApi artists = JellyfinArtistsApi(_http);

  /// `/DisplayPreferences` operations — per-user UI state.
  late final JellyfinDisplayPreferencesApi displayPreferences =
      JellyfinDisplayPreferencesApi(_http);

  /// `/Lyrics` operations — fetch and upload synchronized lyrics.
  late final JellyfinLyricsApi lyrics = JellyfinLyricsApi(_http);

  /// `/Channels` operations — virtual channels (plugins).
  late final JellyfinChannelsApi channels = JellyfinChannelsApi(_http);

  /// `/Collections` operations — manage user-defined collections.
  late final JellyfinCollectionApi collection = JellyfinCollectionApi(_http);

  /// `/UserViews` operations — per-user library shortcuts.
  late final JellyfinUserViewsApi userViews = JellyfinUserViewsApi(_http);

  /// `/Persons` operations — list and fetch people (artists included
  /// since Jellyfin 12).
  late final JellyfinPersonsApi persons = JellyfinPersonsApi(_http);

  /// `/Studios` operations — list and fetch studios.
  late final JellyfinStudiosApi studios = JellyfinStudiosApi(_http);

  /// `/Genres` operations — list and fetch genres.
  late final JellyfinGenresApi genres = JellyfinGenresApi(_http);

  /// `/Years` operations — list and fetch year groupings.
  late final JellyfinYearsApi years = JellyfinYearsApi(_http);

  /// `/Localization` operations — cultures, countries, options.
  late final JellyfinLocalizationApi localization = JellyfinLocalizationApi(
    _http,
  );

  /// `/Items/RemoteSearch` operations — metadata provider lookup.
  late final JellyfinItemLookupApi itemLookup = JellyfinItemLookupApi(_http);

  /// `/Library/VirtualFolders` operations — manage library roots.
  late final JellyfinLibraryStructureApi libraryStructure =
      JellyfinLibraryStructureApi(_http);

  /// `/Plugins` operations — list, configure, uninstall plugins.
  late final JellyfinPluginsApi plugins = JellyfinPluginsApi(_http);

  /// `/Packages` operations — repository catalog and install.
  late final JellyfinPackagesApi packages = JellyfinPackagesApi(_http);

  /// `/ScheduledTasks` operations — server background jobs.
  late final JellyfinScheduledTasksApi scheduledTasks =
      JellyfinScheduledTasksApi(_http);

  /// `/System/Configuration` operations — server settings.
  late final JellyfinConfigurationApi configuration = JellyfinConfigurationApi(
    _http,
  );

  /// `/Environment` operations — server-host filesystem browsing.
  late final JellyfinEnvironmentApi environment = JellyfinEnvironmentApi(_http);

  /// `/Startup` operations — first-run wizard endpoints.
  late final JellyfinStartupApi startup = JellyfinStartupApi(_http);

  /// `/Branding` operations — login splash, custom CSS.
  late final JellyfinBrandingApi branding = JellyfinBrandingApi(_http);

  /// `/Auth/Keys` operations — long-lived API key management.
  late final JellyfinApiKeyApi apiKey = JellyfinApiKeyApi(_http);

  /// `/Backup` operations — server backup and restore.
  late final JellyfinBackupApi backup = JellyfinBackupApi(_http);

  /// `/Dashboard` operations — admin dashboard data.
  late final JellyfinDashboardApi dashboard = JellyfinDashboardApi(_http);

  /// `/System/ActivityLog` operations — audit log entries.
  late final JellyfinActivityLogApi activityLog = JellyfinActivityLogApi(_http);

  /// `/ClientLog` operations — client-side log submission.
  late final JellyfinClientLogApi clientLog = JellyfinClientLogApi(_http);

  /// `/RemoteImages` operations — fetch images from metadata providers.
  late final JellyfinRemoteImageApi remoteImage = JellyfinRemoteImageApi(_http);

  /// `/Devices` operations — list and manage registered devices.
  late final JellyfinDevicesApi devices = JellyfinDevicesApi(_http);

  /// `/Notifications` operations — server notification feed.
  late final JellyfinNotificationsApi notifications =
      _parent?.notifications ?? JellyfinNotificationsApi(_http);

  /// Creates a client bound to [credentials] and (optionally) a server URL.
  ///
  /// Pass an [httpClient] to choose the HTTP stack — for example a
  /// `CupertinoClient` (`package:cupertino_http`) or a `CronetClient`
  /// (`package:cronet_http`) for HTTP/2 and the system proxy, or a
  /// `MockClient` in tests. An injected client is yours to close; the one
  /// created when you pass none is closed by [close].
  ///
  /// [connectTimeout] bounds the handshake (on the default client) and,
  /// together with [receiveTimeout], the wait for the response headers.
  /// [receiveTimeout] also bounds every pause in a response body.
  ///
  /// Responses of [jsonIsolateThreshold] bytes or more are decoded, and
  /// for the typed calls parsed into models, on a background isolate.
  ///
  /// [retryPolicy] resends idempotent requests after transient failures;
  /// it is off ([JellyfinRetryPolicy.none]) unless you pass one.
  JellyfinClient({
    required JellyfinCredentials credentials,
    String? baseUrl,
    http.Client? httpClient,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
    int jsonIsolateThreshold = JellyfinConnection.defaultJsonIsolateThreshold,
    JellyfinRetryPolicy retryPolicy = JellyfinRetryPolicy.none,
  }) : _http = JellyfinConnection(
         credentials: credentials,
         baseUrl: baseUrl,
         httpClient: httpClient,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
         jsonIsolateThreshold: jsonIsolateThreshold,
         retryPolicy: retryPolicy,
       ),
       _parent = null;

  JellyfinClient._scoped(JellyfinClient parent, JellyfinCancelToken token)
    : _http = JellyfinConnection.scoped(parent._http, token),
      _parent = parent;

  /// A view of this client whose every request is cancelled by
  /// [cancelToken].
  ///
  /// The view shares this client's HTTP connection pool, server and
  /// session — `setSession`, `connect` and `close` on either affect both —
  /// and costs nothing to create, so make one per page, filter or search
  /// term and cancel it when that is abandoned:
  ///
  /// ```dart
  /// _pageToken?.cancel();
  /// final token = _pageToken = JellyfinCancelToken();
  /// final albums = await jf
  ///     .withCancelToken(token)
  ///     .items
  ///     .list(includeItemTypes: const [JellyfinItemKind.musicAlbum], limit: 50);
  /// ```
  ///
  /// A cancelled call throws a [JellyfinException] of type
  /// [JellyfinErrorType.cancelled]. [notifications] is the same object as
  /// on this client: a WebSocket is not a request and is not cancelled.
  JellyfinClient withCancelToken(JellyfinCancelToken cancelToken) =>
      JellyfinClient._scoped(this, cancelToken);

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
  ///
  /// An open [notifications] socket is left open: it was authenticated
  /// when it connected. Close it with `notifications.close()`.
  void clearSession() {
    _http.token = null;
    _http.userId = null;
  }

  /// Drop base URL, token, and user id.
  void disconnect() {
    clearSession();
    _http.baseUrl = null;
  }

  /// Closes the HTTP client this client created and the [notifications]
  /// socket, if one is open. Requests made afterwards — through this
  /// client or any [withCancelToken] view — fail with
  /// [JellyfinErrorType.state]. Does nothing to an injected `httpClient`.
  void close() {
    _http.close();
    unawaited(notifications.close());
  }

  /// Escape hatch: issue an arbitrary request through the same HTTP client
  /// and headers as the sub-APIs.
  ///
  /// Use this for endpoints not yet covered by the typed sub-APIs.
  /// Throws [JellyfinException] on failure (same as every other call).
  ///
  /// The body is decoded per [responseType] (JSON by default). A `List`
  /// in [queryParameters] repeats the key once per element.
  Future<JellyfinResponse<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, Object?>? queryParameters,
    Object? data,
    Map<String, String>? extraHeaders,
    bool absoluteUrl = false,
    JellyfinResponseType? responseType,
    JellyfinCancelToken? cancelToken,
  }) => _http.request<T>(
    path,
    method: method,
    queryParameters: queryParameters,
    data: data,
    extraHeaders: extraHeaders,
    absoluteUrl: absoluteUrl,
    responseType: responseType,
    cancelToken: cancelToken,
  );

  /// Convenience for byte GETs (artwork, small files). The whole body is
  /// held in memory; use [requestStream] for media downloads.
  Future<JellyfinResponse<Uint8List>> requestBytes(
    String url, {
    Map<String, Object?>? queryParameters,
    bool absoluteUrl = true,
    JellyfinCancelToken? cancelToken,
  }) => _http.requestBytes(
    url,
    queryParameters: queryParameters,
    absoluteUrl: absoluteUrl,
    cancelToken: cancelToken,
  );

  /// Streams a GET body as it arrives — for downloads, so a whole track
  /// never sits in memory. Write [JellyfinStreamedResponse.stream] to a
  /// file sink; cancelling the subscription closes the connection.
  ///
  /// A pause in the body longer than the receive timeout fails the stream
  /// unless [stallTimeout] is `false`.
  Future<JellyfinStreamedResponse> requestStream(
    String url, {
    Map<String, Object?>? queryParameters,
    Map<String, String>? extraHeaders,
    bool absoluteUrl = true,
    bool stallTimeout = true,
    JellyfinCancelToken? cancelToken,
  }) => _http.requestStream(
    url,
    queryParameters: queryParameters,
    extraHeaders: extraHeaders,
    absoluteUrl: absoluteUrl,
    stallTimeout: stallTimeout,
    cancelToken: cancelToken,
  );

  // ─── Lightweight method aliases ────────────────────────────────────

  /// Shorthand for a `GET` [request].
  Future<JellyfinResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, String>? extraHeaders,
    JellyfinCancelToken? cancelToken,
  }) => request<T>(
    path,
    queryParameters: queryParameters,
    extraHeaders: extraHeaders,
    cancelToken: cancelToken,
  );

  /// Shorthand for a `POST` [request].
  Future<JellyfinResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, String>? extraHeaders,
    JellyfinCancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
    extraHeaders: extraHeaders,
    cancelToken: cancelToken,
  );

  /// Shorthand for a `DELETE` [request].
  Future<JellyfinResponse<T>> delete<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, String>? extraHeaders,
    JellyfinCancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'DELETE',
    queryParameters: queryParameters,
    extraHeaders: extraHeaders,
    cancelToken: cancelToken,
  );
}
