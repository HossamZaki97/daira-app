import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';
import '../models/account.dart';
import '../models/json.dart';
import 'api_exception.dart';
import 'client_info.dart';

/// Signed-in credentials. Stored only in the platform keystore.
class Session {
  const Session({required this.accessToken, required this.refreshToken, required this.profile});

  factory Session.fromJson(Json json) {
    final access = json.str('access_token');
    final refresh = json.str('refresh_token');
    if (access.isEmpty || refresh.isEmpty) throw const FormatException('Incomplete session');
    return Session(accessToken: access, refreshToken: refresh, profile: Profile.fromJson(json.obj('profile')));
  }

  final String accessToken;
  final String refreshToken;
  final Profile profile;

  Session withProfile(Profile value) => Session(accessToken: accessToken, refreshToken: refreshToken, profile: value);

  Json toJson() => {'access_token': accessToken, 'refresh_token': refreshToken, 'profile': profile.toJson()};
}

abstract interface class SessionVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionVault implements SessionVault {
  SecureSessionVault(String scope) : key = 'daira.session.$scope';
  final String key;
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  @override
  Future<String?> read() => _storage.read(key: key);
  @override
  Future<void> write(String value) => _storage.write(key: key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: key);
}

/// Random UUID v4 for Idempotency-Key. Keep one key per user action and reuse
/// it when retrying that action, so the server applies it only once.
String newCommandId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// HTTP client for /daira/api/v1.
///
/// * reads the `{ok, data}` / `{ok:false, error}` envelope into data or [ApiException];
/// * sends the client headers, language, bearer token and Idempotency-Key;
/// * refreshes an expired access token once (shared by parallel calls) and retries;
/// * raises [signals] for session end, suspension, maintenance and forced update.
class ApiClient {
  ApiClient(this.config, this.vault, this.info, {HttpClient? http, this.timeout = const Duration(seconds: 20)})
    : _http = http ?? HttpClient();

  final AppConfig config;
  final SessionVault vault;
  final ClientInfo info;
  final Duration timeout;
  final HttpClient _http;

  /// Accept-Language sent to the server (ar | en). Kept in sync with the app language.
  String language = 'ar';

  /// Current session; null when signed out. The router listens to it.
  final ValueNotifier<Session?> session = ValueNotifier(null);

  final _signals = StreamController<ApiSignal>.broadcast();
  Stream<ApiSignal> get signals => _signals.stream;

  Future<void>? _refreshing;
  int _generation = 0;

  // ------------------------------------------------------------ session
  Future<void> restore() async {
    try {
      final raw = await vault.read();
      if (raw != null) session.value = Session.fromJson(Json.from(jsonDecode(raw) as Map));
    } catch (_) {
      await _clearVault();
    }
  }

  /// Stores the result of /auth/login.
  Future<Session> startSession(Json data) async {
    final value = Session.fromJson(data);
    _generation++;
    await vault.write(jsonEncode(value.toJson()));
    session.value = value;
    return value;
  }

  Future<void> updateProfile(Profile profile) async {
    final current = session.value;
    if (current == null) return;
    final value = current.withProfile(profile);
    session.value = value;
    try {
      await vault.write(jsonEncode(value.toJson()));
    } catch (_) {
      // The profile is refreshed again on next start.
    }
  }

  /// Forgets the session on this phone. [signal] tells the app why.
  Future<void> endSession([ApiSignal? signal]) async {
    _generation++;
    session.value = null;
    await _clearVault();
    if (signal != null && !_signals.isClosed) _signals.add(signal);
  }

  /// Signs out here immediately, then tells the server (best effort, also offline).
  Future<void> logout() async {
    final token = session.value?.accessToken;
    await endSession();
    if (token == null) return;
    try {
      await _send('POST', '/auth/logout', token: token, auth: true, retried: true);
    } catch (_) {
      // Already signed out locally.
    }
  }

  Future<void> _clearVault() async {
    try {
      await vault.clear();
    } catch (_) {
      // Nothing else to do; the in-memory session is already gone.
    }
  }

