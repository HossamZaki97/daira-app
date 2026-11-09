import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/activity.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../startup/gate_screens.dart';
import '../state.dart';

/// "What do I need to do now?" — actions first, then my next turn, then what is coming.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final name = ref.watch(sessionProvider)?.profile.name ?? '';
    final home = ref.watch(homeProvider);
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DairaMark(size: 28),
            const SizedBox(width: Space.sm),
            Flexible(child: Text(t.hello(first), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(tooltip: t.joinWithCode, icon: const Icon(AppIcons.ticket), onPressed: () => context.push(Routes.join())),
          IconButton(tooltip: t.createCircle, icon: const Icon(AppIcons.add), onPressed: () => context.push(Routes.newCircle)),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async {
          refreshLists(ref.invalidate);
          await ref.read(homeProvider.future);
        },
        child: home.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          loading: () => const PageBody(children: [Skeleton.card(height: 150), SizedBox(height: Space.xl), SkeletonList()]),
          error: (e, _) => ListView(
            children: [
              SizedBox(
                height: 480,
                child: ErrorView(
                  title: t.unavailableTitle,
                  message: t.error(e),
                  retryLabel: t.retry,
                  offline: e is ApiException && e.isOffline,
                  onRetry: () => ref.invalidate(homeProvider),
                ),
              ),
            ],
          ),
          data: (data) => _HomeBody(data),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody(this.data);
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final turn = data.nextTurn;
    final empty = data.activeCircles == 0 && data.actions.isEmpty;
    return PageBody(
      children: [
        const UpdateOfferBanner(),
        const AnnouncementBanners(),
        if (empty)
          SizedBox(
            height: 460,
            child: MessageView(
              showMark: true,
              title: t.emptyCirclesTitle,
              body: t.emptyCirclesBody,
              primary: AppButton(label: t.createCircle, icon: AppIcons.add, onPressed: () => context.push(Routes.newCircle)),
              secondary: AppButton.secondary(
                label: t.joinWithCode,
                icon: AppIcons.ticket,
                onPressed: () => context.push(Routes.join()),
              ),
            ),
          )
        else ...[
          if (turn != null) _NextTurnCard(turn),
          SectionHeader(t.needsYou),
          if (data.actions.isEmpty)
            AppCard(
              child: Row(
                children: [
                  Icon(AppIcons.success, color: context.colors.success),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(t.nothingNeeded, style: context.text.bodyMedium)),
                ],
              ),
            )
          else
            for (final action in data.actions)
              Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: _ActionCard(action)),
          if (data.upcoming.isNotEmpty) ...[
            SectionHeader(t.upcomingPayments),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, item) in data.upcoming.indexed) ...[
                    if (i > 0) const Divider(indent: Space.md, endIndent: Space.md),
                    ListTile(
                      onTap: () => context.push(Routes.circle(item.circleId)),
                      title: Text(item.circle),
                      subtitle: Text(
                        [t.roundNumber(item.roundNumber), if (item.dueDate != null) dueLabel(t, item.dueDate!)].join(' · '),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AmountText(item.amount),
                          const SizedBox(height: 2),
                          ObligationChip(item.state),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _NextTurnCard extends StatelessWidget {
  const _NextTurnCard(this.turn);
  final NextTurn turn;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    final muted = context.text.bodySmall?.copyWith(color: colors.onHeroMuted);
    final done = turn.roundNumber - turn.roundsBefore - 1;
    return HeroCard(
      onTap: () => context.push(Routes.circle(turn.circleId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.yourTurn, style: muted)),
              Text(turn.circle, style: context.text.labelLarge?.copyWith(color: colors.onHero)),
            ],
          ),
          const SizedBox(height: Space.xs),
          AmountText(turn.amount, large: true, color: colors.onHero),
          const SizedBox(height: Space.xxs),
          Text(
            turn.roundsBefore == 0 ? t.turnIsNow : t.turnInRounds(turn.roundsBefore),
            style: context.text.titleSmall?.copyWith(color: colors.onHero),
          ),
          const SizedBox(height: Space.md),
          ProgressBar(turn.totalRounds == 0 ? 0 : done / turn.totalRounds, onHero: true),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(child: Text(t.roundOf(turn.roundNumber, turn.totalRounds), style: muted)),
              if (turn.dueDate != null) Text(t.date(turn.dueDate!), style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(this.action);
  final HomeAction action;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    final (icon, title, cta) = switch (action.type) {
      HomeActionType.pay => (AppIcons.pay, t.actionPayTitle, t.actionPaid),
      HomeActionType.receipt => (AppIcons.receive, t.actionReceiptTitle, t.actionReceipt),
      HomeActionType.confirm => (AppIcons.confirmed, t.actionConfirmTitle(action.count), t.review),
      HomeActionType.payout => (AppIcons.payout, t.actionPayoutTitle(action.recipient ?? ''), t.actionPayout),
    };
    final late = action.dueDate != null && daysUntil(action.dueDate!) < 0 && action.type == HomeActionType.pay;
    return AppCard(
      onTap: () => context.push(Routes.circle(action.circleId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: colors.accentContainer, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: colors.text),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    Text('${action.circle} · ${t.roundNumber(action.roundNumber)}', style: context.text.bodySmall),
                  ],
                ),
              ),
              if (action.type != HomeActionType.confirm) AmountText(action.amount),
            ],
          ),
          if (action.rejectedReason != null) ...[
            const SizedBox(height: Space.sm),
            InlineBanner(title: t.notReceivedReason(action.rejectedReason!), tone: Tone.danger),
          ],
          const SizedBox(height: Space.sm),
          Row(
            children: [
              if (action.dueDate != null)
                StatusChip(dueLabel(t, action.dueDate!), tone: late ? Tone.danger : Tone.pending, icon: AppIcons.calendar),
              const Spacer(),
              Text(cta, style: context.text.labelLarge?.copyWith(color: colors.primary)),
              const SizedBox(width: Space.xxs),
              DirectionalIcon(AppIcons.forward, size: 16, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
