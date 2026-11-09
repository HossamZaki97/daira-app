import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/config.dart';
import '../core/models.dart';

final configProvider = Provider<AppConfig>((_) => AppConfig.environment());
final apiProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(configProvider);
  final api = ApiClient(config, SecureSessionVault(config.scope));
  ref.onDispose(api.dispose);
  return api;
});
final localeProvider = StateProvider<Locale>((_) => const Locale('ar'));
final themeProvider = StateProvider<ThemeMode>((_) => ThemeMode.light);
final pendingInviteProvider = StateProvider<String?>((_) => null);
final invitationSecretsProvider = StateProvider<Map<String, String>>((ref) {
  ref.watch(authProvider.select((state) => state.profile?['id']));
  return {};
});
final pendingCommandsProvider = StateProvider<Map<String, CommandRequest>>((
  ref,
) {
  ref.watch(authProvider.select((state) => state.profile?['id']));
  return {};
});

class AuthState {
  const AuthState({this.profile, this.loading = false, this.error});
  final Json? profile;
  final bool loading;
  final String? error;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.api) : super(const AuthState(loading: true)) {
    _expiry = api.expired.stream.listen((_) => state = const AuthState());
    restore();
  }
  final ApiClient api;
  late final StreamSubscription<void> _expiry;
  Future<void> restore() async {
    state = const AuthState(loading: true);
    try {
      await api.restore();
      final profile = api.hasSession ? await api.post('me', {}) : null;
      if (mounted) state = AuthState(profile: profile);
    } on ApiFailure catch (error) {
      if (mounted) state = AuthState(error: error.code);
    } catch (_) {
      if (mounted) state = const AuthState(error: 'unavailable');
    }
  }

  Future<void> login(String email, String password) async {
    await api.login(email, password);
    if (mounted) state = AuthState(profile: api.storedProfile);
  }

  Future<void> logout() => api.logout();
  @override
  void dispose() {
    _expiry.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(apiProvider)),
);

class CirclesController extends StateNotifier<AsyncValue<List<Circle>>> {
  CirclesController(this.api, {this.onSync}) : super(const AsyncLoading()) {
    Future<void>.microtask(refresh);
  }
  final ApiClient api;
  final void Function(SyncStatus status)? onSync;
  int _revision = 0;
  DateTime? _updated;
  Future<void> refresh() async {
    if (!mounted) return;
    final revision = ++_revision;
    onSync?.call(SyncStatus(updated: _updated, refreshing: true));
    try {
      final response = await api.post('snapshot', {});
      if (mounted && revision == _revision) {
        state = AsyncData(rows(response['circles']).map(Circle.new).toList());
        _updated = DateTime.now();
        onSync?.call(SyncStatus(updated: _updated));
      }
    } catch (error, stack) {
      if (mounted && revision == _revision) {
        // Keep useful data visible, but explicitly mark it as stale.
        if (!state.hasValue) state = AsyncError(error, stack);
        onSync?.call(SyncStatus(updated: _updated, error: error));
      }
    }
  }

  Future<void> command(String action, Json body) async {
    ++_revision;
    try {
      final response = await api.post(action, body);
      if (!mounted) return;
      ++_revision;
      final circle = Circle(response);
      final existing = state.asData?.value ?? <Circle>[];
      final previous = existing.where((c) => c.id == circle.id).firstOrNull;
      state = AsyncData([
        for (final item in existing)
          if (item.id != circle.id) item,
        if (previous == null || circle.version >= previous.version)
          circle
        else
          previous,
      ]);
      // An acknowledged mutation succeeds independently of the next snapshot.
      unawaited(refresh());
    } catch (_) {
      if (mounted) unawaited(refresh());
      rethrow;
    }
  }
}

class SyncStatus {
  const SyncStatus({this.updated, this.refreshing = false, this.error});
  final DateTime? updated;
  final bool refreshing;
  final Object? error;
}

final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  ref.watch(authProvider.select((s) => s.profile?['id']));
  return const SyncStatus();
});

final circlesProvider =
    StateNotifierProvider.autoDispose<
      CirclesController,
      AsyncValue<List<Circle>>
    >((ref) {
      ref.watch(authProvider.select((s) => s.profile?['id']));
      final sync = ref.watch(syncStatusProvider.notifier);
      return CirclesController(
        ref.watch(apiProvider),
        onSync: (status) {
          if (sync.mounted) sync.state = status;
        },
      );
    });
final metadataProvider = FutureProvider<Json>(
  (ref) => ref.watch(apiProvider).post('meta', {}, authenticated: false),
);

Future<void> savePreference(String key, Object value) async {
  final preferences = await SharedPreferences.getInstance();
  if (value is bool) await preferences.setBool(key, value);
  if (value is String) await preferences.setString(key, value);
}
