import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';
import '../../shared/formatters.dart';
import '../invitations/invitation_sheets.dart';
import 'circle_presentation.dart';
import 'create_circle_screen.dart';
import 'payment_sheet.dart';

String roundStatus(AppLocalizations t, String state) => switch (state) {
  'collecting' => t.collecting,
  'readyForPayout' => t.collectionDone,
  'payoutReported' => t.awaitingReceipt,
  _ => t.roundCompleted,
};
String installmentStatus(AppLocalizations t, String state) => switch (state) {
  'pending' => t.pending,
  'reported' => t.reported,
  _ => t.approved,
};
StatusTone installmentTone(String state) => switch (state) {
  'approved' => StatusTone.success,
  'reported' => StatusTone.waiting,
  _ => StatusTone.neutral,
};

class CircleDetailsScreen extends ConsumerWidget {
  const CircleDetailsScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context), data = ref.watch(circlesProvider);
    final circle = data.asData?.value.where((c) => c.id == id).firstOrNull;
    if (circle == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.circles)),
        body: Center(
          child: data.isLoading
              ? const CircularProgressIndicator()
              : FailureView(
                  data.error ?? const Object(),
                  ref.read(circlesProvider.notifier).refresh,
                ),
        ),
      );
    }
    final user = ref.watch(authProvider).profile?['id'] as String?;
    if (user == null) return const SizedBox.shrink();
    final view = CirclePresentation(circle), current = view.current;
    final sync = ref.watch(syncStatusProvider);
    final actions = actionsFor([circle], user);
    Widget scrolling(String name, List<Widget> children) => RefreshIndicator(
      onRefresh: ref.read(circlesProvider.notifier).refresh,
      child: ListView(
        key: ValueKey(name),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(circle.name),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: t.rounds),
              Tab(text: t.members),
              Tab(text: t.latestActivity),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (sync.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(t.syncPending),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    scrolling('round-scroll', [
                      if (circle.status == 'draft')
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StatusPill(t.draft, tone: StatusTone.neutral),
                              const SizedBox(height: 16),
                              Text(
                                t.continueSetup,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              if (circle.isOrganizer(user))
                                PrimaryButton(
                                  label: t.continueSetup,
                                  onPressed: () => Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CreateCircleScreen(draft: circle),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (circle.status == 'completed')
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                color: context.dairaColors.statusSuccess,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.circleFinished,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      if (current != null) ...[
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    t.roundOf(
                                      current['number'] as int,
                                      circle.rounds.length,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  StatusPill(
                                    roundStatus(t, current['state'] as String),
                                    tone: current['state'] == 'readyForPayout'
                                        ? StatusTone.success
                                        : current['state'] == 'collecting'
                                        ? StatusTone.info
                                        : StatusTone.waiting,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MemberAvatar(
                                    current['recipient'] as String,
                                    receiving: true,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Semantics(
                                      label:
                                          '${t.currentRecipient}: ${current['recipient']}',
                                      excludeSemantics: true,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            view.receiving
                                                ? t.yourReceivingTurn
                                                : t.currentRecipient,
                                            style: TextStyle(
                                              color:
                                                  context.dairaColors.textMuted,
                                            ),
                                          ),
                                          Text(
                                            current['recipient'] as String,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                t.roundAmount,
                                style: TextStyle(
                                  color: context.dairaColors.textMuted,
                                ),
                              ),
                              Text(
                                circle.amount(
                                  current['expected_minor'] as int,
                                  t.localeName,
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              InfoLine(
                                t.dueDate,
                                dateLabel(
                                  current['due_date'] as String,
                                  t.localeName,
                                ),
                              ),
                              const Divider(height: 28),
                              InfoLine(
                                t.collected,
                                circle.amount(
                                  current['approved_minor'] as int,
                                  t.localeName,
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: view.collectionProgress,
                                  minHeight: 6,
                                  semanticsLabel: t.collected,
                                ),
                              ),
                              InfoLine(
                                t.remaining,
                                circle.amount(
                                  current['remaining_minor'] as int,
                                  t.localeName,
                                ),
                              ),
                              Text(
                                t.approvalCount(
                                  rows(current['obligations'])
                                      .where((o) => o['state'] == 'approved')
                                      .length,
                                  rows(current['obligations']).length,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (current['payout_at'] != null)
                                InfoLine(
                                  t.payout,
                                  timestampLabel(
                                    current['payout_at'] as String,
                                    t.localeName,
                                  ),
                                ),
                              if (view.recipient?['user_id'] == null &&
                                  circle.isOrganizer(user)) ...[
                                const SizedBox(height: 12),
                                Text(t.recipientNeedsAccount),
                                TextButton(
                                  onPressed: () =>
                                      _invite(context, circle, view.recipient!),
                                  child: Text(t.inviteRecipient),
                                ),
                              ],
                              for (final action in actions.where(
                                (a) =>
                                    a.action == 'payout' ||
                                    a.action == 'receipt',
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: PrimaryButton(
                                    label: actionLabel(t, action.action),
                                    onPressed: () =>
                                        openAction(context, action),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SectionHeading(t.memberContributions),
                        for (final obligation in rows(current['obligations']))
                          _obligation(
                            context,
                            t,
                            circle,
                            current,
                            obligation,
                            actions,
                          ),
                        if (view.next != null) ...[
                          SectionHeading(t.nextRound),
                          SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  view.next!['recipient'] as String,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  dateLabel(
                                    view.next!['due_date'] as String,
                                    t.localeName,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 8),
                      SurfaceCard(
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(t.schedulePreview),
                          children: [
                            for (final round in circle.rounds)
                              InkWell(
                                onTap: () =>
                                    _showRound(context, t, circle, round),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Text(
                                            t.roundOf(
                                              round['number'] as int,
                                              circle.rounds.length,
                                            ),
                                          ),
                                          StatusPill(
                                            round['legacy'] == true
                                                ? t.historical
                                                : round['state'] == 'completed'
                                                ? t.roundCompleted
                                                : current?['number'] ==
                                                      round['number']
                                                ? t.currentRound
                                                : t.upcoming,
                                            tone: round['state'] == 'completed'
                                                ? StatusTone.success
                                                : StatusTone.neutral,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        round['recipient'] as String,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        dateLabel(
                                          round['due_date'] as String,
                                          t.localeName,
                                        ),
                                      ),
                                      InfoLine(
                                        t.roundAmount,
                                        circle.amount(
                                          round['expected_minor'] as int,
                                          t.localeName,
                                        ),
                                      ),
                                      if (round['received_at'] != null)
                                        InfoLine(
                                          t.receipt,
                                          timestampLabel(
                                            round['received_at'] as String,
                                            t.localeName,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
                    scrolling('members-scroll', [
                      for (final member in circle.members)
                        _member(context, t, circle, view, member, user),
                    ]),
                    scrolling('activity-scroll', [
                      if (rows(circle.data['events']).isEmpty)
                        Text(t.noActivity),
                      for (final event in rows(circle.data['events']))
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _eventLabel(t, event['action'] as String),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(event['actor'] as String),
                              if (event['round_number'] != null)
                                Text('${t.round} ${event['round_number']}'),
                              Text(
                                timestampLabel(
                                  event['at'] as String,
                                  t.localeName,
                                ),
                                style: TextStyle(
                                  color: context.dairaColors.textMuted,
                                ),
                              ),
                              if (event['note'] != null)
                                Text(event['note'] as String),
                            ],
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRound(
    BuildContext context,
    AppLocalizations t,
    Circle circle,
    Json round,
  ) {
    final historical = round['legacy'] == true;
    final upcoming =
        circle.status == 'draft' ||
        (circle.current != null &&
            (round['number'] as int) > (circle.current!['number'] as int));
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.roundOf(round['number'] as int, circle.rounds.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StatusPill(
              historical
                  ? t.historical
                  : upcoming
                  ? t.upcoming
                  : roundStatus(t, round['state'] as String),
              tone: StatusTone.neutral,
            ),
            InfoLine(t.beneficiary, round['recipient'] as String),
            InfoLine(
              t.dueDate,
              dateLabel(round['due_date'] as String, t.localeName),
            ),
            InfoLine(
              t.roundAmount,
              circle.amount(round['expected_minor'] as int, t.localeName),
            ),
            if (circle.status != 'draft') ...[
              InfoLine(
                t.collected,
                circle.amount(round['approved_minor'] as int, t.localeName),
              ),
              InfoLine(
                t.remaining,
                circle.amount(round['remaining_minor'] as int, t.localeName),
              ),
              if (!historical && round['payout_at'] != null)
                InfoLine(
                  t.payout,
                  timestampLabel(round['payout_at'] as String, t.localeName),
                ),
              if (!historical && round['received_at'] != null)
                InfoLine(
                  t.receipt,
                  timestampLabel(round['received_at'] as String, t.localeName),
                ),
              const Divider(height: 24),
              for (final o in rows(round['obligations']))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InfoLine(
                        o['member'] as String,
                        circle.amount(o['amount_minor'] as int, t.localeName),
                      ),
                      Text(installmentStatus(t, o['state'] as String)),
                      if (o['reason'] != null) Text(o['reason'] as String),
                    ],
                  ),
                ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(sheet),
              child: Text(t.close),
            ),
          ],
        ),
      ),
    );
  }

  void _invite(BuildContext context, Circle circle, Json member) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ManageInvitationSheet(circle: circle, member: member),
      );
  Widget _member(
    BuildContext context,
    AppLocalizations t,
    Circle circle,
    CirclePresentation view,
    Json member,
    String user,
  ) {
    final own = member['user_id'] == user,
        receiving =
            view.current != null &&
            member['id'] == view.current!['recipient_id'];
    return SurfaceCard(
      highlight: own || receiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemberAvatar(member['name'] as String, receiving: receiving),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (own)
                          Semantics(
                            label: t.thisIsYou,
                            excludeSemantics: true,
                            child: StatusPill(t.you),
                          ),
                        if (member['organizer'] == true)
                          StatusPill(t.organizer, tone: StatusTone.neutral),
                        if (receiving) StatusPill(t.currentRecipient),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoLine(t.shares, '${member['shares']}'),
          InfoLine(
            own ? t.yourTurns : t.receivingTurns,
            view
                .turnsFor(member['id'] as String)
                .join(t.localeName.startsWith('ar') ? '، ' : ', '),
          ),
          if (member['user_id'] == null && circle.status == 'active') ...[
            Text(
              t.notLinked,
              style: TextStyle(color: context.dairaColors.textMuted),
            ),
            if (circle.isOrganizer(user))
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _invite(context, circle, member),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(t.invite),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _obligation(
    BuildContext context,
    AppLocalizations t,
    Circle circle,
    Json round,
    Json obligation,
    List<ActionItem> actions,
  ) {
    final permitted = actions
        .where((a) => a.obligation?['id'] == obligation['id'])
        .firstOrNull;
    final late =
        obligation['state'] == 'pending' &&
        overdue(round['due_date'] as String);
    return SurfaceCard(
      highlight: obligation['member_id'] == circle.actor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            obligation['member'] as String,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            circle.amount(obligation['amount_minor'] as int, t.localeName),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(
                installmentStatus(t, obligation['state'] as String),
                tone: installmentTone(obligation['state'] as String),
              ),
              if (late) StatusPill(t.overdue, tone: StatusTone.danger),
            ],
          ),
          if (obligation['reason'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(obligation['reason'] as String),
            ),
          if (permitted != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => openAction(context, permitted),
                child: Text(actionLabel(t, permitted.action)),
              ),
            ),
        ],
      ),
    );
  }

  String _eventLabel(AppLocalizations t, String kind) => switch (kind) {
    'report' => t.report,
    'approve' => t.approve,
    'reject' => t.reject,
    'payout' => t.payout,
    'receipt' => t.receipt,
    'circle_saved' => t.saveCircle,
    'collection_completed' => t.readyForPayout,
    'circle_completed' => t.completed,
    'invitation_created' => t.invite,
    'invitation_revoked' => t.revoke,
    'invitation_accepted' => t.acceptInvite,
    _ => t.audit,
  };
}
