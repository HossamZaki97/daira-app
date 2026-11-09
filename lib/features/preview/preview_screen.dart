import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/activity.dart';
import '../../core/models/circle.dart';
import '../../core/models/money.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../settings/preference_controls.dart';
import '../startup/gate_screens.dart';

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) => ref.watch(accountRepositoryProvider).home());

/// Phase 3 home: proves the new API layer against the server and shows every
/// foundation component in both languages and themes. Replaced by the real
/// home in Phase 4.
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final profile = ref.watch(sessionProvider)?.profile;
    final home = ref.watch(homeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DairaMark(size: 28),
            const SizedBox(width: Space.sm),
            Text(t.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: t.signOut,
            icon: const DirectionalIcon(AppIcons.signOut),
            onPressed: () => ref.read(authRepositoryProvider).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => ref.refresh(homeProvider.future),
        child: PageBody(
          children: [
            const UpdateOfferBanner(),
            const AnnouncementBanners(),
            HeroCard(
              child: home.when(
                data: (data) => _Summary(name: profile?.name ?? '', home: data),
                loading: () => const SizedBox(height: 120, child: Center(child: RingLoader(size: 36))),
                error: (e, _) => Text(t.error(e), style: context.text.bodyMedium?.copyWith(color: context.colors.onHero)),
              ),
            ),
            SectionHeader(t.previewTitle),
            Text(t.previewBody, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
            SectionHeader(t.language),
            const LanguageSelector(),
            SectionHeader(t.appearance),
            const ThemeSelector(),
            SectionHeader(t.componentsTitle),
            const _ComponentGallery(),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.name, required this.home});
  final String name;
  final HomeData home;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    final muted = context.text.bodySmall?.copyWith(color: colors.onHeroMuted);
    final turn = home.nextTurn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.signedInAs(name), style: muted),
        const SizedBox(height: Space.xxs),
        Text(t.actionsCount(home.actions.length), style: context.text.titleLarge?.copyWith(color: colors.onHero)),
        Text(t.activeCirclesCount(home.activeCircles), style: muted),
        if (turn != null) ...[
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(child: Text(turn.circle, style: context.text.labelLarge?.copyWith(color: colors.onHero))),
              AmountText(turn.amount, color: colors.onHero),
            ],
          ),
          const SizedBox(height: Space.xs),
          ProgressBar(
            turn.totalRounds == 0 ? 0 : (turn.roundNumber - turn.roundsBefore - 1) / turn.totalRounds,
            onHero: true,
          ),
          const SizedBox(height: Space.xs),
          Text(t.roundOf(turn.roundNumber, turn.totalRounds), style: muted),
        ],
      ],
    );
  }
}

class _ComponentGallery extends ConsumerStatefulWidget {
  const _ComponentGallery();

  @override
  ConsumerState<_ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends ConsumerState<_ComponentGallery> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = ref.watch(settingsProvider);
    final code = settings?.suggestedCurrency ?? 'EGP';
    final currency = settings?.currency(code);
    final sample = Money(125050, currency: code, decimals: currency?.decimals ?? 2);
    const gap = SizedBox(height: Space.sm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const InitialsAvatar('Mona Adel', highlight: true),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(t.roundOf(3, 10), style: context.text.titleSmall)),
                  StatusChip(t.roundState(RoundState.collecting)),
                ],
              ),
              const SizedBox(height: Space.md),
              AmountText(sample, large: true),
              const SizedBox(height: Space.sm),
              const ProgressBar(0.6),
              const SizedBox(height: Space.sm),
              Text(t.dueOn(t.date(DateTime.now().add(const Duration(days: 3)))), style: context.text.bodySmall),
            ],
          ),
        ),
        gap,
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            StatusChip(t.obligation(ObligationState.pending)),
            StatusChip(t.obligation(ObligationState.reported), icon: AppIcons.waiting),
            StatusChip(t.obligation(ObligationState.approved), tone: Tone.success, icon: AppIcons.confirmed),
            StatusChip(t.obligation(ObligationState.pending, overdue: true), tone: Tone.danger),
            StatusChip(t.circleStatus(CircleStatus.suspended), tone: Tone.danger),
          ],
        ),
        const SizedBox(height: Space.md),
        AppButton(
          label: t.actionPaid,
          icon: AppIcons.pay,
          loading: _loading,
          onPressed: () async {
            setState(() => _loading = true);
            await Future<void>.delayed(const Duration(seconds: 2));
            if (mounted) setState(() => _loading = false);
          },
        ),
        gap,
        ButtonPair(
          first: AppButton.secondary(label: t.actionReceived, icon: AppIcons.check, onPressed: () {}),
          second: AppButton(kind: ButtonKind.danger, label: t.actionNotReceived, onPressed: () {}),
        ),
        gap,
        AppButton(label: t.actionPayout, onPressed: null),
        gap,
        InlineBanner(title: t.errorConflict, tone: Tone.pending),
        gap,
        InlineBanner(title: t.errorOffline, tone: Tone.danger, onDismiss: () {}),
        const SizedBox(height: Space.md),
        AppTextField(label: t.email, icon: AppIcons.email, hint: 'name@example.com', textDirection: TextDirection.ltr),
        gap,
        AppTextField(label: t.password, icon: AppIcons.password, password: true, errorText: t.requiredField),
        const SizedBox(height: Space.md),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [DairaMark(size: 48), RingLoader(size: 48), RingLoader(size: 24)],
        ),
        const SizedBox(height: Space.md),
        const Skeleton.line(width: 160),
        gap,
        const SkeletonList(count: 2, height: 72),
        const SizedBox(height: Space.md),
        SizedBox(
          height: 360,
          child: AppCard(
            child: MessageView(
              showMark: true,
              title: t.emptyCirclesTitle,
              body: t.emptyCirclesBody,
              primary: AppButton(label: t.createCircle, icon: AppIcons.add, onPressed: () {}),
              secondary: AppButton.secondary(label: t.joinWithCode, icon: AppIcons.ticket, onPressed: () {}),
            ),
          ),
        ),
        gap,
        Center(
          child: AppButton.text(
            label: t.unavailableTitle,
            onPressed: () => showToast(context, t.errorGeneric, tone: Tone.danger),
          ),
        ),
      ],
    );
  }
}
