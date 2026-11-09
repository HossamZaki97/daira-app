import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

typedef Json = Map<String, dynamic>;

class ApiFailure implements Exception {
  const ApiFailure(this.code);
  final String code;
}

abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionVault implements SessionVault {
  SecureSessionVault(String scope) : key = 'daira.odoo.$scope';
  final String key;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  @override
  Future<String?> read() => _storage.read(key: key);
  @override
  Future<void> write(String value) => _storage.write(key: key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: key);
}

class ApiClient {
  ApiClient(this.config, this.vault, {HttpClient? http})
    : _http = http ?? HttpClient();
  final AppConfig config;
  final SessionVault vault;
  final HttpClient _http;
  final expired = StreamController<void>.broadcast();
  Json? _session;
  Future<void>? _refreshing;
  int _generation = 0;
  bool get hasSession => _session != null;
  Json? get storedProfile => _session?['profile'] as Json?;

  Future<void> restore() async {
    final raw = await vault.read();
    if (raw != null) {
      try {
        _session = Json.from(jsonDecode(raw) as Map);
      } catch (_) {
        await clear();
      }
    }
  }

  Future<void> clear() async {
    _generation++;
    _session = null;
    try {
      await vault.clear();
    } finally {
      if (!expired.isClosed) expired.add(null);
    }
  }

  Future<void> login(String email, String password) async {
    final generation = ++_generation;
    _session = null;
    await vault.clear();
    final result = await post('login', {
      'email': email,
      'password': password,
    }, authenticated: false);
    if (generation != _generation) throw const ApiFailure('session_expired');
    _session = result;
    await vault.write(jsonEncode(result));
  }

  Future<Json> post(
    String action,
    Json body, {
    bool authenticated = true,
    bool retry = true,
  }) async {
    final generation = _generation;
    final bearer = _session?['access_token'];
    if (authenticated && _session == null) {
      throw const ApiFailure('session_expired');
    }
    try {
      final request = await _http
          .postUrl(config.endpoint(action))
          .timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      if (authenticated) {
        request.headers.set('Authorization', 'Bearer $bearer');
      }
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final content = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 15));
      if (generation != _generation) throw const ApiFailure('session_expired');
      final envelope = Json.from(jsonDecode(content) as Map);
      if (response.statusCode == 401 && authenticated && retry) {
        if (_session?['access_token'] != bearer) {
          return post(action, body, retry: false);
        }
        await (_refreshing ??= _refresh().whenComplete(
          () => _refreshing = null,
        ));
        return post(action, body, retry: false);
      }
      if (envelope['ok'] != true) {
        throw ApiFailure(
          (envelope['error'] as Map?)?['code'] as String? ?? 'unavailable',
        );
      }
      return Json.from(envelope['data'] as Map);
    } on ApiFailure {
      rethrow;
    } on SocketException {
      throw const ApiFailure('offline');
    } on TimeoutException {
      throw const ApiFailure('offline');
    } on HandshakeException {
      throw const ApiFailure('offline');
    } on HttpException {
      throw const ApiFailure('offline');
    } catch (_) {
      throw const ApiFailure('unavailable');
    }
  }

  Future<void> _refresh() async {
    final generation = _generation;
    final refresh = _session?['refresh_token'];
    try {
      if (refresh == null) throw const ApiFailure('session_expired');
      final result = await post('refresh', {
        'refresh_token': refresh,
      }, authenticated: false);
      if (generation != _generation) throw const ApiFailure('session_expired');
      _session = result;
      await vault.write(jsonEncode(result));
    } on ApiFailure catch (error) {
      if (error.code != 'offline' && generation == _generation) await clear();
      rethrow;
    }
  }

  Future<void> logout() async {
    final remote = _session != null ? post('logout', {}, retry: false) : null;
    try {
      await clear();
    } finally {
      try {
        await remote;
      } catch (_) {
        /* Local logout is immediate, even offline. */
      }
    }
  }

  void dispose() {
    _http.close(force: true);
    expired.close();
  }
}
