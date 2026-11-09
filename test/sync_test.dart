import 'dart:async';
import 'package:daira/app/providers.dart';
import 'package:daira/core/api_client.dart';
import 'package:daira/core/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_test.dart' show MemoryVault;
import 'models_test.dart' show fixture;

class QueuedApi extends ApiClient {
  QueuedApi()
    : super(const AppConfig('https://example.invalid'), MemoryVault());
  final snapshots = <Completer<Json>>[];
  final commands = <Completer<Json>>[];
  @override
  Future<Json> post(
    String action,
    Json body, {
    bool authenticated = true,
    bool retry = true,
  }) {
    final result = Completer<Json>();
    (action == 'snapshot' ? snapshots : commands).add(result);
    return result.future;
  }
}

Future<void> tick() => Future<void>.delayed(Duration.zero);
Json snapshot(Json circle) => {
  'circles': [circle],
};

void main() {
  late QueuedApi api;
  late CirclesController controller;
  late List<SyncStatus> statuses;
  setUp(() async {
    api = QueuedApi();
    statuses = [];
    controller = CirclesController(api, onSync: statuses.add);
    await tick();
    api.snapshots.single.complete(snapshot(fixture()));
    await tick();
  });
  tearDown(() {
    if (controller.mounted) controller.dispose();
    api.dispose();
  });

  test(
    'acknowledged command updates immediately even if snapshot fails',
    () async {
      final command = controller.command('approve', {});
      final updated = fixture()..['version'] = 2;
      api.commands.single.complete(updated);
      await command;
      expect(controller.state.asData!.value.single.version, 2);
      api.snapshots.last.completeError(const ApiFailure('offline'));
      await tick();
      expect(controller.state.hasError, isFalse);
      expect(controller.state.asData!.value.single.version, 2);
      expect(statuses.last.error, isA<ApiFailure>());
    },
  );
  test('older overlapping snapshot cannot replace newer response', () async {
    final older = controller.refresh(), newer = controller.refresh();
    api.snapshots.last.complete(snapshot(fixture()..['version'] = 3));
    await newer;
    api.snapshots[1].complete(snapshot(fixture()..['version'] = 2));
    await older;
    expect(controller.state.asData!.value.single.version, 3);
  });
  test('snapshot started before mutation cannot undo its result', () async {
    final old = controller.refresh();
    final command = controller.command('payout', {});
    api.commands.single.complete(
      fixture(state: 'payoutReported')..['version'] = 3,
    );
    await command;
    api.snapshots[1].complete(snapshot(fixture()));
    await old;
    expect(
      controller.state.asData!.value.single.current!['state'],
      'payoutReported',
    );
    api.snapshots.last.complete(
      snapshot(fixture(state: 'payoutReported')..['version'] = 3),
    );
    await tick();
  });
  test(
    'last receipt updates circle completion before snapshot returns',
    () async {
      final command = controller.command('receipt', {});
      final complete = fixture()
        ..['version'] = 5
        ..['status'] = 'completed'
        ..['current_round'] = null;
      api.commands.single.complete(complete);
      await command;
      expect(controller.state.asData!.value.single.status, 'completed');
      expect(controller.state.asData!.value.single.current, isNull);
      api.snapshots.last.complete(snapshot(complete));
      await tick();
    },
  );
  test('unknown command result throws and never fabricates success', () async {
    final result = controller.command('report', {});
    final assertion = expectLater(result, throwsA(isA<ApiFailure>()));
    api.commands.single.completeError(const ApiFailure('offline'));
    await assertion;
    expect(controller.state.asData!.value.single.version, 1);
    api.snapshots.last.completeError(const ApiFailure('offline'));
    await tick();
  });
  test('disposed account ignores delayed data and sync metadata', () async {
    final refresh = controller.refresh();
    final before = statuses.length;
    controller.dispose();
    api.snapshots.last.complete(snapshot(fixture()..['version'] = 10));
    await refresh;
    expect(statuses.length, before);
  });
  test(
    'newer mutation response wins when commands finish out of order',
    () async {
      final first = controller.command('approve', {}),
          second = controller.command('approve', {});
      api.commands.last.complete(fixture()..['version'] = 4);
      await second;
      api.commands.first.complete(fixture()..['version'] = 3);
      await first;
      expect(controller.state.asData!.value.single.version, 4);
      for (final pending in api.snapshots.where((c) => !c.isCompleted)) {
        pending.complete(snapshot(fixture()..['version'] = 4));
      }
      await tick();
    },
  );
}
