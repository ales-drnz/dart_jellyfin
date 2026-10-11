// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Contract test against the pinned OpenAPI document.
///
/// Every public method of every sub-API is called through `dart:mirrors`
/// with stand-in arguments — every optional parameter filled, so every
/// query parameter the wrapper can send is sent — and each request that
/// leaves the client is checked against `docs/jellyfin-openapi-stable.json`
/// (Jellyfin 12.2.0; source and checksum in `_helpers/spec_watchdog.dart`):
///
/// * its path matches a documented route,
/// * that route documents its HTTP method,
/// * every query parameter is one the route declares.
///
/// Jellyfin ignores a query parameter it does not know and answers 200 with
/// a *wider* result, so a misspelt or misplaced parameter is invisible
/// everywhere else. Here it fails the suite — unless it is listed in
/// [_allowedExtras] with the reason it is right anyway.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';
import 'dart:typed_data';

import 'package:dart_jellyfin/dart_jellyfin.dart';
import 'package:test/test.dart';

import '_helpers/capturing_client.dart';

/// Query parameters a route does not declare, with why they are sent.
/// Keys are `METHOD /spec/route`, values parameter name → reason.
const _allowedExtras = <String, Map<String, String>>{
  // ApiKey authenticates URLs a player opens itself (no auth header). The
  // 12.x document declares only the Authorization header (securitySchemes:
  // CustomAuthentication) and no query parameter for it, but the server
  // reads the token from `ApiKey` on any route, case-insensitively: 12.2
  // answered /Users/Me?ApiKey= and ?apikey= with 200, and ?api_key= (the
  // 10.x spelling) with 401.
  '*': {
    'apikey': 'query-string token for URLs opened by a player (verified)',
  },
  // /universal copies its whole query into the HLS variant URL it answers
  // with (verified on 12.2: a PlaySessionId sent here comes back in
  // main.m3u8?…&PlaySessionId=…), and that route reads both.
  'GET /Audio/{itemId}/universal': {
    'playsessionid': 'forwarded to main.m3u8, which reads it (verified)',
    'breakonnonkeyframes': 'forwarded to main.m3u8 (verified)',
  },
};

/// Methods not called, with why.
const _skipped = <String, String>{
  // Opens a WebSocket, not an HTTP request.
  'JellyfinNotificationsApi.connect': 'WebSocket',
  'JellyfinNotificationsApi.disconnect': 'WebSocket',
  'JellyfinNotificationsApi.send': 'WebSocket',
  'JellyfinNotificationsApi.startSessionsFeed': 'WebSocket',
  'JellyfinNotificationsApi.stopSessionsFeed': 'WebSocket',
  'JellyfinNotificationsApi.startScheduledTasksFeed': 'WebSocket',
  'JellyfinNotificationsApi.stopScheduledTasksFeed': 'WebSocket',
  'JellyfinNotificationsApi.startActivityLogFeed': 'WebSocket',
  'JellyfinNotificationsApi.stopActivityLogFeed': 'WebSocket',
  'JellyfinNotificationsApi.startSessions': 'WebSocket',
  'JellyfinNotificationsApi.stopSessions': 'WebSocket',
  'JellyfinNotificationsApi.startScheduledTasks': 'WebSocket',
  'JellyfinNotificationsApi.stopScheduledTasks': 'WebSocket',
  'JellyfinNotificationsApi.close': 'WebSocket',
};

final class _Route {
  final String path;
  final RegExp pattern;
  final int literals;
  final Map<String, Set<String>> paramsByMethod;

  _Route(this.path, this.pattern, this.literals, this.paramsByMethod);
}

