import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/models/circle.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../invitations/invite_sheet.dart';
import '../state.dart';

/// One circle: the current round, what I must do, what the organizer must do,
/// members and the full turn order.
class CircleScreen extends ConsumerWidget {
  const CircleScreen({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final circle = ref.watch(circleProvider(id));
    final name = circle.valueOrNull?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        actions: [
          if (circle.hasValue)
            IconButton(
              tooltip: t.activityLog,
              icon: const Icon(AppIcons.history),
              onPressed: () => context.push(Routes.activity(id)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => ref.read(circleProvider(id).notifier).reload(),
        child: circle.when(
          skipLoadingOnReload: true,
          loading: () => const PageBody(
            children: [Skeleton.card(height: 180), SizedBox(height: Space.md), SkeletonList(count: 3, height: 72)],
          ),
          error: (e, _) => ListView(
            children: [SizedBox(height: 480, child: LoadError(e, onRetry: () => ref.invalidate(circleProvider(id))))],
          ),
          data: (c) => _CircleBody(c),
        ),
      ),
    );
  }
}

class _CircleBody extends ConsumerStatefulWidget {
  const _CircleBody(this.circle);
  final Circle circle;

  @override
  ConsumerState<_CircleBody> createState() => _CircleBodyState();
}

class _CircleBodyState extends ConsumerState<_CircleBody> {
  /// Actions waiting for the server, so their buttons show the loader.
  final _busy = <String>{};

  CircleController get _controller => ref.read(circleProvider(widget.circle.id).notifier);

  Future<void> _run(String id, Future<void> Function() action, {String? done}) async {
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await action();
      if (mounted && done != null) showToast(context, done, tone: Tone.success);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _report(Obligation o) async {
    final t = context.l10n;
    final ok = await confirmDialog(context, title: t.confirmPaidTitle, body: t.confirmPaidBody, confirm: t.actionPaid);
    if (ok) await _run('report:${o.id}', () => _controller.report(o), done: t.paidDone);
  }

  Future<void> _approve(Obligation o) =>
      _run('approve:${o.id}', () => _controller.approve(o), done: context.l10n.approvedDone(o.member));

  Future<void> _reject(Obligation o) async {
    final reason = await showAppSheet<String>(context, builder: (_) => _RejectSheet(member: o.member));
    if (reason == null || !mounted) return;
    await _run('reject:${o.id}', () => _controller.reject(o, reason), done: context.l10n.rejectedDone);
  }

  Future<void> _payout(Round r) async {
    final t = context.l10n;
    final ok = await confirmDialog(
      context,
      title: t.confirmPayoutTitle,
      body: t.confirmPayoutBody(r.recipient),
      confirm: t.actionPayout,
    );
    if (ok) await _run('payout:${r.number}', () => _controller.payout(r.number), done: t.payoutDone);
  }

  Future<void> _receipt(Round r) async {
    final t = context.l10n;
    final ok = await confirmDialog(context, title: t.confirmReceiptTitle, body: t.confirmReceiptBody, confirm: t.actionReceipt);
    if (ok) await _run('receipt:${r.number}', () => _controller.receipt(r.number), done: t.receiptDone);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final c = widget.circle;
    final round = c.currentRound;
    final me = c.me;
    final mine = round?.obligations.where((o) => o.memberId == c.actorMemberId).firstOrNull;
    final active = c.status == CircleStatus.active;
    final reported = round?.obligations.where((o) => o.state == ObligationState.reported).toList() ?? const [];
    return PageBody(
      children: [
        if (c.status == CircleStatus.suspended)
          _Notice(InlineBanner(title: t.circleSuspendedTitle, body: t.circleSuspendedBody, tone: Tone.danger)),
        if (c.status == CircleStatus.cancelled)
          _Notice(InlineBanner(title: t.circleCancelledTitle, tone: Tone.danger)),
        if (c.status == CircleStatus.completed)
          _Notice(InlineBanner(title: t.circleCompletedTitle, tone: Tone.success, icon: AppIcons.confirmed)),
        if (c.status == CircleStatus.draft) _DraftCard(c),
        _Summary(c),
        if (round != null) ...[
          const SizedBox(height: Space.md),
          _RoundHero(circle: c, round: round),
        ],

        // --- what I must do
        if (active && round != null && mine != null && round.state == RoundState.collecting) ...[
          SectionHeader(t.yourPayment),
          _MyPayment(
            obligation: mine,
            busy: _busy.contains('report:${mine.id}'),
            onPaid: () => _report(mine),
          ),
        ],
        if (active && round != null && round.state == RoundState.payoutReported && round.recipientId == c.actorMemberId) ...[
          SectionHeader(t.yourPayout),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.payoutSentToYou(round.expected.format(context.localeName)), style: context.text.bodyLarge),
                const SizedBox(height: Space.md),
                AppButton(
                  label: t.actionReceipt,
                  icon: AppIcons.receive,
                  loading: _busy.contains('receipt:${round.number}'),
                  onPressed: () => _receipt(round),
                ),
              ],
            ),
          ),
        ],

        // --- what the organizer must do
        if (c.isOrganizer && active && round != null) ...[
          if (round.state == RoundState.readyForPayout) ...[
            SectionHeader(t.handOver),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.readyForPayoutBody(round.recipient), style: context.text.bodyLarge),
                  const SizedBox(height: Space.xs),
                  AmountText(round.expected, large: true),
                  const SizedBox(height: Space.md),
                  AppButton(
                    label: t.actionPayout,
                    icon: AppIcons.payout,
                    loading: _busy.contains('payout:${round.number}'),
                    onPressed: () => _payout(round),
                  ),
                ],
              ),
            ),
          ],
          if (round.state == RoundState.payoutReported)
            _Notice(InlineBanner(title: t.waitingRecipient(round.recipient), tone: Tone.pending), top: Space.md),
          if (round.state == RoundState.collecting) ...[
            SectionHeader(
              t.paymentsThisRound,
              trailing: reported.isEmpty ? null : StatusChip(t.toReview(reported.length), tone: Tone.pending),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, o) in round.obligations.indexed) ...[
                    if (i > 0) const Divider(indent: Space.md, endIndent: Space.md),
                    _ObligationRow(
                      obligation: o,
                      isMe: o.memberId == c.actorMemberId,
                      approving: _busy.contains('approve:${o.id}'),
                      rejecting: _busy.contains('reject:${o.id}'),
                      onApprove: () => _approve(o),
                      onReject: () => _reject(o),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],

        // --- people and turns
        SectionHeader(t.membersCount(c.members.length)),
        _Members(circle: c, me: me),
        SectionHeader(t.turnOrder),
        _Rounds(c),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.child, {this.top = 0});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.only(top: top, bottom: Space.md), child: child);
}