  // ------------------------------------------------------------ requests
  Future<Json> get(String path, {Map<String, String>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<Json> post(String path, {Json? body, bool auth = true, String? idempotencyKey}) =>
      _send('POST', path, body: body ?? const {}, auth: auth, idempotencyKey: idempotencyKey);

  Future<Json> patch(String path, {required Json body, String? idempotencyKey}) =>
      _send('PATCH', path, body: body, auth: true, idempotencyKey: idempotencyKey);

  Future<Json> delete(String path, {Json? body}) => _send('DELETE', path, body: body, auth: true);

  Future<Json> _send(
    String method,
    String path, {
    Json? body,
    Map<String, String>? query,
    required bool auth,
    String? idempotencyKey,
    String? token,
    bool retried = false,
  }) async {
    final generation = _generation;
    final bearer = token ?? session.value?.accessToken;
    if (auth && bearer == null) throw const ApiException('session_expired', status: 401);

    late final int status;
    late final String text;
    try {
      final request = await _http.openUrl(method, config.endpoint(path, query)).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptLanguageHeader, language);
      info.headers.forEach((name, value) => request.headers.set(name, value));
      if (auth) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      if (idempotencyKey != null) request.headers.set('Idempotency-Key', idempotencyKey);
      if (body != null) {
        final bytes = utf8.encode(jsonEncode(body));
        request.headers.contentType = ContentType.json;
        request.contentLength = bytes.length;
        request.add(bytes);
      }
      final response = await request.close().timeout(timeout);
      status = response.statusCode;
      text = await utf8.decoder.bind(response).join().timeout(timeout);
    } on SocketException {
      throw const ApiException('offline');
    } on TimeoutException {
      throw const ApiException('offline');
    } on TlsException {
      throw const ApiException('offline');
    } on HttpException {
      throw const ApiException('offline');
    } on ArgumentError {
      rethrow;
    } catch (_) {
      throw const ApiException('unavailable');
    }

    // A sign-out or a new sign-in happened while this call was running.
    if (auth && generation != _generation && token == null) {
      throw const ApiException('session_expired', status: 401);
    }

    Json envelope;
    try {
      envelope = Json.from(jsonDecode(text) as Map);
    } catch (_) {
      throw ApiException('unavailable', status: status);
    }
    if (envelope['ok'] == true) {
      final data = envelope['data'];
      return data is Map ? Json.from(data) : <String, dynamic>{};
    }

    final error = envelope.obj('error');
    final failure = ApiException(error.str('code', 'unavailable'), status: status, field: error.strOrNull('field'));

    if (auth && failure.code == 'session_expired' && !retried) {
      if (session.value != null && session.value!.accessToken != bearer) {
        // Another call already refreshed the token.
        return _send(method, path, body: body, query: query, auth: auth, idempotencyKey: idempotencyKey, retried: true);
      }
      await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
      return _send(method, path, body: body, query: query, auth: auth, idempotencyKey: idempotencyKey, retried: true);
    }
    await _raise(failure, auth && token == null);
    throw failure;
  }

  Future<void> _refresh() async {
    final generation = _generation;
    final current = session.value;
    if (current == null) throw const ApiException('session_expired', status: 401);
    try {
      final data = await _send('POST', '/auth/refresh', body: {'refresh_token': current.refreshToken}, auth: false);
      if (generation != _generation) throw const ApiException('session_expired', status: 401);
      final value = Session.fromJson(data);
      await vault.write(jsonEncode(value.toJson()));
      session.value = value;
    } on ApiException catch (error) {
      if (generation == _generation && (error.code == 'session_expired' || error.code == 'account_suspended')) {
        await endSession(error.code == 'account_suspended' ? ApiSignal.suspended : ApiSignal.signedOut);
      }
      rethrow;
    } on FormatException {
      await endSession(ApiSignal.signedOut);
      throw const ApiException('session_expired', status: 401);
    }
  }

  Future<void> _raise(ApiException failure, bool auth) async {
    switch (failure.code) {
      case 'maintenance':
        _signals.add(ApiSignal.maintenance);
      case 'update_required':
        _signals.add(ApiSignal.updateRequired);
      case 'account_suspended' when auth:
        await endSession(ApiSignal.suspended);
      case 'session_expired' when auth:
        await endSession(ApiSignal.signedOut);
    }
  }

  void dispose() {
    _http.close(force: true);
    _signals.close();
    session.dispose();
  }
}
