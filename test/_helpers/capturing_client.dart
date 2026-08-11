// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// A [JellyfinClient] wired to a Dio [HttpClientAdapter] that answers
/// every request with a canned Jellyfin envelope and records the
/// [RequestOptions] it was given.
///
/// The point is to assert on the *outgoing* request. Jellyfin answers
/// 200 whether or not a filter bound, so a test that only inspects the
/// returned entities cannot tell a scoped query from an unscoped one —
/// the query string is the only place the defect is visible.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dio/dio.dart';

/// Captures the [RequestOptions] of the last request and replies with a
/// canned empty `QueryResult`, so the wrapper's parsing succeeds.
class CapturingAdapter implements HttpClientAdapter {
  /// The [RequestOptions] of the most recent request, or `null` if none
  /// has been made yet.
  RequestOptions? last;

  /// JSON body returned for every request. The default satisfies both
  /// the `QueryResult` envelope and the bare-list endpoints.
  String body = jsonEncode({
    'Items': <dynamic>[],
    'TotalRecordCount': 0,
  });

  /// Every query parameter of the last request, decoded from the URI
  /// that actually went on the wire — so a list shows up as repeated
  /// values only if it was really encoded that way.
  Map<String, List<String>> get query => last!.uri.queryParametersAll;

  /// The raw, still-percent-encoded query string of the last request.
  String get rawQuery => last!.uri.query;

  /// Path of the last request, without the query string.
  String get path => last!.uri.path;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds an authenticated [JellyfinClient] whose traffic is captured by
/// [adapter] instead of reaching a server.
JellyfinClient capturingClient(CapturingAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = JellyfinClient(
    credentials: const JellyfinCredentials(
      client: 'Finova',
      device: 'iPhone',
      deviceId: 'abc-uuid',
      version: '1.2.3',
    ),
    baseUrl: 'https://jf.example.test',
    dio: dio,
  );
  client.connect('https://jf.example.test');
  client.setSession(token: 'tok', userId: 'user-1');
  return client;
}