class _Summary extends StatelessWidget {
  const _Summary(this.circle);
  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final c = circle;
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CircleStatusChip(c.status),
        StatusChip(t.perShare(c.installment.format(context.localeName)), tone: Tone.info, icon: AppIcons.pay),
        StatusChip(cadenceLabel(t, c.cadence, c.interval), tone: Tone.info, icon: AppIcons.calendar),
        if (c.isOrganizer) StatusChip(t.youOrganize, tone: Tone.info, icon: AppIcons.organizer),
      ],
    );
  }
}

class _RoundHero extends StatelessWidget {
  const _RoundHero({required this.circle, required this.round});
  final Circle circle;
  final Round round;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    final muted = context.text.bodySmall?.copyWith(color: colors.onHeroMuted);
    final mine = round.recipientId == circle.actorMemberId;
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.roundOf(round.number, circle.rounds.length), style: muted)),
              Text(t.roundState(round.state), style: context.text.labelMedium?.copyWith(color: colors.accent)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            mine ? t.yourTurnNow : t.recipientIs(round.recipient),
            style: context.text.titleMedium?.copyWith(color: colors.onHero),
          ),
          const SizedBox(height: Space.xxs),
          AmountText(round.expected, large: true, color: colors.onHero),
          const SizedBox(height: Space.md),
          ProgressBar(round.progress, onHero: true),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.collectedOf(round.approved.amount(context.localeName), round.expected.amount(context.localeName)),
                  style: muted,
                ),
              ),
              if (round.dueDate != null)
                Text(
                  round.overdue ? t.daysLate(-daysUntil(round.dueDate!)) : t.date(round.dueDate!),
                  style: muted?.copyWith(color: round.overdue ? colors.accent : null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyPayment extends StatelessWidget {
  const _MyPayment({required this.obligation, required this.busy, required this.onPaid});
  final Obligation obligation;
  final bool busy;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final o = obligation;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: ObligationChip(o.state, overdue: o.overdue)),
          const SizedBox(height: Space.xs),
          AmountText(o.amount, large: true),
          if (o.state == ObligationState.pending && o.reason != null) ...[
            const SizedBox(height: Space.sm),
            InlineBanner(title: t.notReceivedReason(o.reason!), body: t.notReceivedHint, tone: Tone.danger),
          ],
          const SizedBox(height: Space.sm),
          if (o.state == ObligationState.pending) ...[
            Text(t.payHint, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            AppButton(label: t.actionPaid, icon: AppIcons.pay, loading: busy, onPressed: onPaid),
          ] else if (o.state == ObligationState.reported)
            Text(t.waitingOrganizer, style: context.text.bodyMedium)
          else
            Text(t.paymentConfirmed, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

class _ObligationRow extends StatelessWidget {
  const _ObligationRow({
    required this.obligation,
    required this.isMe,
    required this.approving,
    required this.rejecting,
    required this.onApprove,
    required this.onReject,
  });

  final Obligation obligation;
  final bool isMe;
  final bool approving;
  final bool rejecting;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final o = obligation;
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(o.member, highlight: isMe),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isMe ? t.youName(o.member) : o.member, style: context.text.titleSmall),
                    AmountText(o.amount),
                    const SizedBox(height: Space.xxs),
                    ObligationChip(o.state, overdue: o.overdue),
                  ],
                ),
              ),
            ],
          ),
          if (o.state == ObligationState.reported) ...[
            if (o.reportedAt != null) ...[
              const SizedBox(height: Space.xs),
              Text(t.reportedAt(relativeTime(t, o.reportedAt!)), style: context.text.bodySmall),
            ],
            const SizedBox(height: Space.sm),
            ButtonPair(
              first: AppButton(label: t.actionReceived, icon: AppIcons.check, loading: approving, onPressed: rejecting ? null : onApprove),
              second: AppButton(
                kind: ButtonKind.danger,
                label: t.actionNotReceived,
                loading: rejecting,
                onPressed: approving ? null : onReject,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks the organizer why the payment did not arrive (required, shown to the member).
class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.member});
  final String member;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.rejectTitle(widget.member), style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(t.rejectBody, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
          const SizedBox(height: Space.lg),
          AppTextField(
            controller: _reason,
            label: t.reason,
            hint: t.reasonHint,
            maxLength: 200,
            autofocus: true,
            validator: (v) => (v ?? '').trim().isEmpty ? t.requiredField : null,
          ),
          const SizedBox(height: Space.lg),
          AppButton(
            kind: ButtonKind.danger,
            label: t.actionNotReceived,
            onPressed: () {
              if (_form.currentState?.validate() ?? false) Navigator.pop(context, _reason.text.trim());
            },
          ),
          const SizedBox(height: Space.xs),
          AppButton.text(label: t.cancel, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _Members extends ConsumerWidget {
  const _Members({required this.circle, required this.me});
  final Circle circle;
  final Member? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final c = circle;
    final canInvite = c.isOrganizer &&
        c.status == CircleStatus.active &&
        (ref.watch(settingsProvider)?.features.invitations ?? true);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, m) in c.members.indexed) ...[
            if (i > 0) const Divider(indent: Space.md, endIndent: Space.md),
            ListTile(
              leading: InitialsAvatar(m.name, highlight: m.id == me?.id),
              title: Text(m.id == me?.id ? t.youName(m.name) : m.name),
              subtitle: Text(
                [
                  if (m.organizer) t.organizer,
                  if (m.shares > 1) t.sharesCount(m.shares),
                  if (!m.organizer) m.linked ? t.memberJoined : t.memberNotJoined,
                ].join(' · '),
              ),
              trailing: canInvite && !m.linked && !m.organizer
                  ? TextButton.icon(
                      onPressed: () => showInviteSheet(context, circle: c, member: m),
                      icon: const Icon(AppIcons.invite, size: 18),
                      label: Text(t.invite),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Rounds extends StatelessWidget {
  const _Rounds(this.circle);
  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        children: [
          for (final r in circle.rounds)
            Builder(
              builder: (context) {
                final current = r.number == circle.currentRoundNumber;
                final mine = r.recipientId == circle.actorMemberId;
                return Container(
                  color: current ? colors.primaryContainer.withValues(alpha: 0.5) : null,
                  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${r.number}', style: context.text.labelLarge?.copyWith(fontFeatures: DairaType.numeric.fontFeatures)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mine ? t.youName(r.recipient) : r.recipient,
                                style: context.text.titleSmall?.copyWith(fontWeight: mine ? FontWeight.w700 : null)),
                            if (r.dueDate != null) Text(t.date(r.dueDate!), style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      if (r.legacy)
                        StatusChip(t.importedRound, tone: Tone.info)
                      else if (r.state == RoundState.completed)
                        Icon(AppIcons.success, size: 20, color: colors.success)
                      else if (current)
                        StatusChip(t.roundState(r.state), tone: roundTone(r.state))
                      else if (mine)
                        Icon(AppIcons.turn, size: 20, color: colors.accent),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Draft: only the organizer sees it; edit or start it.
class _DraftCard extends ConsumerStatefulWidget {
  const _DraftCard(this.circle);
  final Circle circle;

  @override
  ConsumerState<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends ConsumerState<_DraftCard> {
  bool _busy = false;

  Future<void> _activate() async {
    final t = context.l10n;
    final ok = await confirmDialog(context, title: t.startCircleTitle, body: t.startCircleBody, confirm: t.startCircle);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(circleProvider(widget.circle.id).notifier).activate(widget.circle.version);
      if (mounted) showToast(context, t.circleStarted, tone: Tone.success);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (!widget.circle.isOrganizer) return const SizedBox.shrink();
    return _Notice(
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.draftTitle, style: context.text.titleMedium),
            const SizedBox(height: Space.xxs),
            Text(t.draftBody, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            AppButton(label: t.startCircle, loading: _busy, onPressed: _activate),
            const SizedBox(height: Space.xs),
            AppButton.secondary(
              label: t.editDraft,
              icon: AppIcons.edit,
              onPressed: _busy ? null : () => context.push(Routes.editDraft(widget.circle.id)),
            ),
          ],
        ),
      ),
    );
  }
}
