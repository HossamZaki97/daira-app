import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/data/repositories.dart';
import '../../core/models/circle.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../state.dart';

/// All my circles, split into active, drafts and finished.
class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.tabCircles),
          actions: [
            IconButton(tooltip: t.joinWithCode, icon: const Icon(AppIcons.ticket), onPressed: () => context.push(Routes.join())),
            const SizedBox(width: Space.xxs),
          ],
          bottom: TabBar(
            tabs: [Tab(text: t.filterActive), Tab(text: t.filterDrafts), Tab(text: t.filterCompleted)],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.newCircle),
          icon: const Icon(AppIcons.add),
          label: Text(t.createCircle),
        ),
        body: const TabBarView(
          children: [
            _CircleList(CircleFilter.active),
            _CircleList(CircleFilter.draft),
            _CircleList(CircleFilter.completed),
          ],
        ),
      ),
    );
  }
}

class _CircleList extends ConsumerWidget {
  const _CircleList(this.filter);
  final CircleFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final circles = ref.watch(circlesProvider(filter));
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => ref.refresh(circlesProvider(filter).future),
      child: circles.when(
        loading: () => const PageBody(padding: EdgeInsets.all(Space.gutter), children: [SkeletonList(count: 4, height: 120)]),
        error: (e, _) => ListView(
          children: [SizedBox(height: 480, child: LoadError(e, onRetry: () => ref.invalidate(circlesProvider(filter))))],
        ),
        data: (items) => items.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 460,
                    child: MessageView(
                      icon: filter == CircleFilter.draft ? AppIcons.edit : AppIcons.circles,
                      title: switch (filter) {
                        CircleFilter.active => t.emptyCirclesTitle,
                        CircleFilter.draft => t.noDrafts,
                        CircleFilter.completed => t.noCompleted,
                      },
                      body: filter == CircleFilter.active ? t.emptyCirclesBody : null,
                    ),
                  ),
                ],
              )
            : PageBody(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 96),
                children: [
                  for (final c in items)
                    Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: CircleCard(c)),
                ],
              ),
      ),
    );
  }
}

class CircleCard extends StatelessWidget {
  const CircleCard(this.circle, {super.key});
  final CircleSummary circle;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final c = circle;
    final draft = c.status == CircleStatus.draft;
    return AppCard(
      onTap: () => context.push(draft && c.isOrganizer ? Routes.editDraft(c.id) : Routes.circle(c.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (c.isOrganizer) ...[
                Tooltip(message: t.organizer, child: Icon(AppIcons.organizer, size: 18, color: context.colors.textMuted)),
                const SizedBox(width: Space.xs),
              ],
              if (c.status != CircleStatus.active) CircleStatusChip(c.status),
            ],
          ),
          const SizedBox(height: Space.xxs),
          Row(
            children: [
              AmountText(c.installment),
              const SizedBox(width: Space.xs),
              Expanded(child: Text(cadenceLabel(t, c.cadence, c.interval), style: context.text.bodySmall)),
            ],
          ),
          if (c.status == CircleStatus.active || c.status == CircleStatus.suspended) ...[
            const SizedBox(height: Space.md),
            ProgressBar(c.progress),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                if (c.currentRound != null)
                  Expanded(child: Text(t.roundOf(c.currentRound!, c.totalRounds), style: context.text.bodySmall))
                else
                  const Spacer(),
                if (c.myObligationState != null) ObligationChip(c.myObligationState!),
              ],
            ),
            if (c.myNextTurn != null) ...[
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Icon(AppIcons.turn, size: 16, color: context.colors.textMuted),
                  const SizedBox(width: Space.xxs),
                  Expanded(
                    child: Text(
                      c.myNextTurnDate == null
                          ? t.myTurnRound(c.myNextTurn!)
                          : '${t.myTurnRound(c.myNextTurn!)} · ${t.date(c.myNextTurnDate!)}',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ] else if (draft) ...[
            const SizedBox(height: Space.xs),
            Text(t.draftHint, style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}
