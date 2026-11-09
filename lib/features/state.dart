import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/data/repositories.dart';
import '../core/models/activity.dart';
import '../core/models/circle.dart';
import '../core/providers.dart';

/// Screen data. Everything is scoped to the signed-in account: a new session
/// rebuilds these providers, so one account never sees another's data.
final homeProvider = FutureProvider.autoDispose<HomeData>((ref) {
  ref.watch(sessionProvider.select((s) => s?.profile.id));
  return ref.watch(accountRepositoryProvider).home();
});

final circlesProvider = FutureProvider.autoDispose.family<List<CircleSummary>, CircleFilter>((ref, filter) {
  ref.watch(sessionProvider.select((s) => s?.profile.id));
  return ref.watch(circlesRepositoryProvider).list(filter);
});

/// Unread notifications, for the badge. Refreshed with home and after reading.
final unreadProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(sessionProvider.select((s) => s?.profile.id));
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

/// Refresh the lists after anything changed on the server.
/// Pass `ref.invalidate` (works from widgets and providers).
void refreshLists(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(homeProvider);
  invalidate(circlesProvider);
  invalidate(unreadProvider);
}

/// One circle, with every command it supports. A command returns the fresh
/// circle, which replaces the state; lists are refreshed in the background.
class CircleController extends AutoDisposeFamilyAsyncNotifier<Circle, String> {
  /// One Idempotency-Key per pending action, reused when the person retries
  /// after a network failure so the server applies it only once.
  final _keys = <String, String>{};

  @override
  Future<Circle> build(String id) {
    ref.watch(sessionProvider.select((s) => s?.profile.id));
    return ref.watch(circlesRepositoryProvider).get(id);
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(circlesRepositoryProvider).get(arg));
  }

  /// Runs [action] for [actionId]. Throws [ApiException] for the screen to show.
  Future<void> perform(String actionId, Future<Circle> Function(CirclesRepository repo, String key) action) async {
    final key = _keys.putIfAbsent(actionId, newCommandId);
    try {
      final circle = await action(ref.read(circlesRepositoryProvider), key);
      _keys.remove(actionId);
      state = AsyncData(circle);
      refreshLists(ref.invalidate);
    } on ApiException catch (error) {
      // Keep the key only when the server may not have received the request.
      if (!(error.isOffline || error.code == 'unavailable')) _keys.remove(actionId);
      if (error.isConflict || error.code == 'not_found' || error.code == 'circle_suspended') {
        await reload();
        refreshLists(ref.invalidate);
      }
      rethrow;
    }
  }

  Future<void> report(Obligation o) =>
      perform('report:${o.id}', (repo, key) => repo.reportPayment(arg, o, key));

  Future<void> approve(Obligation o) =>
      perform('approve:${o.id}', (repo, key) => repo.approvePayment(arg, o, key));

  Future<void> reject(Obligation o, String reason) =>
      perform('reject:${o.id}', (repo, key) => repo.rejectPayment(arg, o, reason, key));

  Future<void> payout(int round) => perform('payout:$round', (repo, key) => repo.reportPayout(arg, round, key));

  Future<void> receipt(int round) => perform('receipt:$round', (repo, key) => repo.confirmReceipt(arg, round, key));

  Future<void> activate(int version) => perform('activate', (repo, key) => repo.activate(arg, version, key));
}

final circleProvider = AsyncNotifierProvider.autoDispose.family<CircleController, Circle, String>(CircleController.new);
