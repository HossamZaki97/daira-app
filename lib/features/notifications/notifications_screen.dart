import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/models/activity.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../state.dart';

/// In-app notifications, newest first. Opening one marks it read.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _items = <AppNotification>[];
  final _read = <String>{};
  String? _cursor;
  bool _loading = false;
  bool _done = false;
  bool _loaded = false;
  Object? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _load();
    });
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (_done && !reset)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(notificationsRepositoryProvider).page(cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items.clear();
          _read.clear();
        }
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _done = !page.hasMore;
        _loaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isRead(AppNotification n) => n.read || _read.contains(n.id);

  Future<void> _open(AppNotification n) async {
    if (!_isRead(n)) {
      setState(() => _read.add(n.id));
      ref.read(notificationsRepositoryProvider).markRead([n.id]).then(
        (_) => ref.invalidate(unreadProvider),
        onError: (Object _) {},
      );
    }
    if (n.circleId != null) await context.push(Routes.circle(n.circleId!));
  }

  Future<void> _readAll() async {
    try {
      await ref.read(notificationsRepositoryProvider).markRead();
      if (!mounted) return;
      setState(() => _read.addAll(_items.map((n) => n.id)));
      ref.invalidate(unreadProvider);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final anyUnread = _items.any((n) => !_isRead(n));
    // New notifications arrive with the unread count (foreground refresh).
    ref.listen(unreadProvider, (previous, next) {
      final before = previous?.valueOrNull ?? 0;
      if ((next.valueOrNull ?? 0) > before && _loaded) _load(reset: true);
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(t.tabNotifications),
        actions: [
          if (anyUnread) TextButton(onPressed: _readAll, child: Text(t.markAllRead)),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async {
          ref.invalidate(unreadProvider);
          await _load(reset: true);
        },
        child: !_loaded && _error != null
            ? ListView(children: [SizedBox(height: 480, child: LoadError(_error!, onRetry: () => _load(reset: true)))])
            : !_loaded
            ? const PageBody(children: [SkeletonList(count: 6, height: 64)])
            : _items.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 460,
                    child: MessageView(icon: AppIcons.notifications, title: t.noNotifications, body: t.noNotificationsBody),
                  ),
                ],
              )
            : PageBody(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: Space.xxl),
                children: [
                  for (final n in _items) _NotificationTile(n, read: _isRead(n), onTap: () => _open(n)),
                  if (_loading) const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: RingLoader(size: 28))),
                ],
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.n, {required this.read, required this.onTap});
  final AppNotification n;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    final (icon, text) = describeNotification(t, n, context.localeName);
    return Material(
      color: read ? Colors.transparent : colors.primaryContainer.withValues(alpha: 0.45),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: n.actionRequired ? colors.accentContainer : colors.surfaceSunken,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: colors.text),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: context.text.bodyMedium?.copyWith(fontWeight: read ? FontWeight.w400 : FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (n.circle != null) n.circle!, if (n.at != null) relativeTime(t, n.at!)].join(' · '),
                      style: context.text.bodySmall,
                    ),
                    if (n.actionRequired) ...[
                      const SizedBox(height: Space.xxs),
                      StatusChip(t.needsAction, tone: Tone.pending),
                    ],
                  ],
                ),
              ),
              if (!read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sentence for a notification, written in the reader's language from its facts.
(IconData, String) describeNotification(AppLocalizations t, AppNotification n, String locale) {
  final actor = n.actor ?? '';
  final member = n.member ?? '';
  final round = n.roundNumber ?? 0;
  final amount = n.amount?.format(locale) ?? '';
  return switch (n.kind) {
    'payment_reported' => (AppIcons.pay, t.ntPaymentReported(actor, round)),
    'payment_confirmed' => (AppIcons.confirmed, t.ntPaymentConfirmed(actor, round)),
    'payment_not_received' => (AppIcons.error, t.ntPaymentNotReceived(round, n.note ?? '')),
    'ready_for_payout' => (AppIcons.payout, t.ntReadyForPayout(round, member)),
    'payout_sent' => (AppIcons.receive, t.ntPayoutSent(actor, amount)),
    'payout_received' => (AppIcons.success, t.ntPayoutReceived(actor, round)),
    'member_joined' => (AppIcons.invite, t.ntMemberJoined(actor)),
    'payment_due_soon' => (AppIcons.calendar, t.ntDueSoon(round, amount)),
    'payment_overdue' => (AppIcons.warning, t.ntOverdue(round, amount)),
    'circle_completed' => (AppIcons.confirmed, t.ntCircleCompleted),
    'circle_suspended' => (AppIcons.warning, t.ntCircleSuspended),
    'circle_resumed' => (AppIcons.refresh, t.ntCircleResumed),
    'circle_cancelled' => (AppIcons.close, t.ntCircleCancelled),
    _ => (AppIcons.notifications, t.ntGeneric),
  };
}
