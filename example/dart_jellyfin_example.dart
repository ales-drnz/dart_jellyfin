// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:dart_jellyfin/dart_jellyfin.dart';

Future<void> main() async {
  final jellyfin = JellyfinClient(
    credentials: const JellyfinCredentials(
      client: 'MyApp',
      device: 'CLI',
      deviceId: 'example-device',
      version: '1.0.0',
    ),
    // Opt in to resending idempotent requests after transient failures.
    retryPolicy: const JellyfinRetryPolicy(),
  );

  jellyfin.connect('https://jellyfin.example.com');

  try {
    final auth = await jellyfin.user.authenticateByName(
      username: 'user',
      password: 'password',
    );
    print('Logged in as ${auth.user.name}');

    jellyfin.setSession(token: auth.accessToken, userId: auth.user.id);

    final views = await jellyfin.userViews.list();
    for (final v in views.items) {
      print('${v.name} (${v.collectionType})');
    }

    final music = views.items.where((v) => v.isMusic).firstOrNull;
    if (music == null) return;

    // Walk the library's albums page by page; every request made through
    // the view can be cancelled with one token.
    final token = JellyfinCancelToken();
    final scoped = jellyfin.withCancelToken(token);
    final albums = JellyfinPaging.items(
      (start, size) async => (await scoped.items.list(
        parentId: music.id,
        includeItemTypes: const [JellyfinItemKind.musicAlbum],
        sortBy: const [JellyfinSortField.sortName],
        startIndex: start,
        limit: size,
        fields: JellyfinItemsApi.browseFields,
        enableTotalRecordCount: false,
      ))
          .items,
      pageSize: 50,
      limit: 200,
    );
    await for (final album in albums) {
      print('${album.name} - ${album.albumArtist ?? '?'}');
    }
  } on JellyfinException catch (e) {
    if (e.isCancelled) return;
    print('Failed: ${e.type} ${e.statusCode ?? ''} ${e.message}');
  } finally {
    jellyfin.close();
  }
}
