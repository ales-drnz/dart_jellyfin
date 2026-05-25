// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_models.dart';

/// Quick Connect flow.
///
/// 1. Caller (the device that wants in) calls [initiate] → shows the
///    6-character [JellyfinQuickConnectState.code] to the user.
/// 2. User authorises on another already-logged-in device.
/// 3. Caller polls [state] until [JellyfinQuickConnectState.authenticated]
///    is true.
/// 4. Caller calls
///    [JellyfinUserApi.authenticateWithQuickConnect] with the now-final
///    secret to get the real access token.
class JellyfinQuickConnectApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinQuickConnectApi(this._http);

  /// Whether the server allows Quick Connect.
  Future<bool> enabled() async {
    final res = await _http.request<dynamic>('/QuickConnect/Enabled');
    return res.data == true;
  }

  /// Start a new Quick Connect attempt — returns the `Secret` to keep
  /// (poll with it) and the `Code` to display to the user.
  Future<JellyfinQuickConnectState> initiate() async {
    final res = await _http.request<Map<String, dynamic>>(
      '/QuickConnect/Initiate',
      method: 'POST',
    );
    return JellyfinQuickConnectState.fromJson(res.data ?? const {});
  }

  /// Poll Quick Connect state.
  ///
  /// Once `authenticated` flips to true, call
  /// [JellyfinUserApi.authenticateWithQuickConnect] with the same secret.
  Future<JellyfinQuickConnectState> state(String secret) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/QuickConnect/Connect',
      queryParameters: {'secret': secret},
    );
    return JellyfinQuickConnectState.fromJson(res.data ?? const {});
  }

  /// Approve a code from an already-authenticated device — i.e. the
  /// "authorise other device" flow.
  Future<bool> authorize(String code) async {
    final res = await _http.request<dynamic>(
      '/QuickConnect/Authorize',
      method: 'POST',
      queryParameters: {'code': code},
    );
    return res.data == true;
  }
}
