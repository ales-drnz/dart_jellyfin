Catch and classify failures, cancel calls, retry them, and walk paged results.

## Exceptions

Every call throws a `JellyfinException` on failure:

```dart
try {
  await jellyfin.items.list(parentId: musicLibraryId);
} on JellyfinException catch (e) {
  print('${e.type} ${e.statusCode} ${e.message}');
}
```

`JellyfinErrorType` is one of `connection`, `timeout`, `auth`,
`notFound`, `badRequest`, `serverError`, `parse`, `state`, `cancelled`
and `unknown`. The exception also carries `statusCode`, `path`, `cause`,
`stackTrace`, the whole error `body` the server sent (`message` holds at
most its first 512 bytes) and `retryAfter`, the server's `Retry-After`
on a `429` or `503`.

A typed answer of the wrong shape throws a `parse` error. A lookup
(`items.byId()`, `devices.info()`, `scheduledTasks.byId()`,
`syncPlay.group()`, `playlists.userAccess()`) returns `null` when there
is no such item. Another empty single-object answer is the model's
defaults, except for `collection.create()`, which throws a `parse` error
when the answer holds no id.

Invalid arguments are programming errors and throw `ArgumentError`
instead, such as a malformed `backgroundColor` in `images.url()`.

## Classifying a failure

```dart
try {
  await jellyfin.items.list(parentId: musicLibraryId);
} on JellyfinException catch (e) {
  if (e.isCancelled) {
    // the caller cancelled: not a failure
  } else if (e.isTransient) {
    scheduleRetry(); // network failure, 5xx or 429
  } else if (e.isAuthError) {
    await signInAgain(); // 401 or 403: the token was rejected
  } else if (e.isNotFound) {
    showError('Gone from the server');
  } else {
    showError(e.message);
  }
}
```

| Getter | True for |
| :--- | :--- |
| `isNetworkFailure` | No answer at all: the connection failed or timed out |
| `isTransient` | May pass later: a network failure, a 5xx or a `429` |
| `isNotFound` | The server answered `404` |
| `isCancelled` | The request was cancelled through a cancel token |
| `isAuthError` | `401` or `403` |

The library never fetches a new token on its own. `isAuthError` is the
signal to run `authenticateByName()` or Quick Connect again.

## Cancellation

`withCancelToken()` returns a view of the client whose every sub-API
call is cancelled by one `JellyfinCancelToken`. The view shares the
connection pool, the server and the session, and costs nothing to
create, so make one for each page, filter or search term:

```dart
JellyfinCancelToken? pageToken;

Future<void> showAlbums(String libraryId) async {
  pageToken?.cancel(); // drop the previous page's requests
  final token = pageToken = JellyfinCancelToken();
  try {
    final albums = await jellyfin.withCancelToken(token).items.list(
          parentId: libraryId,
          includeItemTypes: const [JellyfinItemKind.musicAlbum],
          limit: 50,
        );
    print(albums.items.length);
  } on JellyfinException catch (e) {
    if (e.isCancelled) return; // not a failure
    rethrow;
  }
}
```

A cancelled call throws a `JellyfinException` of type `cancelled`. A
token cancels once; make a new one for the next page. `request()`,
`requestBytes()`, `requestStream()`, `downloadToFile()` and
`images.fetch()` also take a `cancelToken` directly. The notifications
socket is not a request, and a token does not close it.

## Retries

Retries are off by default. Pass a `JellyfinRetryPolicy` to resend
idempotent requests after a transient failure:

```dart
final jellyfin = JellyfinClient(
  credentials: credentials,
  retryPolicy: const JellyfinRetryPolicy(), // up to 3 attempts in all
);

// Or tune it:
const patient = JellyfinRetryPolicy(
  maxAttempts: 5,
  initialDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 10),
);
```

The defaults are `maxAttempts: 3` (the first attempt included),
`initialDelay: 300 ms` and `maxDelay: 5 s`.

Only `GET` and `HEAD` are resent, and only after no answer at all, a
`502`, `503`, `504` or `429`. A `500` is not retried. The wait grows
exponentially with full jitter, a `Retry-After` header (in seconds) is
honored up to `maxDelay`, and a cancel token also cancels the wait.
Opening a stream is retried too; a body already flowing is not replayed.

## Paging

`JellyfinPaging.items()` and `JellyfinPaging.pages()` walk any paged call
as a stream, one request per page, nothing fetched ahead:

```dart
final tracks = JellyfinPaging.items(
  (start, size) async => (await jellyfin.items.list(
    parentId: music.id,
    includeItemTypes: const [JellyfinItemKind.audio],
    sortBy: const [JellyfinSortField.sortName],
    startIndex: start,
    limit: size,
    enableTotalRecordCount: false,
  ))
      .items,
  pageSize: 200,
);
await for (final track in tracks) {
  print(track.name);
}
```

Paging stops at the first page shorter than `pageSize`, or after `limit`
items when you pass one. Cancelling the subscription stops it before the
next request; pair it with a cancel token (see Cancellation above) to drop
the request in flight too.
