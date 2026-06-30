// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Semantic categories for failures coming out of [JellyfinClient].
enum JellyfinErrorType {
  /// Transport-level failure — DNS, TCP, TLS, socket reset.
  connection,

  /// Connect/send/receive deadline exceeded.
  timeout,

  /// HTTP `401`/`403` — missing or rejected credentials.
  auth,

  /// HTTP `404` — resource does not exist on the server.
  notFound,

  /// HTTP `4xx` other than auth/notFound — malformed request.
  badRequest,

  /// HTTP `5xx` — server-side failure.
  serverError,

  /// Response body could not be decoded into the expected shape.
  parse,

  /// Client used in an invalid state — e.g. no base URL set.
  state,

  /// The request was cancelled by the caller via a `CancelToken` before it
  /// completed. Not an error condition — distinct from [unknown] so callers
  /// can ignore cancellations instead of logging them as failures.
  cancelled,

  /// Anything that doesn't fit the other categories.
  unknown;

  /// Whether a retry might succeed (connection/timeout only).
  bool get isRetriable =>
      this == JellyfinErrorType.connection || this == JellyfinErrorType.timeout;

  /// Whether the failure is an authentication/authorization problem.
  bool get isAuthError => this == JellyfinErrorType.auth;

  /// Maps an HTTP status code to the matching category.
  static JellyfinErrorType fromHttpStatus(int status) {
    if (status == 401 || status == 403) return JellyfinErrorType.auth;
    if (status == 404) return JellyfinErrorType.notFound;
    if (status >= 500) return JellyfinErrorType.serverError;
    if (status >= 400) return JellyfinErrorType.badRequest;
    return JellyfinErrorType.unknown;
  }
}
