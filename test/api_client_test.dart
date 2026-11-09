import 'dart:convert';
import 'dart:io';
import 'package:daira/core/api_client.dart';
import 'package:daira/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryVault implements SessionVault {
  String? value;
  bool failClear = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Storage unavailable');
    value = null;
  }
}

void main() {
  late HttpServer server;
  late ApiClient api;
  late MemoryVault vault;
  var access = 'first', refreshed = 0, forceExpired = false;
  Map<String, dynamic> tokens() => {
    'access_token': access,
    'refresh_token': 'refresh-fixture',
    'profile': {'id': 'user', 'name': 'Name', 'email': 'user@example.invalid'},
  };
  setUp(() async {
    access = 'first';
    refreshed = 0;
    forceExpired = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      final action = request.uri.path.split('/').last;
      var status = 200;
      Json data = {};
      if (action == 'login') {
        data = tokens();
      } else if (action == 'refresh') {
        refreshed++;
        access = 'second';
        data = tokens();
      } else if (request.headers.value('Authorization') != 'Bearer $access' ||
          forceExpired && access == 'first') {
        status = 401;
      } else if (action == 'me') {
        data = Json.from(tokens()['profile'] as Map);
      }
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(
          status == 200
              ? {'ok': true, 'data': data}
              : {
                  'ok': false,
                  'error': {'code': 'session_expired'},
                },
        ),
      );
      await request.response.close();
    });
    vault = MemoryVault();
    api = ApiClient(
      AppConfig('http://127.0.0.1:${server.port}', allowLocalHttp: true),
      vault,
    );
  });
  tearDown(() async {
    api.dispose();
    await server.close(force: true);
  });
  test(
    'login, secure-vault restoration, expiry refresh and logout use Odoo contract',
    () async {
      await api.login('user@example.invalid', 'fixture-password');
      expect(vault.value, isNotNull);
      forceExpired = true;
      expect((await api.post('me', {}))['id'], 'user');
      expect(refreshed, 1);
      final reopened = ApiClient(api.config, vault);
      await reopened.restore();
      expect((await reopened.post('me', {}))['id'], 'user');
      await reopened.logout();
      expect(vault.value, isNull);
      reopened.dispose();
    },
  );
  test(
    'protected calls without a session never send anonymous financial requests',
    () async {
      await expectLater(
        api.post('snapshot', {}),
        throwsA(
          isA<ApiFailure>().having((e) => e.code, 'code', 'session_expired'),
        ),
      );
      expect(refreshed, 0);
    },
  );
  test('concurrent expired requests share one token rotation', () async {
    await api.login('user@example.invalid', 'fixture-password');
    forceExpired = true;
    final results = await Future.wait(
      List.generate(4, (_) => api.post('me', {})),
    );
    expect(results.every((profile) => profile['id'] == 'user'), isTrue);
    expect(refreshed, 1);
  });
  test(
    'logout clears the in-memory session even when secure storage fails',
    () async {
      await api.login('user@example.invalid', 'fixture-password');
      vault.failClear = true;
      final signedOut = api.expired.stream.first;
      await expectLater(api.logout(), throwsStateError);
      await signedOut;
      expect(api.hasSession, isFalse);
      await expectLater(api.post('snapshot', {}), throwsA(isA<ApiFailure>()));
    },
  );
}
