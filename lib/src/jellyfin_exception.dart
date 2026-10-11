// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'jellyfin_client.dart';
import 'jellyfin_error_type.dart';

/// Exception thrown by [JellyfinClient] for any failed operation.
final class JellyfinException implements Exception {
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

  /// How long the server asked the client to wait (`Retry-After`, on a
  /// `429` or `503`), when it said.
  final Duration? retryAfter;

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
    this.retryAfter,
  });

  /// No answer from the server at all: the connection failed or timed out.
  /// The server may be down or unreachable — not the same as an answer that
  /// says no.
  bool get isNetworkFailure =>
      type == JellyfinErrorType.connection || type == JellyfinErrorType.timeout;

  /// A failure that may pass if the same request is sent again later: a
  /// network failure, a 5xx (the server failed or is overloaded), or
  /// `429 Too Many Requests`. Not an auth error, another 4xx, a parse or
  /// state error, or a cancellation.
  bool get isTransient =>
      isNetworkFailure ||
      type == JellyfinErrorType.serverError ||
      statusCode == 429;

  /// The server answered `404`: what was asked for does not exist. For a
  /// read this is a confirmed absence, not a failure to answer.
  bool get isNotFound => type == JellyfinErrorType.notFound;

  /// The caller cancelled the request. Not a failure: ignore it rather
  /// than reporting it.
  bool get isCancelled => type == JellyfinErrorType.cancelled;

  /// Whether [type] is an authentication/authorization failure.
  bool get isAuthError => type.isAuthError;

  /// Same as [isNetworkFailure].
  @Deprecated(
    'Use isNetworkFailure, or isTransient to include 5xx and 429. '
    'Removed in 0.4.',
  )
  bool get isRetriable => isNetworkFailure;

  @override
  String toString() {
    final parts = <String>['JellyfinException($type)'];
    if (statusCode != null) parts.add('status=$statusCode');
    if (path != null) parts.add('path=$path');
    parts.add(message);
    return parts.join(' ');
  }
}
