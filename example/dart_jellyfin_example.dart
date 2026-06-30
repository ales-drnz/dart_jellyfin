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
  );

  jellyfin.connect('https://jellyfin.example.com');

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
}
