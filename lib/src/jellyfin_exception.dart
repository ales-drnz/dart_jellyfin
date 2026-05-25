// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dio/dio.dart';

import 'jellyfin_error_type.dart';

/// Exception thrown by [JellyfinClient] for any failed operation.
class JellyfinException implements Exception {
  final String message;
  final JellyfinErrorType type;
  final int? statusCode;
  final String? path;
  final Object? cause;

  const JellyfinException(
    this.message, {
    this.type = JellyfinErrorType.unknown,
    this.statusCode,
    this.path,
    this.cause,
  });

  factory JellyfinException.fromDio(DioException e, {String? path}) {
    final code = e.response?.statusCode;
    final type = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        JellyfinErrorType.timeout,
      DioExceptionType.connectionError => JellyfinErrorType.connection,
      DioExceptionType.badResponse when code != null =>
        JellyfinErrorType.fromHttpStatus(code),
      DioExceptionType.cancel => JellyfinErrorType.unknown,
      _ => JellyfinErrorType.unknown,
    };
    return JellyfinException(
      e.message ?? 'Jellyfin request failed',
      type: type,
      statusCode: code,
      path: path ?? e.requestOptions.path,
      cause: e,
    );
  }

  bool get isAuthError => type.isAuthError;
  bool get isRetriable => type.isRetriable;

  @override
  String toString() {
    final parts = <String>['JellyfinException($type)'];
    if (statusCode != null) parts.add('status=$statusCode');
    if (path != null) parts.add('path=$path');
    parts.add(message);
    return parts.join(' ');
  }
}
