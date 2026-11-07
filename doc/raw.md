For a route the sub-APIs do not cover, call it directly. These calls use
the same HTTP client, headers, retry policy and `JellyfinException`
translation as the sub-APIs.

## Raw request

```dart
final response = await jellyfin.request<Map<String, Object?>>(
  '/Items',
  queryParameters: {
    'userId': jellyfin.userId,
    'includeItemTypes': 'Audio',
    'recursive': true,
    'limit': 0,
  },
);
final total = response.data?['TotalRecordCount'];
```

`request()` returns a `JellyfinResponse<T>` with `data`, `statusCode`,
`headers` and `uri`. It takes `method` (`'POST'`, `'DELETE'`),
`extraHeaders`, `data`, `absoluteUrl` and `cancelToken`; a `List` in
`queryParameters` repeats the key once for each value. An `extraHeaders`
entry replaces the header of the same name, whatever its case, and an
empty value removes it: `{'Authorization': ''}` sends no `Authorization`
header. `responseType` picks the decoding: `JellyfinResponseType.json`
(the default: JSON when the server says so, text otherwise), `plain`
(UTF-8 text) or `bytes` (a `Uint8List`). `get()`, `post()` and `delete()` are shorthands.

```dart
final m3u8 = await jellyfin.request<String>(
  '/Audio/${track.id}/main.m3u8',
  responseType: JellyfinResponseType.plain,
);
print(m3u8.data);
```

## Raw bytes

```dart
final response = await jellyfin.requestBytes(
  '/Items/${item.id}/Download',
  absoluteUrl: false,
);
final bytes = response.data;
```

`requestBytes()` holds the whole body in memory, which suits artwork and
small files. Its `url` is absolute by default, for a URL a builder made;
with `absoluteUrl: false` it is a path on the server. For media, stream
the body (see Streamed body below) or write it to disk with `downloadToFile()`, in the [Events and downloads](https://pub.dev/documentation/dart_jellyfin/latest/topics/Events%20and%20downloads-topic.html) topic.

## Streamed body

```dart
final (url, _) = jellyfin.audio.directStreamUrl(itemId: track.id);
final res = await jellyfin.requestStream(url);
print('${res.contentLength} bytes, ${res.contentType}');
await for (final chunk in res.stream) {
  sink.add(chunk);
}
```

`requestStream()` returns a `JellyfinStreamedResponse` as soon as the
headers arrive. Listen to `stream` once; cancelling the subscription
closes the connection. A pause in the body longer than `receiveTimeout`
fails the stream, unless you pass `stallTimeout: false`.
