import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Set in main when Firebase started (google-services.json present). Without
/// it the app works the same, with in-app notifications only.
final firebaseReadyProvider = Provider<bool>((_) => false);

Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (error) {
    debugPrint('[push] Firebase not started: $error');
    return false;
  }
}

/// Last push step, shown in debug builds on the account screen.
final pushStatus = ValueNotifier<String>('not started');

void _status(String value) {
  pushStatus.value = value;
  debugPrint('[push] $value');
}

/// Registers this phone for push while someone is signed in, and reports
/// taps on notifications. The server removes the registration on sign-out.
class PushController {
  PushController(this._ref, {required this.onOpenCircle, required this.onForeground});

  final WidgetRef _ref;

  /// A notification was tapped (app opened from it).
  final void Function(String circleId) onOpenCircle;

  /// A notification arrived while the app is open (the system shows nothing then).
  final void Function(String? title) onForeground;

  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _token;

  Future<void> start() async {
    if (!_ref.read(firebaseReadyProvider)) return _status('Firebase not available');
    final platform = _ref.read(clientInfoProvider).platform;
    if (platform != 'android' && platform != 'ios') return _status('unsupported platform');
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      _status('permission: ${permission.authorizationStatus.name}');
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      // The server sends with the FCM HTTP v1 `token` field, so the app reports
      // registration tokens. firebase_messaging 17 deprecates them in favour of
      // installation IDs (register/onRegistered); switch both sides together.
      _subscriptions
        // ignore: deprecated_member_use
        ..add(messaging.onTokenRefresh.listen(_register))
        ..add(FirebaseMessaging.onMessage.listen((m) => onForeground(m.notification?.title)))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_opened));
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token == null) _status('no FCM token');
      if (token != null) await _register(token);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _opened(initial);
    } catch (error) {
      // Push is a convenience; in-app notifications still work.
      _status('failed: $error');
    }
  }

  /// Sends the language again so pushes are written in the app language.
  Future<void> languageChanged() async {
    final token = _token;
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    _token = token;
    try {
      await _ref.read(accountRepositoryProvider).registerDevice(
        token: token,
        platform: _ref.read(clientInfoProvider).platform,
        lang: _ref.read(localeProvider).languageCode,
      );
      _status('registered with the server');
    } catch (error) {
      // Retried on the next start or token refresh.
      _status('server registration failed: $error');
    }
  }

  void _opened(RemoteMessage message) {
    final id = message.data['circle_id'];
    if (id is String && id.isNotEmpty) onOpenCircle(id);
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
}
