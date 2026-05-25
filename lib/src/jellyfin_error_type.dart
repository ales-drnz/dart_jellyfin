// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Semantic categories for failures coming out of [JellyfinClient].
enum JellyfinErrorType {
  connection,
  timeout,
  auth,
  notFound,
  badRequest,
  serverError,
  parse,
  state,
  unknown;

  bool get isRetriable =>
      this == JellyfinErrorType.connection ||
      this == JellyfinErrorType.timeout;

  bool get isAuthError => this == JellyfinErrorType.auth;

  static JellyfinErrorType fromHttpStatus(int status) {
    if (status == 401 || status == 403) return JellyfinErrorType.auth;
    if (status == 404) return JellyfinErrorType.notFound;
    if (status >= 500) return JellyfinErrorType.serverError;
    if (status >= 400) return JellyfinErrorType.badRequest;
    return JellyfinErrorType.unknown;
  }
}
