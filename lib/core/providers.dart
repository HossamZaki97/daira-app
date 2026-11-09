import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/api_exception.dart';
import 'api/client_info.dart';
import 'config.dart';
import 'data/repositories.dart';
import 'models/app_settings.dart';

// ------------------------------------------------------------ wiring (overridden in main)
final preferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('override in main'));
final clientInfoProvider = Provider<ClientInfo>((_) => throw UnimplementedError('override in main'));
final apiProvider = Provider<ApiClient>((_) => throw UnimplementedError('override in main'));

final appRepositoryProvider = Provider((ref) => AppRepository(ref.watch(apiProvider)));
final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiProvider)));
final accountRepositoryProvider = Provider((ref) => AccountRepository(ref.watch(apiProvider)));
final circlesRepositoryProvider = Provider((ref) => CirclesRepository(ref.watch(apiProvider)));
final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiProvider)));

// ------------------------------------------------------------ session
/// The signed-in session, or null. Rebuilds whenever the API client signs in or out.
final sessionProvider = Provider<Session?>((ref) {
  final api = ref.watch(apiProvider);
  void changed() => ref.invalidateSelf();
  api.session.addListener(changed);
  ref.onDispose(() => api.session.removeListener(changed));
  return api.session.value;
});

/// Why the person was signed out, shown once on the sign-in screen.
final sessionNoticeProvider = StateProvider<ApiSignal?>((_) => null);

/// A link that opened the app and waits until the person can act on it.
final pendingLinkProvider = StateProvider<DeepLink?>((_) => null);

// ------------------------------------------------------------ preferences
const _languageKey = 'language';
const _themeKey = 'theme';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.watch(preferencesProvider).getString(_languageKey);
    final code = saved == 'en' ? 'en' : 'ar';
    ref.read(apiProvider).language = code;
    return Locale(code);
  }

  Future<void> set(String code) async {
    final value = code == 'en' ? 'en' : 'ar';
    ref.read(apiProvider).language = value;
    state = Locale(value);
    await ref.read(preferencesProvider).setString(_languageKey, value);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.watch(preferencesProvider).getString(_themeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(preferencesProvider).setString(_themeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

// ------------------------------------------------------------ start-up gates
enum StartupStatus { loading, ready, offline, unavailable, maintenance, updateRequired }

class StartupState {
  const StartupState(this.status, {this.settings, this.skippedBuild});

  final StartupStatus status;

  /// Last configuration received from the backend.
  final AppSettings? settings;

  /// The optional update the person chose to skip ("later").
  final int? skippedBuild;

  /// A newer optional build exists and was not skipped.
  bool get offerUpdate {
    final update = settings?.update;
    return update != null && update.available && !update.required && update.latestBuild != skippedBuild;
  }

  StartupState copyWith({StartupStatus? status, AppSettings? settings, int? skippedBuild}) => StartupState(
    status ?? this.status,
    settings: settings ?? this.settings,
    skippedBuild: skippedBuild ?? this.skippedBuild,
  );
}

const _skippedBuildKey = 'skipped_update_build';

/// Loads /app/config and decides which gate the app shows: maintenance,
/// forced update, offline, or the app itself. Any API call that hits
/// maintenance or a forced update reloads it.
class StartupController extends Notifier<StartupState> {
  StreamSubscription<ApiSignal>? _signals;

  @override
  StartupState build() {
    final api = ref.watch(apiProvider);
    _signals?.cancel();
    _signals = api.signals.listen(_onSignal);
    ref.onDispose(() => _signals?.cancel());
    Future.microtask(load);
    return StartupState(StartupStatus.loading, skippedBuild: ref.read(preferencesProvider).getInt(_skippedBuildKey));
  }

  /// [quiet]: re-check in the background without leaving the current screen
  /// unless the backend now blocks the app.
  Future<void> load({bool quiet = false}) async {
    if (!quiet && state.status != StartupStatus.loading) state = state.copyWith(status: StartupStatus.loading);
    try {
      final settings = await ref.read(appRepositoryProvider).config();
      state = state.copyWith(
        settings: settings,
        status: settings.update.required
            ? StartupStatus.updateRequired
            : settings.maintenance.active
            ? StartupStatus.maintenance
            : StartupStatus.ready,
      );
      final session = ref.read(sessionProvider);
      if (state.status == StartupStatus.ready && session != null) {
        // Keep the stored name/language current; a dead session signs out here.
        unawaited(ref.read(accountRepositoryProvider).me().then((_) {}, onError: (_) {}));
      }
    } on ApiException catch (error) {
      if (!quiet) state = state.copyWith(status: error.isOffline ? StartupStatus.offline : StartupStatus.unavailable);
    } catch (_) {
      if (!quiet) state = state.copyWith(status: StartupStatus.unavailable);
    }
  }

  Future<void> skipUpdate() async {
    final build = state.settings?.update.latestBuild;
    if (build == null) return;
    state = state.copyWith(skippedBuild: build);
    await ref.read(preferencesProvider).setInt(_skippedBuildKey, build);
  }

  void _onSignal(ApiSignal signal) {
    switch (signal) {
      case ApiSignal.maintenance:
      case ApiSignal.updateRequired:
        if (state.status != StartupStatus.loading) load(quiet: true);
      case ApiSignal.signedOut:
      case ApiSignal.suspended:
        ref.read(sessionNoticeProvider.notifier).state = signal;
    }
  }
}

final startupProvider = NotifierProvider<StartupController, StartupState>(StartupController.new);

/// Shortcut for screens that need the backend settings (always loaded once the app is past the gates).
final settingsProvider = Provider<AppSettings?>((ref) => ref.watch(startupProvider.select((s) => s.settings)));
