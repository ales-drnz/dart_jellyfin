// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dio/dio.dart';

import 'jellyfin_error_type.dart';

/// Exception thrown by [JellyfinClient] for any failed operation.
class JellyfinException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// Semantic category of the failure.
  final JellyfinErrorType type;

  /// HTTP status code, when the failure came from an HTTP response.
  final int? statusCode;

  /// Request path/URL that triggered the failure, when known.
  final String? path;

  /// Underlying error (typically the originating [DioException]).
  final Object? cause;

  /// The originating stack trace, when captured. Preserves the async stack
  /// across catch-and-rethrow so crash reporters can pinpoint the failure.
  final StackTrace? stackTrace;

  /// Creates an exception with the given message and optional metadata.
  const JellyfinException(
    this.message, {
    this.type = JellyfinErrorType.unknown,
    this.statusCode,
    this.path,
    this.cause,
    this.stackTrace,
  });

  /// Converts a Dio failure into a [JellyfinException] with a mapped [type].
  /// A response-body decode failure (Dio surfaces a [FormatException] under
  /// [DioExceptionType.unknown]) maps to [JellyfinErrorType.parse].
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
      DioExceptionType.cancel => JellyfinErrorType.cancelled,
      DioExceptionType.unknown when e.error is FormatException =>
        JellyfinErrorType.parse,
      _ => JellyfinErrorType.unknown,
    };
    return JellyfinException(
      e.message ?? 'Jellyfin request failed',
      type: type,
      statusCode: code,
      path: path ?? e.requestOptions.path,
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  /// Whether [type] is an authentication/authorization failure.
  bool get isAuthError => type.isAuthError;

  /// Whether a retry might succeed for this failure.
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
