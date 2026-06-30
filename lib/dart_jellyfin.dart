// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Pure-Dart client for Jellyfin.
///
/// Entry point is [JellyfinClient] — a stateful façade that holds the
/// device identity, access token, and user id across calls and exposes
/// one sub-API per domain:
///
/// ```dart
/// final jf = JellyfinClient(
///   baseUrl: 'https://jellyfin.example.com',
///   credentials: const JellyfinCredentials(
///     client: 'Finova',
///     device: 'iPhone',
///     deviceId: '2f5b-uuid',
///     version: '1.0.0',
///   ),
/// );
///
/// final auth = await jf.user.authenticateByName(
///   username: 'me', password: 'pw',
/// );
/// jf.setSession(token: auth.accessToken, userId: auth.user.id);
///
/// final views = await jf.library.userViews();
/// final music = views.firstWhere((v) => v.collectionType == 'music');
/// final albums = await jf.items.list(
///   parentId: music.id,
///   includeItemTypes: const ['MusicAlbum'],
///   sortBy: const ['SortName'],
///   limit: 50,
/// );
/// ```
library;

export 'src/api/jellyfin_activity_log_api.dart';
export 'src/api/jellyfin_api_key_api.dart';
export 'src/api/jellyfin_artists_api.dart';
export 'src/api/jellyfin_audio_api.dart';
export 'src/api/jellyfin_backup_api.dart';
export 'src/api/jellyfin_branding_api.dart';
export 'src/api/jellyfin_channels_api.dart';
export 'src/api/jellyfin_client_log_api.dart';
export 'src/api/jellyfin_collection_api.dart';
export 'src/api/jellyfin_configuration_api.dart';
export 'src/api/jellyfin_dashboard_api.dart';
export 'src/api/jellyfin_devices_api.dart';
export 'src/api/jellyfin_display_preferences_api.dart';
export 'src/api/jellyfin_environment_api.dart';
export 'src/api/jellyfin_filter_api.dart';
export 'src/api/jellyfin_genres_api.dart';
export 'src/api/jellyfin_hls_api.dart';
export 'src/api/jellyfin_images_api.dart';
export 'src/api/jellyfin_instant_mix_api.dart';
export 'src/api/jellyfin_item_lookup_api.dart';
export 'src/api/jellyfin_items_api.dart';
export 'src/api/jellyfin_library_api.dart';
export 'src/api/jellyfin_library_structure_api.dart';
export 'src/api/jellyfin_live_tv_api.dart';
export 'src/api/jellyfin_localization_api.dart';
export 'src/api/jellyfin_lyrics_api.dart';
export 'src/api/jellyfin_media_info_api.dart';
export 'src/api/jellyfin_media_segments_api.dart';
export 'src/api/jellyfin_movies_api.dart';
export 'src/api/jellyfin_music_genres_api.dart';
export 'src/api/jellyfin_notifications_api.dart';
export 'src/api/jellyfin_packages_api.dart';
export 'src/api/jellyfin_persons_api.dart';
export 'src/api/jellyfin_playback_api.dart';
export 'src/api/jellyfin_playlists_api.dart';
export 'src/api/jellyfin_plugins_api.dart';
export 'src/api/jellyfin_quick_connect_api.dart';
export 'src/api/jellyfin_remote_image_api.dart';
export 'src/api/jellyfin_scheduled_tasks_api.dart';
export 'src/api/jellyfin_search_api.dart';
export 'src/api/jellyfin_sessions_api.dart';
export 'src/api/jellyfin_startup_api.dart';
export 'src/api/jellyfin_studios_api.dart';
export 'src/api/jellyfin_subtitles_api.dart';
export 'src/api/jellyfin_suggestions_api.dart';
export 'src/api/jellyfin_sync_play_api.dart';
export 'src/api/jellyfin_system_api.dart';
export 'src/api/jellyfin_tmdb_api.dart';
export 'src/api/jellyfin_trailers_api.dart';
export 'src/api/jellyfin_trickplay_api.dart';
export 'src/api/jellyfin_tv_shows_api.dart';
export 'src/api/jellyfin_user_api.dart';
export 'src/api/jellyfin_user_data_api.dart';
export 'src/api/jellyfin_user_views_api.dart';
export 'src/api/jellyfin_videos_api.dart';
export 'src/api/jellyfin_years_api.dart';
export 'src/jellyfin_auth_header.dart' show JellyfinAuthHeader;
export 'src/jellyfin_client.dart';
export 'src/jellyfin_credentials.dart';
export 'src/jellyfin_error_type.dart';
export 'src/jellyfin_exception.dart';
export 'src/jellyfin_models.dart';
