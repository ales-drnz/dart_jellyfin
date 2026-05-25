// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// `/Sessions/*` — list active sessions, send remote-control commands,
/// register your own client as a cast target.
///
/// Maps the `Session` OpenAPI tag (~16 operations). Together with the
/// per-session playstate ([JellyfinPlaybackApi]) this is the full
/// "cast / remote control" surface.
class JellyfinSessionsApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinSessionsApi(this._http);

  // ─── Listing ───────────────────────────────────────────────────────

  /// GET `/Sessions` — every active session the server can see.
  ///
  /// [controllableByUserId] limits the result to sessions the named
  /// user is allowed to control (useful when the caller is an admin).
  /// [activeWithinSeconds] keeps only recently-active sessions.
  Future<List<JellyfinSession>> list({
    String? controllableByUserId,
    int? activeWithinSeconds,
    String? deviceId,
  }) async {
    final qp = <String, dynamic>{};
    if (controllableByUserId != null) {
      qp['controllableByUserId'] = controllableByUserId;
    }
    if (activeWithinSeconds != null) {
      qp['activeWithinSeconds'] = activeWithinSeconds;
    }
    if (deviceId != null) qp['deviceId'] = deviceId;
    final res = await _http.request<List<dynamic>>(
      '/Sessions',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinSession.fromJson(e),
    ];
  }

  // ─── Capabilities (register this client as a cast target) ──────────

  /// POST `/Sessions/Capabilities` — tells the server which playback
  /// surfaces this client can handle (Play, Pause, Seek, Volume, …)
  /// and which media types it knows. Other clients will list this one
  /// as a cast target once capabilities are registered.
  Future<void> postCapabilities({
    List<String> playableMediaTypes = const ['Audio'],
    List<String> supportedCommands = const ['Play', 'Pause', 'Stop'],
    bool supportsMediaControl = false,
    bool supportsPersistentIdentifier = true,
  }) async {
    await _http.request<void>(
      '/Sessions/Capabilities',
      method: 'POST',
      queryParameters: {
        'playableMediaTypes': playableMediaTypes.join(','),
        'supportedCommands': supportedCommands.join(','),
        'supportsMediaControl': supportsMediaControl,
        'supportsPersistentIdentifier': supportsPersistentIdentifier,
      },
    );
  }

  /// POST `/Sessions/Capabilities/Full` — same as [postCapabilities]
  /// but accepts the full `ClientCapabilitiesDto` body for advanced
  /// declarations (device profile, app store url, icon url, …).
  Future<void> postFullCapabilities({
    required Map<String, dynamic> body,
  }) async {
    await _http.request<void>(
      '/Sessions/Capabilities/Full',
      method: 'POST',
      data: body,
    );
  }

  /// POST `/Sessions/Logout` — tells the server the user logged out;
  /// the session is closed and any pending now-playing entries cleared.
  Future<void> reportSessionEnded() async {
    await _http.request<void>('/Sessions/Logout', method: 'POST');
  }

  /// POST `/Sessions/Viewing` — used to tell the server the user is
  /// browsing (NOT playing) a given item. Drives "now viewing"
  /// indicators on shared accounts.
  Future<void> reportViewing({required String itemId}) async {
    await _http.request<void>(
      '/Sessions/Viewing',
      method: 'POST',
      queryParameters: {'itemId': itemId},
    );
  }

  // ─── Remote control: instruct a session to play / control / display ─

  /// POST `/Sessions/{sessionId}/Playing` — instruct a remote session
  /// to start playing a list of items. The `playCommand` controls
  /// whether the target queues, replaces, or inserts.
  Future<void> play({
    required String sessionId,
    required List<String> itemIds,
    String playCommand = 'PlayNow', // PlayNow | PlayNext | PlayLast | Shuffle
    int? startPositionTicks,
    int? startIndex,
    String? mediaSourceId,
  }) async {
    final qp = <String, dynamic>{
      'playCommand': playCommand,
      'itemIds': itemIds.join(','),
    };
    if (startPositionTicks != null) {
      qp['startPositionTicks'] = startPositionTicks;
    }
    if (startIndex != null) qp['startIndex'] = startIndex;
    if (mediaSourceId != null) qp['mediaSourceId'] = mediaSourceId;
    await _http.request<void>(
      '/Sessions/$sessionId/Playing',
      method: 'POST',
      queryParameters: qp,
    );
  }

  /// POST `/Sessions/{sessionId}/Playing/{command}` — send a
  /// playstate command (Pause, NextTrack, Seek, …) to a remote
  /// session. See [PlaystateCommand] for the accepted values.
  Future<void> sendPlaystateCommand({
    required String sessionId,
    required String command,
    int? seekPositionTicks,
    String? controllingUserId,
  }) async {
    final qp = <String, dynamic>{};
    if (seekPositionTicks != null) {
      qp['seekPositionTicks'] = seekPositionTicks;
    }
    if (controllingUserId != null) {
      qp['controllingUserId'] = controllingUserId;
    }
    await _http.request<void>(
      '/Sessions/$sessionId/Playing/$command',
      method: 'POST',
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  /// POST `/Sessions/{sessionId}/System/{command}` — system-level
  /// commands (`GoHome`, `GoToSettings`, `Restart`, …).
  Future<void> sendSystemCommand({
    required String sessionId,
    required String command,
  }) async {
    await _http.request<void>(
      '/Sessions/$sessionId/System/$command',
      method: 'POST',
    );
  }

  /// POST `/Sessions/{sessionId}/Command/{command}` — general command
  /// shorthand (`VolumeUp`, `VolumeDown`, `Mute`, `Unmute`,
  /// `ToggleMute`, `SetVolume`, `ToggleFullscreen`, …).
  Future<void> sendCommand({
    required String sessionId,
    required String command,
  }) async {
    await _http.request<void>(
      '/Sessions/$sessionId/Command/$command',
      method: 'POST',
    );
  }

  /// POST `/Sessions/{sessionId}/Command` — full command body, for
  /// commands that take arguments (`SetVolume` with `Volume`,
  /// `SetSubtitleStreamIndex`, `DisplayContent`, …).
  Future<void> sendFullCommand({
    required String sessionId,
    required String name,
    Map<String, dynamic> arguments = const {},
  }) async {
    await _http.request<void>(
      '/Sessions/$sessionId/Command',
      method: 'POST',
      data: {'Name': name, 'Arguments': arguments},
    );
  }

  /// POST `/Sessions/{sessionId}/Message` — push a banner / toast to
  /// the remote session.
  Future<void> sendMessage({
    required String sessionId,
    required String text,
    String? header,
    int? timeoutMs,
  }) async {
    final qp = <String, dynamic>{'text': text};
    if (header != null) qp['header'] = header;
    if (timeoutMs != null) qp['timeoutMs'] = timeoutMs;
    await _http.request<void>(
      '/Sessions/$sessionId/Message',
      method: 'POST',
      queryParameters: qp,
    );
  }

  /// POST `/Sessions/{sessionId}/Viewing` — instruct a session to
  /// open the detail page of an item (without starting playback).
  Future<void> displayContent({
    required String sessionId,
    required String itemId,
    required String itemType,
    required String itemName,
  }) async {
    await _http.request<void>(
      '/Sessions/$sessionId/Viewing',
      method: 'POST',
      queryParameters: {
        'itemId': itemId,
        'itemType': itemType,
        'itemName': itemName,
      },
    );
  }

  // ─── User association (multi-user sessions) ────────────────────────

  /// POST `/Sessions/{sessionId}/User/{userId}` — associate an extra
  /// user with the session (used by shared / family-mode setups).
  Future<void> addUser({
    required String sessionId,
    required String userId,
  }) async {
    await _http.request<void>(
      '/Sessions/$sessionId/User/$userId',
      method: 'POST',
    );
  }

  /// DELETE `/Sessions/{sessionId}/User/{userId}` — remove the user
  /// association.
  Future<void> removeUser({
    required String sessionId,
    required String userId,
  }) async {
    await _http.request<void>(
      '/Sessions/$sessionId/User/$userId',
      method: 'DELETE',
    );
  }
}

/// String constants for `sendPlaystateCommand(command: …)`.
abstract final class JellyfinPlaystateCommand {
  /// Stop playback.
  static const stop = 'Stop';
  /// Pause playback.
  static const pause = 'Pause';
  /// Resume from pause.
  static const unpause = 'Unpause';
  /// Skip to the next track in the queue.
  static const nextTrack = 'NextTrack';
  /// Jump back to the previous track.
  static const previousTrack = 'PreviousTrack';
  /// Seek to `seekPositionTicks`.
  static const seek = 'Seek';
  /// Rewind a small fixed amount.
  static const rewind = 'Rewind';
  /// Fast-forward a small fixed amount.
  static const fastForward = 'FastForward';
  /// Toggle between play and pause.
  static const playPause = 'PlayPause';
}

/// String constants for `sendCommand(command: …)`.
abstract final class JellyfinGeneralCommand {
  /// Increase volume one notch.
  static const volumeUp = 'VolumeUp';
  /// Decrease volume one notch.
  static const volumeDown = 'VolumeDown';
  /// Mute audio.
  static const mute = 'Mute';
  /// Unmute audio.
  static const unmute = 'Unmute';
  /// Toggle the mute state.
  static const toggleMute = 'ToggleMute';
  /// Set absolute volume — requires a `Volume` argument via [JellyfinSessionsApi.sendFullCommand].
  static const setVolume = 'SetVolume';
  /// Switch audio track — requires an `Index` argument.
  static const setAudioStreamIndex = 'SetAudioStreamIndex';
  /// Switch subtitle track — requires an `Index` argument.
  static const setSubtitleStreamIndex = 'SetSubtitleStreamIndex';
  /// Toggle fullscreen mode on the remote client.
  static const toggleFullscreen = 'ToggleFullscreen';
  /// Toggle the on-screen-display / overlay menu.
  static const toggleOsdMenu = 'ToggleOsdMenu';
  /// Show an item's detail page — requires `ItemId`/`ItemType`/`ItemName` arguments.
  static const displayContent = 'DisplayContent';
}
