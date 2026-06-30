// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dio/dio.dart';

import 'jellyfin_auth_header.dart';
import 'jellyfin_credentials.dart';
import 'jellyfin_error_type.dart';
import 'jellyfin_exception.dart';

/// Internal HTTP transport shared by every sub-API. Not exported.
class JellyfinConnection {
  final Dio _dio;

  /// Client identity sent on every request via the auth header.
  final JellyfinCredentials credentials;

  String? _baseUrl;
  String? _token;

  /// Authenticated user id, or `null` if no session is active.
  String? userId;

  /// Creates a connection bound to [credentials] and an optional [baseUrl].
  JellyfinConnection({
    required this.credentials,
    String? baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
    _dio.options.headers['Accept'] = 'application/json';
    if (baseUrl != null) this.baseUrl = baseUrl;
    _applyAuthHeader();
  }

  /// Server root URL without a trailing slash, or `null` if not connected.
  String? get baseUrl => _baseUrl;

  /// Current access token, or `null` if no session is active.
  String? get token => _token;

  /// `true` when [baseUrl], [token], and [userId] are all set.
  bool get isAuthenticated =>
      _baseUrl != null && _token != null && userId != null;

  /// Returns the authenticated [userId], or throws a [JellyfinException] of
  /// type [JellyfinErrorType.state] when no session user is set.
  ///
  /// Centralizes the "no user" guard shared by every user-scoped endpoint —
  /// sub-APIs call this instead of re-checking [userId] themselves.
  String requireUserId() {
    final id = userId;
    if (id == null) {
      throw const JellyfinException(
        'No user — call JellyfinClient.setSession() with a userId first.',
        type: JellyfinErrorType.state,
      );
    }
    return id;
  }

  /// Sets the server root URL, stripping a trailing `/` if present.
  set baseUrl(String? value) {
    if (value == null) {
      _baseUrl = null;
      return;
    }
    _baseUrl =
        value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Sets the access token and refreshes the cached auth headers.
  set token(String? value) {
    _token = value;
    _applyAuthHeader();
  }

  void _applyAuthHeader() {
    // Only the `Authorization: MediaBrowser` header is sent. `build()` already
    // embeds `Token="$token"` in that header, which is the sole auth path the
    // server honors on 10.12 (where `EnableLegacyAuthorization` defaults to
    // false) and 10.13 (where legacy auth is removed). The deprecated
    // `X-Emby-Authorization` and `X-MediaBrowser-Token` headers are no longer
    // sent — they are off-by-default in 10.12 and dead weight thereafter.
    _dio.options.headers['Authorization'] =
        JellyfinAuthHeader.build(credentials, token: _token);
  }

  /// Issues an HTTP request relative to [baseUrl] (or absolute when
  /// `absoluteUrl` is `true`), wrapping Dio failures in [JellyfinException].
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? extraHeaders,
    bool absoluteUrl = false,
    ResponseType? responseType,
    CancelToken? cancelToken,
  }) async {
    final url = absoluteUrl ? path : _resolve(path);
    try {
      return await _dio.request<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          headers: extraHeaders,
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      throw JellyfinException.fromDio(e, path: url);
    }
  }

  /// Convenience for byte-stream GETs (artwork, downloads).
  Future<Response<List<int>>> requestBytes(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool absoluteUrl = true,
    CancelToken? cancelToken,
  }) =>
      request<List<int>>(
        url,
        queryParameters: queryParameters,
        absoluteUrl: absoluteUrl,
        responseType: ResponseType.bytes,
        cancelToken: cancelToken,
      );

  String _resolve(String path) {
    if (_baseUrl == null) {
      throw const JellyfinException(
        'JellyfinClient.connect() has not been called — no base URL is set.',
        type: JellyfinErrorType.state,
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (!path.startsWith('/')) return '$_baseUrl/$path';
    return '$_baseUrl$path';
  }
}
