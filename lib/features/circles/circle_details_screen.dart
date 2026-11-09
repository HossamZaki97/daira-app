import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';
import '../invitations/invitation_sheets.dart';
import 'payment_sheet.dart';

String roundStatus(AppLocalizations t, String state) => switch (state) {
  'collecting' => t.collecting,
  'readyForPayout' => t.readyForPayout,
  'payoutReported' => t.payoutReported,
  _ => t.completed,
};
String installmentStatus(AppLocalizations t, String state) => switch (state) {
  'pending' => t.pending,
  'reported' => t.reported,
  _ => t.approved,
};

class CircleDetailsScreen extends ConsumerWidget {
  const CircleDetailsScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(circlesProvider);
    final circle = state.asData?.value.where((c) => c.id == id).firstOrNull;
    if (circle == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.circles)),
        body: FailureView(
          state.error ?? const Object(),
          ref.read(circlesProvider.notifier).refresh,
        ),
      );
    }
    final user = ref.watch(authProvider).profile!['id'] as String;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(circle.name),
          bottom: TabBar(
            tabs: [
              Tab(text: t.rounds),
              Tab(text: t.members),
              Tab(text: t.audit),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: ref.read(circlesProvider.notifier).refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (circle.status == 'draft')
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(t.draft),
                          const SizedBox(height: 8),
                          _ActivateDraft(circle: circle),
                        ],
                      ),
                    ),
                  for (final round in circle.rounds)
                    SurfaceCard(
                      highlight: round['number'] == circle.current?['number'],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${t.round} ${round['number']} • ${round['recipient']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('${t.dueDate}: ${round['due_date']}'),
                          Text(
                            round['legacy'] == true
                                ? t.historical
                                : roundStatus(t, round['state'] as String),
                          ),
                          const SizedBox(height: 12),
                          for (final pair in [
                            (t.expected, round['expected_minor']),
                            (t.collected, round['approved_minor']),
                            (t.remaining, round['remaining_minor']),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 12,
                                children: [
                                  Text(pair.$1),
                                  Text(
                                    circle.amount(pair.$2 as int, t.localeName),
                                  ),
                                ],
                              ),
                            ),
                          if (round['number'] == circle.current?['number'] &&
                              circle.status == 'active') ...[
                            const Divider(),
                            for (final obligation in rows(round['obligations']))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      alignment: WrapAlignment.spaceBetween,
                                      children: [
                                        Text(obligation['member'] as String),
                                        Text(
                                          circle.amount(
                                            obligation['amount_minor'] as int,
                                            t.localeName,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      installmentStatus(
                                        t,
                                        obligation['state'] as String,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if (obligation['reason'] != null)
                                      Text(obligation['reason'] as String),
                                    if (obligation['member_id'] ==
                                            circle.actor &&
                                        obligation['state'] == 'pending')
                                      TextButton(
                                        onPressed: () => openAction(
                                          context,
                                          ActionItem(
                                            circle,
                                            round,
                                            obligation,
                                            'report',
                                          ),
                                        ),
                                        child: Text(t.report),
                                      ),
                                    if (circle.isOrganizer(user) &&
                                        obligation['state'] == 'reported')
                                      TextButton(
                                        onPressed: () => openAction(
                                          context,
                                          ActionItem(
                                            circle,
                                            round,
                                            obligation,
                                            'review',
                                          ),
                                        ),
                                        child: Text(t.review),
                                      ),
                                  ],
                                ),
                              ),
                            if (round['state'] == 'readyForPayout' &&
                                circle.isOrganizer(user))
                              PrimaryButton(
                                label: t.payout,
                                onPressed: () => openAction(
                                  context,
                                  ActionItem(circle, round, null, 'payout'),
                                ),
                              ),
                            if (round['state'] == 'payoutReported' &&
                                round['recipient_id'] == circle.actor)
                              PrimaryButton(
                                label: t.receipt,
                                onPressed: () => openAction(
                                  context,
                                  ActionItem(circle, round, null, 'receipt'),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final member in circle.members)
                  SurfaceCard(
                    highlight: member['user_id'] == user,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              member['name'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (member['user_id'] == user)
                              Semantics(
                                label: t.you,
                                child: Chip(label: Text(t.you)),
                              ),
                            if (member['organizer'] == true)
                              Chip(label: Text(t.organizer)),
                          ],
                        ),
                        Text('${t.shares}: ${member['shares']}'),
                        if (circle.status == 'active' &&
                            circle.isOrganizer(user) &&
                            member['user_id'] == null)
                          TextButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              useSafeArea: true,
                              isScrollControlled: true,
                              builder: (_) => ManageInvitationSheet(
                                circle: circle,
                                member: member,
                              ),
                            ),
                            child: Text(t.invite),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final event in rows(circle.data['events']))
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event['actor']} • ${_eventLabel(t, event['action'] as String)}',
                        ),
                        if (event['round_number'] != null)
                          Text('${t.round} ${event['round_number']}'),
                        Text(event['at'] as String),
                        if (event['note'] != null)
                          Text(event['note'] as String),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
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

class _ActivateDraft extends ConsumerStatefulWidget {
  const _ActivateDraft({required this.circle});
  final Circle circle;
  @override
  ConsumerState<_ActivateDraft> createState() => _ActivateDraftState();
}

class _ActivateDraftState extends ConsumerState<_ActivateDraft> {
  bool _busy = false;
  Object? _failure;
  final _command = commandId();
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_failure != null) Text(errorText(t, _failure!)),
        PrimaryButton(
          label: t.activate,
          loading: _busy,
          onPressed: () async {
            setState(() {
              _busy = true;
              _failure = null;
            });
            final circle = widget.circle;
            final others = circle.members.where((m) => m['organizer'] != true);
            try {
              final factor = circle.decimals;
              final minor = circle.data['installment_minor'] as int;
              final digits = minor.toString().padLeft(factor + 1, '0');
              final amount = factor == 0
                  ? digits
                  : '${digits.substring(0, digits.length - factor)}.${digits.substring(digits.length - factor)}';
              await ref.read(circlesProvider.notifier).command('save', {
                'command_id': _command,
                'id': circle.id,
                'version': circle.version,
                'name': circle.name,
                'amount': amount,
                'currency': circle.currency,
                'cadence': circle.data['cadence'],
                'interval': circle.data['interval'],
                'start_date': circle.data['start_date'],
                'activate': true,
                'organizer_shares': circle.members.firstWhere(
                  (m) => m['organizer'] == true,
                )['shares'],
                'members': [
                  for (final member in others)
                    {'name': member['name'], 'shares': member['shares']},
                ],
              });
            } catch (error) {
              if (mounted) setState(() => _failure = error);
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          },
        ),
      ],
    );
  }
}
