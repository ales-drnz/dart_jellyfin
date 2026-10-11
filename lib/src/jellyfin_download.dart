// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'jellyfin_client.dart';
import 'jellyfin_error_type.dart';
import 'jellyfin_exception.dart';
import 'transport/jellyfin_cancel_token.dart';

/// Downloads straight to disk.
extension JellyfinDownload on JellyfinClient {
  /// Streams [url] into the file at [path] and returns the bytes written.
  ///
  /// The body is written as it arrives — a whole track never sits in
  /// memory — to `$path.part`, renamed to [path] only once complete, so
  /// [path] either holds the whole file or does not exist: a failure, a
  /// stall past the receive timeout or a cancellation through
  /// [cancelToken] removes the partial file and throws a [JellyfinException]
  /// (of type [JellyfinErrorType.cancelled] for a cancellation).
  ///
  /// [onProgress] is called after each chunk with the bytes received so
  /// far and the total when the server sent a `Content-Length`.
  Future<int> downloadToFile(
    String url,
    String path, {
    Map<String, Object?>? queryParameters,
    bool absoluteUrl = true,
    JellyfinCancelToken? cancelToken,
    void Function(int received, int? total)? onProgress,
  }) async {
    final res = await requestStream(
      url,
      queryParameters: queryParameters,
      absoluteUrl: absoluteUrl,
      cancelToken: cancelToken,
    );
    final part = File('$path.part');
    await part.parent.create(recursive: true);
    final sink = part.openWrite();
    var received = 0;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, res.contentLength);
      }
      await sink.flush();
      await sink.close();
      await part.rename(path);
      return received;
    } catch (e, st) {
      await sink.close().catchError((Object _) {});
      if (part.existsSync()) await part.delete();
      if (e is JellyfinException) rethrow;
      throw JellyfinException(
        'Download to $path failed: $e',
        path: url,
        cause: e,
        stackTrace: st,
      );
    }
  }
}
