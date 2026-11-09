import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/account.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';

final _sessionsProvider = FutureProvider.autoDispose<List<DeviceSession>>(
  (ref) => ref.watch(accountRepositoryProvider).sessions(),
);

/// Phones signed in to this account; end one or all the others.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  Future<void> _end(BuildContext context, WidgetRef ref, String id) async {
    final t = context.l10n;
    final ok = await confirmDialog(
      context,
      title: id == 'others' ? t.endOthersTitle : t.endSessionTitle,
      body: t.endSessionBody,
      confirm: t.endSession,
      danger: true,
    );
    if (!ok) return;
    try {
      await ref.read(accountRepositoryProvider).endSession(id);
      ref.invalidate(_sessionsProvider);
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final sessions = ref.watch(_sessionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.signedInDevices)),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => ref.refresh(_sessionsProvider.future),
        child: sessions.when(
          loading: () => const PageBody(children: [SkeletonList(count: 3, height: 64)]),
          error: (e, _) => ListView(
            children: [SizedBox(height: 480, child: LoadError(e, onRetry: () => ref.invalidate(_sessionsProvider)))],
          ),
          data: (items) => PageBody(
            children: [
              const SizedBox(height: Space.xs),
              Text(t.devicesBody, style: context.text.bodySmall),
              const SizedBox(height: Space.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, s) in items.indexed) ...[
                      if (i > 0) const Divider(indent: 56),
                      ListTile(
                        leading: const Icon(AppIcons.devices),
                        title: Text(s.device ?? (s.platform == 'ios' ? 'iPhone' : 'Android')),
                        subtitle: Text(
                          [
                            if (s.appVersion != null) s.appVersion!,
                            if (s.lastUsedAt != null) relativeTime(t, s.lastUsedAt!),
                          ].join(' · '),
                        ),
                        trailing: s.current
                            ? StatusChip(t.thisDevice, tone: Tone.success)
                            : IconButton(
                                tooltip: t.endSession,
                                icon: Icon(AppIcons.signOut, color: context.colors.danger),
                                onPressed: () => _end(context, ref, s.id),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
              if (items.length > 1) ...[
                const SizedBox(height: Space.lg),
                AppButton(kind: ButtonKind.danger, label: t.endOthers, onPressed: () => _end(context, ref, 'others')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