/// The pinned 12.x document plus the routes it hides but servers still
/// serve (HLS playlists and segments, a few obsolete endpoints): those come
/// from the 10.11.6 document, kept in
/// `test/fixtures/spec/jellyfin-hidden-routes.json`. It keeps only the
/// routes a 12.2 server still has — probed with a GET, which an unknown
/// route answers with an empty 404 and a POST- or DELETE-only route with
/// 405 — so it cannot hide a call to a route 12.x removed.
List<_Route> _loadSpec() {
  final spec = jsonDecode(
    File('docs/jellyfin-openapi-stable.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final routes = <_Route>[];
  (spec['paths']! as Map<String, Object?>).forEach((path, ops) {
    final byMethod = <String, Set<String>>{};
    (ops! as Map<String, Object?>).forEach((method, op) {
      if (op is! Map<String, Object?>) return;
      byMethod[method.toUpperCase()] = {
        for (final p in (op['parameters'] as List<Object?>?) ?? const [])
          if (p is Map<String, Object?> && p['in'] == 'query')
            (p['name']! as String).toLowerCase(),
      };
    });
    routes.add(_route(path, byMethod));
  });
  final hidden = jsonDecode(
    File('test/fixtures/spec/jellyfin-hidden-routes.json').readAsStringSync(),
  ) as Map<String, Object?>;
  (hidden['routes']! as Map<String, Object?>).forEach((path, ops) {
    routes.add(
      _route(path, {
        for (final e in (ops! as Map<String, Object?>).entries)
          e.key: {
            for (final p in e.value! as List<Object?>)
              (p! as String).toLowerCase(),
          },
      }),
    );
  });
  return routes;
}

_Route _route(String path, Map<String, Set<String>> byMethod) {
  // A placeholder can be a whole segment ({itemId}) or part of one
  // ({segmentId}.{container}).
  final regex = path
      .split('/')
      .map(
        (s) => s
            .split(RegExp(r'(\{[^}]+\})'))
            .map(RegExp.escape)
            .join()
            .toLowerCase(),
      )
      .join('/');
  final pattern = RegExp(
    '^${path.toLowerCase().split('/').map((s) => s.replaceAllMapped(RegExp(r'\{[^}]+\}'), (_) => '\u0000')).map((s) => s.split('\u0000').map(RegExp.escape).join('[^/]+')).join('/')}\$',
  );
  assert(regex.isNotEmpty);
  return _Route(
    path,
    pattern,
    path.split('/').where((s) => !s.contains('{')).length,
    byMethod,
  );
}

/// The most specific route matching [path], preferring one that documents
/// [method] (`/Items/{id}/RemoteSearch/Subtitles/{language}` and
/// `…/{subtitleId}` share a shape and differ by method).
_Route? _match(List<_Route> routes, String path, String method) {
  final lower = path.toLowerCase();
  _Route? best;
  int score(_Route r) =>
      r.literals * 2 + (r.paramsByMethod.containsKey(method) ? 1 : 0);
  for (final r in routes) {
    if (!r.pattern.hasMatch(lower)) continue;
    if (best == null || score(r) > score(best)) best = r;
  }
  return best;
}

/// A stand-in value for a parameter of [type], or `#skip` when there is
/// none (the parameter is then left out if it may be).
Object? _value(TypeMirror type, String name) {
  // A verbatim pass-through for parameters the wrapper does not type.
  if (name == 'params' || name == 'extraHeaders') return #skip;
  if (type is! ClassMirror) return #skip;
  final t = type.reflectedType;
  if (t == String) {
    // images.url validates its colour.
    if (name == 'backgroundColor') return '000000';
    return name.toLowerCase().contains('date') ? '2026-01-01' : 'x';
  }
  if (t == int) return 1;
  if (t == double || t == num) return 1.5;
  if (t == bool) return true;
  if (t == Duration) return const Duration(seconds: 1);
  if (t == DateTime) return DateTime.utc(2026);
  if (t == Uint8List) return Uint8List.fromList([1]);
  if (type.isEnum) {
    return (type.getField(#values).reflectee as List<Object?>).first;
  }
  if (type.simpleName == #List) {
    final arg = type.typeArguments.single;
    final inner = _value(arg, name);
    return inner == #skip ? #skip : _list(arg, inner);
  }
  if (type.simpleName == #Map) {
    final v = (type.typeArguments.last as ClassMirror).reflectedType;
    return v == String
        ? <String, String>{'k': 'v'}
        : <String, Object?>{'k': 'v'};
  }
  if (t == JellyfinDeviceProfile) {
    return const JellyfinDeviceProfile(name: 'x');
  }
  if (t == JellyfinDisplayPreferences) {
    return JellyfinDisplayPreferences.fromJson(const {'Id': 'x'});
  }
  if (t == JellyfinCredentials) {
    return const JellyfinCredentials(
      client: 'x',
      device: 'x',
      deviceId: 'x',
      version: '1',
    );
  }
  return #skip;
}

/// A typed one-element list, so `List<String>` parameters accept it.
Object _list(TypeMirror arg, Object? element) {
  final t = (arg as ClassMirror).reflectedType;
  if (t == String) return <String>[element! as String];
  if (t == int) return <int>[element! as int];
  if (t == double) return <double>[element! as double];
  if (element is Map<String, Object?>) return <Map<String, Object?>>[element];
  return [element];
}

bool _deprecated(DeclarationMirror d) =>
    d.metadata.any((m) => m.reflectee is Deprecated);

void main() {
  final routes = _loadSpec();

  test('every request a sub-API sends is in the pinned spec', () async {
    final adapter = CapturingAdapter();
    final client = capturingClient(adapter, jsonIsolateThreshold: 1 << 30);
    final clientMirror = reflect(client);
    final violations = <String>[];
    final uncalled = <String>[];
    var calls = 0;

    final apis = clientMirror.type.declarations.values
        .whereType<VariableMirror>()
        .where((v) => !v.isPrivate && !v.isStatic)
        .map((v) => clientMirror.getField(v.simpleName))
        .where((m) => MirrorSystem.getName(m.type.simpleName).endsWith('Api'));

    for (final api in apis) {
      final apiName = MirrorSystem.getName(api.type.simpleName);
      final methods =
          api.type.declarations.values.whereType<MethodMirror>().where(
                (m) =>
                    m.isRegularMethod &&
                    !m.isPrivate &&
                    !m.isStatic &&
                    !m.isOperator &&
                    !_deprecated(m),
              );
      for (final m in methods) {
        final name = '$apiName.${MirrorSystem.getName(m.simpleName)}';
        if (_skipped.containsKey(name)) continue;
        final positional = <Object?>[];
        final named = <Symbol, Object?>{};
        var callable = true;
        for (final p in m.parameters) {
          if (_deprecated(p)) continue;
          final v = _value(p.type, MirrorSystem.getName(p.simpleName));
          if (v == #skip) {
            if (!p.isOptional && !p.isNamed) callable = false;
            if (p.isNamed && !p.isOptional) callable = false;
            continue;
          }
          if (p.isNamed) {
            named[p.simpleName] = v;
          } else {
            positional.add(v);
          }
        }
        if (!callable) {
          uncalled.add(name);
          continue;
        }
        final before = adapter.requests.length;
        Object? result;
        try {
          result = api.invoke(m.simpleName, positional, named).reflectee;
          if (result is Future) await result;
          if (result is Stream) await result.first;
        } catch (_) {
          // The canned answer fits few endpoints; only the request matters.
        }
        final sent = [
          ...adapter.requests.skip(before).map((r) => (r.method, r.uri)),
          if (result is String && result.startsWith('https://'))
            ('GET', Uri.parse(result)),
          if (result is (String, String) && result.$1.startsWith('https://'))
            ('GET', Uri.parse(result.$1)),
        ];
        if (sent.isEmpty) {
          uncalled.add('$name (sent nothing)');
          continue;
        }
        for (final (method, uri) in sent) {
          calls++;
          final route = _match(routes, uri.path, method);
          if (route == null) {
            violations.add('$name: ${uri.path} is not a route in the spec');
            continue;
          }
          final declared = route.paramsByMethod[method];
          if (declared == null) {
            violations.add(
              '$name: $method ${route.path} — the spec has '
              '${route.paramsByMethod.keys.join('/')}',
            );
            continue;
          }
          final allowed = {
            ...?_allowedExtras['*']?.keys,
            ...?_allowedExtras['$method ${route.path}']?.keys,
          };
          for (final q in uri.queryParametersAll.keys) {
            final k = q.toLowerCase();
            if (!declared.contains(k) && !allowed.contains(k)) {
              violations.add(
                '$name: $method ${route.path} sends "$q", '
                'which the route does not declare',
              );
            }
          }
        }
      }
    }

    // ignore: avoid_print
    print('spec contract: $calls requests checked; not called: '
        '${uncalled.length}\n  ${uncalled.join('\n  ')}');
    expect(violations, isEmpty, reason: violations.join('\n'));
    expect(uncalled, isEmpty, reason: 'every method must be exercised');
    expect(calls, greaterThan(250));
  });
}
