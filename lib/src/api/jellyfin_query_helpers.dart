// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// What the sub-APIs share when they ask and read. Not exported.
library;

import '../jellyfin_connection.dart';
import '../jellyfin_exception.dart';

/// The answer of [call], or `null` when the server answers `404`: for a
/// read of one thing by its id or name, a confirmed absence is an answer,
/// not a failure. Every other error is thrown as it came.
Future<T?> nullOnNotFound<T>(Future<T?> Function() call) async {
  try {
    return await call();
  } on JellyfinException catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}

/// Requests that read one thing.
extension JellyfinLookups on JellyfinConnection {
  /// [JellyfinConnection.requestJson], answering `null` on a `404` (see
  /// [nullOnNotFound]) and for an empty body, as [parse] decides.
  Future<R?> requestJsonOrNull<R>(
    String path,
    R? Function(Object? json) parse, {
    Map<String, Object?>? queryParameters,
  }) => nullOnNotFound(
    () => requestJson(path, parse, queryParameters: queryParameters),
  );
}
