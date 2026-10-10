// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

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

  /// Underlying error (for example the transport's `ClientException`).
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
