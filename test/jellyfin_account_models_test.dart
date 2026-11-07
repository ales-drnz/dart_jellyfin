// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The account models, decoded from bodies shaped like Jellyfin 12.4 answers.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

const Map<String, Object?> _empty = {};

void main() {
  group('accounts', () {
    test('JellyfinStartupUser', () {
      final u = JellyfinStartupUser.fromJson(const {'Name': 'admin'});
      expect(u.name, 'admin');
      expect(u.password, isNull);
      expect(JellyfinStartupUser.fromJson(_empty).name, isNull);
    });

    test('JellyfinForgotPasswordResult and JellyfinPinRedeemResult', () {
      final f = JellyfinForgotPasswordResult.fromJson(const {
        'Action': 'PinCode',
        'PinFile': '/config/passwordreset1.json',
        'PinExpirationDate': '2026-11-07T18:00:00Z',
      });
      expect(f.action, 'PinCode');
      expect(f.pinExpirationDate, DateTime.utc(2026, 11, 7, 18));
      expect(JellyfinForgotPasswordResult.fromJson(_empty).action, isNull);

      final p = JellyfinPinRedeemResult.fromJson(const {
        'Success': true,
        'UsersReset': ['admin'],
      });
      expect(p.success, isTrue);
      expect(p.usersReset, ['admin']);
      expect(JellyfinPinRedeemResult.fromJson(_empty).success, isFalse);
    });
  });
}
