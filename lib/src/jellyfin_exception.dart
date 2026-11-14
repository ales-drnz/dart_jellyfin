// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// @docImport 'jellyfin_client.dart';
library;

import 'jellyfin_error_type.dart';

/// Exception thrown by [JellyfinClient] for any failed operation.
///
/// {@category Errors and paging}
final class JellyfinException implements Exception {
  final String _message;
  final String? _path;

  /// Human-readable description of the failure. A token in a URL it
  /// quotes (`ApiKey`, `api_key`) reads `REDACTED`.
  String get message => _redact(_message);

  /// Semantic category of the failure.
  final JellyfinErrorType type;

  /// HTTP status code, when the failure came from an HTTP response.
  final int? statusCode;

  /// Request path/URL that triggered the failure, when known, with the
  /// value of `ApiKey` and `api_key` replaced by `REDACTED`: the signed
  /// stream and download URLs carry the session token there.
  String? get path => _path == null ? null : _redact(_path);

  /// Underlying error (for example the transport's `ClientException`).
  /// Kept as it came: its text can quote the request URL with a token in
  /// it, so log [toString], not this.
  final Object? cause;

  /// How long the server asked the client to wait (`Retry-After`, on a
  /// `429` or `503`), when it said.
  final Duration? retryAfter;

  /// The body of the error answer as text, whole, when the server sent
  /// one ([message] holds at most its first 512 bytes). Kept so a refusal
  /// the package does not recognise can still be read, logged or shown.
  /// Kept as it came, not redacted.
  final String? body;

  /// The originating stack trace, when captured. Preserves the async stack
  /// across catch-and-rethrow so crash reporters can pinpoint the failure.
  final StackTrace? stackTrace;

  /// Creates an exception with the given message and optional metadata.
  const JellyfinException(
    String message, {
    this.type = JellyfinErrorType.unknown,
    this.statusCode,
    String? path,
    this.cause,
    this.stackTrace,
    this.retryAfter,
    this.body,
  }) : _message = message,
       _path = path;

  /// [text] with the value of every `ApiKey` and `api_key` query
  /// parameter replaced by `REDACTED`.
  static String _redact(String text) =>
      text.replaceAllMapped(_secret, (m) => '${m[1]}REDACTED');

  static final RegExp _secret = RegExp(
    r'([?&;](?:apikey|api_key)=)[^&#\s]*',
    caseSensitive: false,
  );

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

  @override
  String toString() {
    final parts = <String>['JellyfinException($type)'];
    if (statusCode != null) parts.add('status=$statusCode');
    if (path != null) parts.add('path=$path');
    parts.add(message);
    return parts.join(' ');
  }
}
