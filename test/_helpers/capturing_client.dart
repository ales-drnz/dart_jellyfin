// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// An [http.Client] that records every outgoing request and answers with
/// a canned body, so tests can assert on what went on the wire.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:http/http.dart' as http;

/// One request as it left the client.
final class CapturedRequest {
  /// HTTP method.
  final String method;

  /// Full URI, query string included.
  final Uri uri;

  /// Request headers.
  final Map<String, String> headers;

  /// Request body bytes.
  final Uint8List body;

  CapturedRequest(this.method, this.uri, this.headers, this.body);

  /// The body decoded as JSON.
  Object? get json => jsonDecode(utf8.decode(body));
}

/// A canned answer.
final class CannedResponse {
  final int status;
  final List<int> body;
  final String contentType;

  CannedResponse(
    this.status,
    this.body, {
    this.contentType = 'application/json',
  });

  CannedResponse.json(Object? value, {this.status = 200})
      : body = utf8.encode(jsonEncode(value)),
        contentType = 'application/json';
}

class CapturingAdapter extends http.BaseClient {
  /// Every request, oldest first.
  final List<CapturedRequest> requests = [];

  /// The most recent request, or `null` if none has been made yet.
  CapturedRequest? get last => requests.isEmpty ? null : requests.last;

  /// JSON body returned for every request without a [respond] override.
  /// The default satisfies both the `QueryResult` envelope and the
  /// bare-list endpoints.
  String body = jsonEncode({
    'Items': <dynamic>[],
    'TotalRecordCount': 0,
  });

  /// Picks the answer per request; `null` falls back to [body].
  CannedResponse? Function(CapturedRequest request)? respond;

  /// Every query parameter of the last request, decoded from the URI
  /// that actually went on the wire — so a list shows up as repeated
  /// values only if it was really encoded that way.
  Map<String, List<String>> get query => last!.uri.queryParametersAll;

  /// The raw, still-percent-encoded query string of the last request.
  String get rawQuery => last!.uri.query;

  /// Path of the last request, without the query string.
  String get path => last!.uri.path;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final captured =
        CapturedRequest(request.method, request.url, request.headers, bytes);
    requests.add(captured);
    final canned =
        respond?.call(captured) ?? CannedResponse(200, utf8.encode(body));
    return http.StreamedResponse(
      Stream.value(canned.body),
      canned.status,
      contentLength: canned.body.length,
      request: request,
      headers: {'content-type': canned.contentType},
    );
  }
}

JellyfinClient capturingClient(
  CapturingAdapter adapter, {
  int jsonIsolateThreshold = 0,
}) {
  final client = JellyfinClient(
    credentials: const JellyfinCredentials(
      client: 'Finova',
      device: 'iPhone',
      deviceId: 'abc-uuid',
      version: '1.2.3',
    ),
    baseUrl: 'https://jf.example.test',
    httpClient: adapter,
    // 0 sends every typed parse through an isolate, so a parse closure that
    // captures something unsendable fails here rather than in production.
    jsonIsolateThreshold: jsonIsolateThreshold,
  );
  client.connect('https://jf.example.test');
  client.setSession(token: 'tok', userId: 'user-1');
  return client;
}
