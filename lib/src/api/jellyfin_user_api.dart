// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../jellyfin_connection.dart';
import '../jellyfin_error_type.dart';
import '../jellyfin_exception.dart';
import '../jellyfin_models.dart';

/// `/Users/*` endpoints — authentication + profile.
class JellyfinUserApi {
  final JellyfinConnection _http;

  /// Wraps a [JellyfinConnection]; obtain through [JellyfinClient].
  JellyfinUserApi(this._http);

  /// Authenticate with username + password.
  ///
  /// On success, both [JellyfinAuthResult.accessToken] and
  /// [JellyfinAuthResult.user.id] should be propagated to the client
  /// via [JellyfinClient.setSession].
  Future<JellyfinAuthResult> authenticateByName({
    required String username,
    required String password,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Users/AuthenticateByName',
      method: 'POST',
      data: {'Username': username, 'Pw': password},
    );
    final data = res.data;
    if (data == null) {
      throw const JellyfinException(
        'Empty response from /Users/AuthenticateByName',
        type: JellyfinErrorType.parse,
      );
    }
    final auth = JellyfinAuthResult.fromJson(data);
    if (auth.accessToken.isEmpty) {
      throw const JellyfinException(
        'Authentication succeeded but no AccessToken was returned',
        type: JellyfinErrorType.auth,
      );
    }
    return auth;
  }

  /// Authenticate using a Quick Connect secret obtained from
  /// [JellyfinQuickConnectApi].
  Future<JellyfinAuthResult> authenticateWithQuickConnect({
    required String secret,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Users/AuthenticateWithQuickConnect',
      method: 'POST',
      data: {'Secret': secret},
    );
    final data = res.data;
    if (data == null) {
      throw const JellyfinException(
        'Empty response from /Users/AuthenticateWithQuickConnect',
        type: JellyfinErrorType.parse,
      );
    }
    return JellyfinAuthResult.fromJson(data);
  }

  /// Current user (`/Users/Me`).
  Future<JellyfinUser> currentUser() async {
    final res = await _http.request<Map<String, dynamic>>('/Users/Me');
    return JellyfinUser.fromJson(res.data ?? const {});
  }

  /// Public users (`/Users/Public`) — does not require authentication,
  /// returns the avatars + names for the server's login picker.
  Future<List<JellyfinUser>> publicUsers() async {
    final res = await _http.request<List<dynamic>>('/Users/Public');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinUser.fromJson(e),
    ];
  }

  /// List all users (admin only).
  Future<List<JellyfinUser>> list() async {
    final res = await _http.request<List<dynamic>>('/Users');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) JellyfinUser.fromJson(e),
    ];
  }

  /// `GET /Users/{userId}` — fetch a single user by id (admin only).
  /// Returns null on 404.
  Future<JellyfinUser?> byId(String userId) async {
    try {
      final res = await _http.request<Map<String, dynamic>>(
        '/Users/$userId',
      );
      final data = res.data;
      if (data == null) return null;
      return JellyfinUser.fromJson(data);
    } on JellyfinException catch (e) {
      if (e.type == JellyfinErrorType.notFound) return null;
      rethrow;
    }
  }

  /// `POST /Users/New?name={name}` — create a new user (admin only).
  /// The server picks the user id.
  Future<JellyfinUser> create({
    required String name,
    String? password,
  }) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Users/New',
      method: 'POST',
      data: {
        'Name': name,
        if (password != null) 'Password': password,
      },
    );
    return JellyfinUser.fromJson(res.data ?? const {});
  }

  /// `POST /Users?userId={id}` — replace a user's profile fields
  /// (admin only). Pass the full [JellyfinUser] body.
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> userBody,
  }) async {
    await _http.request<void>(
      '/Users',
      method: 'POST',
      queryParameters: {'userId': userId},
      data: userBody,
    );
  }

  /// `POST /Users/{userId}/Policy` — replace a user's policy
  /// (admin/role/library access). Admin only.
  Future<void> updatePolicy({
    required String userId,
    required Map<String, dynamic> policy,
  }) async {
    await _http.request<void>(
      '/Users/$userId/Policy',
      method: 'POST',
      data: policy,
    );
  }

  /// `POST /Users/Configuration?userId={id}` — update the user's
  /// configuration (subtitle defaults, display order, etc.).
  Future<void> updateConfiguration({
    String? userId,
    required Map<String, dynamic> configuration,
  }) async {
    final uid = userId ?? _http.userId;
    final qp = <String, dynamic>{};
    if (uid != null) qp['userId'] = uid;
    await _http.request<void>(
      '/Users/Configuration',
      method: 'POST',
      queryParameters: qp.isEmpty ? null : qp,
      data: configuration,
    );
  }

  /// `POST /Users/Password` — change the current user's password.
  /// Set both [currentPassword] and [newPassword]; pass
  /// `resetPassword: true` (and leave the password fields null) to
  /// clear the password.
  Future<void> updatePassword({
    String? userId,
    String? currentPassword,
    String? newPassword,
    bool resetPassword = false,
  }) async {
    await _http.request<void>(
      '/Users/Password',
      method: 'POST',
      data: {
        if (userId != null) 'UserId': userId,
        if (currentPassword != null) 'CurrentPw': currentPassword,
        if (newPassword != null) 'NewPw': newPassword,
        'ResetPassword': resetPassword,
      },
    );
  }

  /// `DELETE /Users/{userId}` — delete a user (admin only).
  Future<void> delete(String userId) async {
    await _http.request<void>('/Users/$userId', method: 'DELETE');
  }

  /// `POST /Users/ForgotPassword?enteredUsername={u}` — start the
  /// forgot-password flow. Returns the server's response (which
  /// includes the action — usually `ContactAdmin` or `PinCode`).
  Future<Map<String, dynamic>> forgotPassword(String username) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Users/ForgotPassword',
      method: 'POST',
      data: {'EnteredUsername': username},
    );
    return res.data ?? const {};
  }

  /// `POST /Users/ForgotPassword/Pin?pin={code}` — submit the PIN
  /// returned by [forgotPassword] (server places it in a known file
  /// on disk for the admin to read).
  Future<Map<String, dynamic>> forgotPasswordPin(String pin) async {
    final res = await _http.request<Map<String, dynamic>>(
      '/Users/ForgotPassword/Pin',
      method: 'POST',
      data: {'Pin': pin},
    );
    return res.data ?? const {};
  }

  /// `GET /Auth/Providers` — list of authentication providers
  /// configured on the server (returned as raw maps).
  Future<List<Map<String, dynamic>>> authProviders() async {
    final res = await _http.request<List<dynamic>>('/Auth/Providers');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }

  /// `GET /Auth/PasswordResetProviders` — list of password-reset
  /// providers configured on the server.
  Future<List<Map<String, dynamic>>> passwordResetProviders() async {
    final res = await _http.request<List<dynamic>>('/Auth/PasswordResetProviders');
    final list = res.data ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) e,
    ];
  }
}
