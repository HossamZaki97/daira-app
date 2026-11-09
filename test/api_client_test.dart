import 'dart:convert';
import 'dart:io';

import 'package:daira/core/api/api_client.dart';
import 'package:daira/core/api/api_exception.dart';
import 'package:daira/core/api/client_info.dart';
import 'package:daira/core/config.dart';
import 'package:daira/core/data/repositories.dart';
import 'package:daira/core/models/json.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryVault implements SessionVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

/// A tiny fake of the Odoo API with the same envelope and error codes.
class FakeServer {
  late HttpServer _server;
  final requests = <HttpRequest>[];
  final bodies = <String, Json>{};
  String access = 'access-1';
  int refreshes = 0;
  bool refreshFails = false;
  bool maintenance = false;

  Future<AppConfig> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
    return AppConfig('http://127.0.0.1:${_server.port}', allowLocalHttp: true);
  }

  Future<void> close() => _server.close(force: true);

  Json _tokens() => {
    'access_token': access,
    'refresh_token': 'refresh-$refreshes',
    'profile': {'id': 'p1', 'name': 'Mona', 'email': 'mona@example.invalid', 'lang': 'ar'},
  };

  Future<void> _handle(HttpRequest request) async {
    requests.add(request);
    final text = await utf8.decoder.bind(request).join();
    final path = request.uri.path.replaceFirst(AppConfig.apiPrefix, '');
    if (text.isNotEmpty) bodies[path] = Json.from(jsonDecode(text) as Map);
    var status = 200;
    Object? data;
    Json? error;
    if (maintenance && path != '/app/config') {
      status = 503;
      error = {'code': 'maintenance'};
    } else if (path == '/auth/login') {
      data = _tokens();
    } else if (path == '/auth/refresh') {
      // Give the parallel callers time to queue behind one refresh.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      refreshes++;
      if (refreshFails) {
        status = 401;
        error = {'code': 'session_expired'};
      } else {
        access = 'access-${refreshes + 1}';
        data = _tokens();
      }
    } else if (request.headers.value('Authorization') != 'Bearer $access') {
      status = 401;
      error = {'code': 'session_expired'};
    } else if (path == '/me') {
      data = _tokens()['profile'];
    } else if (path.endsWith('/report')) {
      status = 409;
      error = {'code': 'conflict'};
    } else {
      data = {'path': path};
    }
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(error == null ? {'ok': true, 'data': data} : {'ok': false, 'error': error}));
    await request.response.close();
  }
}

void main() {
  late FakeServer server;
  late ApiClient api;
  late MemoryVault vault;
  const info = ClientInfo(platform: 'android', version: '2.0.0', build: 7, country: 'EG');

  setUp(() async {
    server = FakeServer();
    vault = MemoryVault();
    api = ApiClient(await server.start(), vault, info, timeout: const Duration(seconds: 5));
  });

  tearDown(() async {
    api.dispose();
    await server.close();
  });

  test('login stores the session and sends client headers', () async {
    api.language = 'en';
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    expect(api.session.value?.profile.name, 'Mona');
    expect(vault.value, contains('access-1'));
    final request = server.requests.single;
    expect(request.headers.value('X-Platform'), 'android');
    expect(request.headers.value('X-App-Version'), '2.0.0+7');
    expect(request.headers.value('X-Country'), 'EG');
    expect(request.headers.value('Accept-Language'), 'en');
    expect(request.headers.contentType?.mimeType, 'application/json');
  });

  test('restores a stored session', () async {
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    final again = ApiClient(api.config, vault, info);
    await again.restore();
    expect(again.session.value?.accessToken, 'access-1');
    again.dispose();
  });

  test('parallel calls share one refresh and then succeed', () async {
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    server.access = 'rotated-on-server'; // the stored token is now expired
    server.refreshes = 0;
    final results = await Future.wait([api.get('/home'), api.get('/circles'), api.get('/me')]);
    expect(results.map((r) => r['path'] ?? r['name']), ['/home', '/circles', 'Mona']);
    expect(server.refreshes, 1);
    expect(api.session.value?.accessToken, server.access);
  });

  test('a refused refresh signs out with a signal', () async {
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    server
      ..access = 'rotated'
      ..refreshFails = true;
    final signals = <ApiSignal>[];
    final sub = api.signals.listen(signals.add);
    await expectLater(api.get('/home'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'session_expired')));
    await Future<void>.delayed(Duration.zero);
    expect(api.session.value, isNull);
    expect(vault.value, isNull);
    expect(signals, [ApiSignal.signedOut]);
    await sub.cancel();
  });

  test('money commands carry the Idempotency-Key and version', () async {
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    final key = newCommandId();
    await expectLater(
      api.post('/circles/c1/obligations/o1/report', body: {'version': 3}, idempotencyKey: key),
      throwsA(isA<ApiException>().having((e) => e.isConflict, 'conflict', isTrue)),
    );
    final request = server.requests.last;
    expect(request.headers.value('Idempotency-Key'), key);
    expect(server.bodies['/circles/c1/obligations/o1/report'], {'version': 3});
  });

  test('maintenance raises a signal', () async {
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    server.maintenance = true;
    final signal = api.signals.first;
    await expectLater(api.get('/home'), throwsA(isA<ApiException>()));
    expect(await signal.timeout(const Duration(seconds: 1)), ApiSignal.maintenance);
    expect(api.session.value, isNotNull, reason: 'maintenance never signs out');
  });

  test('offline is reported as offline', () async {
    final dead = ApiClient(const AppConfig('http://127.0.0.1:9', allowLocalHttp: true), MemoryVault(), info,
        timeout: const Duration(seconds: 2));
    await expectLater(dead.get('/app/config', auth: false), throwsA(isA<ApiException>().having((e) => e.isOffline, 'offline', isTrue)));
    dead.dispose();
  });

  test('command ids are UUID v4', () {
    final id = newCommandId();
    expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(id), isTrue);
    expect(newCommandId(), isNot(id));
  });

  test('logout forgets the session even when the server is gone', () async {
    await AuthRepository(api).login('mona@example.invalid', 'secret');
    await server.close();
    await api.logout();
    expect(api.session.value, isNull);
    expect(vault.value, isNull);
  });
}
