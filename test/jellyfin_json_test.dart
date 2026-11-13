// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The lenient JSON readers every model is built on, and the model
/// members that read through them.
library;

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:dart_jellyfin/src/jellyfin_json.dart';
import 'package:dart_jellyfin/src/jellyfin_parsing.dart';
import 'package:test/test.dart';

void main() {
  group('asString', () {
    test('a string, a number and a boolean are text', () {
      expect(asString('a'), 'a');
      expect(asString(12), '12');
      expect(asString(1.5), '1.5');
      expect(asString(true), 'true');
    });

    test('null, an object and an array are not', () {
      expect(asString(null), isNull);
      expect(asString(const {'Id': 'x'}), isNull);
      expect(asString(const ['x']), isNull);
    });
  });

  test('asBool reads only booleans', () {
    expect(asBool(true), isTrue);
    expect(asBool(false), isFalse);
    expect(asBool('true'), isNull);
    expect(asBool(1), isNull);
    expect(asBool(null), isNull);
  });

  test('asInt and asDouble read numbers and numeric strings', () {
    expect(asInt(3), 3);
    expect(asInt(3.9), 3);
    expect(asInt('42'), 42);
    expect(asInt('x'), isNull);
    expect(asInt(const <Object?>[]), isNull);
    expect(asDouble(3), 3.0);
    expect(asDouble('1.5'), 1.5);
    expect(asDouble(true), isNull);
  });

  group('asUtcDateTime', () {
    test('reads the seven-digit fraction Jellyfin sends', () {
      expect(
        asUtcDateTime('2026-11-08T17:06:04.2882251Z'),
        DateTime.utc(2026, 11, 8, 17, 6, 4, 288, 225),
      );
    });

    test('an offset is converted to UTC', () {
      expect(
        asUtcDateTime('2026-11-08T18:00:00+01:00'),
        DateTime.utc(2026, 11, 8, 17),
      );
    });

    test('the .NET minimum date, a date never set, is null', () {
      expect(asUtcDateTime('0001-01-01T00:00:00.0000000Z'), isNull);
      expect(asUtcDateTime('0001-01-01T00:00:00'), isNull);
    });

    test('anything that is not a timestamp is null', () {
      expect(asUtcDateTime('yesterday'), isNull);
      expect(asUtcDateTime(1700000000), isNull);
      expect(asUtcDateTime(null), isNull);
    });
  });

  test('asTicksDuration: ten million ticks are a second', () {
    expect(asTicksDuration(10000000), const Duration(seconds: 1));
    expect(asTicksDuration(15), const Duration(microseconds: 1));
    expect(asTicksDuration(null), isNull);
  });

  test('the list and map readers skip what does not fit', () {
    expect(asStringList(const ['a', 1, null, 'b']), ['a', 'b']);
    expect(asStringList('a'), isEmpty);
    expect(
      asObjectList(const [
        {'Name': 'a'},
        'x',
        null,
      ], (m) => m['Name']),
      ['a'],
    );
    expect(asObjectList(const {'Name': 'a'}, (m) => m), isEmpty);
    expect(asStringMap(const {'a': 'b', 'c': 1, 2: 'd'}), {'a': 'b'});
    expect(
      fieldStrings(const [
        {'Name': 'Rock'},
        {'Name': 3},
        'x',
      ], 'Name'),
      ['Rock'],
    );
    expect(asObject(const ['x']), isEmpty);
  });

  group('parsers', () {
    Matcher parseError() => throwsA(
      isA<JellyfinException>().having(
        (e) => e.type,
        'type',
        JellyfinErrorType.parse,
      ),
    );

    test('queryResultOf: an empty body is an empty page, a list throws', () {
      final parse = queryResultOf((m) => m['Id']);
      expect(parse(null).items, isEmpty);
      expect(
        parse(const {
          'Items': [
            {'Id': 'a'},
            7,
          ],
          'TotalRecordCount': 9,
        }),
        isA<JellyfinQueryResult<Object?>>()
            .having((r) => r.items, 'items', ['a'])
            .having((r) => r.totalRecordCount, 'total', 9),
      );
      expect(() => parse(const <Object?>[]), parseError());
    });

    test('listOf: an empty body is an empty list, an object throws', () {
      final parse = listOf((m) => m['Id']);
      expect(parse(null), isEmpty);
      expect(
        parse(const [
          {'Id': 'a'},
          'x',
        ]),
        ['a'],
      );
      expect(() => parse(const <String, Object?>{}), parseError());
    });

    test('objectOf, objectOrEmptyOf and requiredObjectOf on an empty body', () {
      expect(objectOf((m) => m)(null), isNull);
      expect(objectOrEmptyOf((m) => m.length)(null), 0);
      expect(() => requiredObjectOf((m) => m)(null), parseError());
    });

    test('requiredObjectOf wants each key present and not empty', () {
      final parse = requiredObjectOf((m) => m['Id'], keys: const ['Id']);
      expect(parse(const {'Id': 'a'}), 'a');
      expect(() => parse(const <String, Object?>{}), parseError());
      expect(() => parse(const {'Id': ''}), parseError());
      expect(() => parse(const {'Id': null}), parseError());
    });
  });

  group('models', () {
    test('a session never checked in has no lastPlaybackCheckIn', () {
      final session = JellyfinSession.fromJson(const {
        'Id': 's',
        'LastPlaybackCheckIn': '0001-01-01T00:00:00.0000000Z',
        'LastActivityDate': '2026-11-08T17:06:04.2882251Z',
      });
      expect(session.lastPlaybackCheckIn, isNull);
      expect(session.lastActivityDate, isNotNull);
    });

    test('user data carries the rating', () {
      final data = JellyfinUserData.fromJson(const {
        'Rating': 7.5,
        'Likes': true,
        'IsFavorite': true,
      });
      expect(data.rating, 7.5);
      expect(data.likes, isTrue);
      expect(JellyfinUserData.fromJson(const {}).rating, isNull);
    });

    test('a task result carries its task key, id and name', () {
      final result = JellyfinTaskResult.fromJson(const {
        'Status': 'Completed',
        'Key': 'RefreshLibrary',
        'Id': 'abc',
        'Name': 'Scan Media Library',
      });
      expect(result.key, 'RefreshLibrary');
      expect(result.id, 'abc');
      expect(result.name, 'Scan Media Library');
    });

    test('display preferences: copyWith changes one field', () {
      final prefs = JellyfinDisplayPreferences.fromJson(const {
        'Id': 'usersettings',
        'Client': 'emby',
        'SortBy': 'SortName',
        'ShowBackdrop': true,
        'CustomPrefs': {'a': 'b'},
      });
      final changed = prefs.copyWith(sortBy: 'DateCreated');
      expect(changed.toJson(), {
        'Id': 'usersettings',
        'Client': 'emby',
        'SortBy': 'DateCreated',
        'ShowBackdrop': true,
        'CustomPrefs': {'a': 'b'},
      });
      expect(changed.raw, same(prefs.raw));
    });

    test('toString names the thing', () {
      final item = JellyfinItem.fromJson(const {
        'Id': 'i1',
        'Name': 'Kind of Blue',
        'Type': 'MusicAlbum',
      });
      expect('$item', 'JellyfinItem(MusicAlbum i1, Kind of Blue)');
      expect(
        '${JellyfinUser.fromJson(const {'Id': 'u1', 'Name': 'me'})}',
        'JellyfinUser(u1, me)',
      );
      expect(
        '${JellyfinQueryResult<JellyfinItem>(items: [item], totalRecordCount: 40)}',
        'JellyfinQueryResult<JellyfinItem>(1 of 40)',
      );
    });
  });

  group('JellyfinUnknownEvent.isMalformed', () {
    test('a type the package does not know is not malformed', () {
      final event = JellyfinEvent.fromFrame(const {
        'MessageType': 'NeverHeardOf',
        'Data': 1,
      });
      expect(
        event,
        isA<JellyfinUnknownEvent>().having(
          (e) => e.isMalformed,
          'isMalformed',
          isFalse,
        ),
      );
    });

    test('a known type with Data of the wrong shape is', () {
      final event = JellyfinEvent.fromFrame(const {
        'MessageType': 'UserDataChanged',
        'Data': 'oops',
      });
      expect(
        event,
        isA<JellyfinUnknownEvent>().having(
          (e) => e.isMalformed,
          'isMalformed',
          isTrue,
        ),
      );
    });
  });
}
