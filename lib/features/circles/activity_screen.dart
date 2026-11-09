import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/circle.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';

/// The circle's audit trail: who did what and when. Read-only, newest first.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({required this.circleId, super.key});
  final String circleId;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _items = <CircleEvent>[];
  String? _cursor;
  bool _loading = false;
  bool _done = false;
  Object? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _more();
    });
    _more();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _more({bool reset = false}) async {
    if (_loading || (_done && !reset)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(circlesRepositoryProvider)
          .events(widget.circleId, cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _done = !page.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.activityLog)),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => _more(reset: true),
        child: _items.isEmpty && _error != null
            ? ListView(children: [SizedBox(height: 480, child: LoadError(_error!, onRetry: () => _more(reset: true)))])
            : _items.isEmpty && _loading
            ? const PageBody(children: [SkeletonList(count: 6, height: 56)])
            : PageBody(
                controller: _scroll,
                children: [
                  if (_items.isEmpty) MessageView(icon: AppIcons.history, title: t.noActivity),
                  for (final e in _items) _EventTile(e),
                  if (_loading) const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: RingLoader(size: 28))),
                ],
              ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile(this.event);
  final CircleEvent event;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final e = event;
    final (icon, text) = describeEvent(t, e);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: context.colors.surfaceSunken, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: context.colors.textMuted),
      ),
      title: Text(text, style: context.text.bodyMedium),
      subtitle: Text(
        [
          e.byAdmin ? t.byDairaSupport : e.actor,
          if (e.at != null) relativeTime(t, e.at!),
          if (e.note != null) '“${e.note}”',
        ].join(' · '),
      ),
    );
  }
}

/// Icon and sentence for an audit entry.
(IconData, String) describeEvent(AppLocalizations t, CircleEvent e) {
  final round = e.roundNumber ?? 0;
  final member = e.member ?? '';
  return switch (e.action) {
    'circle_saved' => (AppIcons.edit, t.evCircleSaved),
    'report' => (AppIcons.pay, t.evReport(member, round)),
    'approve' => (AppIcons.confirmed, t.evApprove(member, round)),
    'reject' => (AppIcons.error, t.evReject(member, round)),
    'collection_completed' => (AppIcons.success, t.evCollectionCompleted(round)),
    'payout' => (AppIcons.payout, t.evPayout(round)),
    'receipt' => (AppIcons.receive, t.evReceipt(round)),
    'circle_completed' => (AppIcons.confirmed, t.evCircleCompleted),
    'invitation_created' => (AppIcons.ticket, t.evInvitationCreated),
    'invitation_revoked' || 'admin_invitation_revoked' => (AppIcons.close, t.evInvitationRevoked),
    'invitation_accepted' => (AppIcons.invite, t.evInvitationAccepted),
    'circle_suspended' => (AppIcons.warning, t.evCircleSuspended),
    'circle_resumed' => (AppIcons.refresh, t.evCircleResumed),
    'circle_cancelled' => (AppIcons.close, t.evCircleCancelled),
    _ => (AppIcons.info, e.action),
  };
}
